import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/media.dart';
import '../services/media_analytics.dart';
import '../services/media_downloader.dart';
import '../services/workout_audio_settings.dart';
import 'glow_image.dart';

/// Lets a player know when its screen has been covered by another route.
///
/// Must be registered on the app's navigator (see `main.dart`). Without it the
/// player has no way to learn that a screen was pushed on top of it — the
/// widget stays mounted and `build` is never called again, so nothing else in
/// the framework would tell it.
final RouteObserver<ModalRoute<void>> videoRouteObserver =
    RouteObserver<ModalRoute<void>>();

// A previous revision opened the clip on the ready screen too and handed the
// controller to this screen, to save the cost of opening it twice. It was
// reverted: two codec instances for one clip exhausted the device's graphics
// buffer pool, and the decoder spent tens of seconds failing to dequeue an
// output buffer (`C2BqBuffer: ... consecutive failures` in logcat), which is
// playback stuttering — a burst of frames, a stall, another burst. The ready
// screen shows the clip's poster instead. It is a frame from the same clip, so
// it looks the same, and it costs no decoder at all.

/// Full-bleed looping video player for an exercise demo clip.
///
/// Shows the poster frame until the first video frame is ready. The API returns
/// one with every clip, and it is what removes the black rectangle that used to
/// sit there while the player initialised — the still appears from cache almost
/// immediately, then the video takes over underneath it.
///
/// Plays only while its route is on top and the app is in the foreground. A
/// video decoder left running behind a pushed screen is not merely wasteful:
/// on a device with software codecs it saturates the CPU, and the starved Dart
/// isolate stops delivering timer callbacks — which is a countdown on the
/// screen above freezing mid-count.
class ExerciseVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;
  final bool playing;

  /// Silences the clip regardless of the user's setting. For a player that is
  /// only there to show a frame — never for expressing a sound preference,
  /// which belongs to [WorkoutAudioSettings].
  final bool muted;

  /// Poster still and blurhash, when the API sent a media object.
  final MediaVideo? media;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
    this.playing = true,
    this.muted = false,
    this.media,
  });

  @override
  State<ExerciseVideoPlayer> createState() => ExerciseVideoPlayerState();
}

class ExerciseVideoPlayerState extends State<ExerciseVideoPlayer>
    with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _hasError = false;

  /// Set while the player is refilling, so one stall counts once rather than
  /// once per notification.
  bool _wasBuffering = false;

  /// Another route is on top of this screen — the rest screen, a settings page,
  /// a dialog route.
  bool _covered = false;

  /// The app is in the background.
  bool _backgrounded = false;

  /// Play only when this screen is the one the user is actually looking at.
  bool get _shouldPlay => widget.playing && !_covered && !_backgrounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The settings screen sits on top of a running workout, so the clip has to
    // follow the slider as it moves rather than at the next exercise.
    WorkoutAudioSettings.instance.enabled.addListener(_applyVolume);
    WorkoutAudioSettings.instance.volume.addListener(_applyVolume);
    _initialize(widget.videoUrl);
  }

  /// The volume this player should be at right now.
  double get _volume =>
      widget.muted ? 0 : WorkoutAudioSettings.instance.effectiveVolume;

  void _applyVolume() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.setVolume(_volume);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      videoRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() => _syncPlayback(covered: true);

  @override
  void didPopNext() => _syncPlayback(covered: false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncPlayback(backgrounded: state != AppLifecycleState.resumed);
  }

  /// Single place that decides whether the clip runs, so the three independent
  /// reasons to stop cannot contradict each other.
  void _syncPlayback({bool? covered, bool? backgrounded}) {
    if (covered != null) _covered = covered;
    if (backgrounded != null) _backgrounded = backgrounded;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_shouldPlay) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  @override
  void didUpdateWidget(ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _detach();
      _controller?.dispose();
      _hasError = false;
      _initialize(widget.videoUrl);
      return;
    }
    if (oldWidget.playing != widget.playing) _syncPlayback();
    if (oldWidget.muted != widget.muted) _applyVolume();
  }

  Future<void> _initialize(String url) async {
    // A downloaded copy wins over the network every time: no request, no
    // buffering, and it works with the phone in aeroplane mode. This is what
    // makes an offline workout actually play rather than merely be listed.
    final local = MediaDownloader.instance.fileFor(url);
    final controller = local != null
        ? VideoPlayerController.file(local)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    // Startup delay: from asking for the video to the first frame being ready.
    // The single number the faststart work exists to move.
    final timer = MediaTimer();

    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      MediaAnalytics.instance.videoStartFailed(url);
      if (mounted && identical(_controller, controller)) {
        setState(() => _hasError = true);
      }
      return;
    }

    // Opening a clip is not instant, and this widget may have been disposed or
    // moved to another exercise while it happened. Releasing the orphan here
    // rather than leaving it to chance is the whole point: a controller that
    // finished initialising after its owner went away keeps a hardware decoder
    // and its graphics buffers checked out. The pool is small — a handful of
    // leaks and the next decoder can never dequeue a buffer, which deadlocks
    // playback and takes the UI thread down with it.
    if (!mounted || !identical(_controller, controller)) {
      await controller.dispose();
      return;
    }

    timer.report((ms) => MediaAnalytics.instance.videoStart(ms: ms, url: url));
    await _configure(controller);
  }

  /// Applies looping, volume and playback state to a controller that is open.
  ///
  /// Looping matters for more than tidiness: the exercise runs for the number
  /// of seconds an admin set, which has nothing to do with how long the clip
  /// happens to be. A clip shorter than the exercise restarts and keeps going
  /// until the countdown ends; a longer one is simply cut off when it does.
  Future<void> _configure(VideoPlayerController controller) async {
    await controller.setLooping(true);
    await controller.setVolume(_volume);
    if (!mounted || !identical(_controller, controller)) {
      await controller.dispose();
      return;
    }

    // Not `widget.playing`: by the time a clip finishes opening the screen may
    // already have been covered, and starting it then is exactly the stall this
    // class exists to avoid.
    if (_shouldPlay) await controller.play();
    controller.addListener(_onPlayerTick);
    if (mounted) setState(() {});
  }

  // Covered and backgrounded pause rather than release. Releasing was tried and
  // reverted: VideoPlayerController.dispose() runs its platform work on the
  // Android main thread, which is also where Choreographer drives Flutter's
  // frames and input dispatch. A slow codec release there stops the app
  // rendering or responding at all — trading a wasted decoder for a freeze.
  // The leak fix in _initialize is what actually bounds decoder use.

  /// Counts stalls. A clip that buffers mid-set is the most visible media
  /// failure in the app, and the one a bitrate or CDN change should fix.
  void _onPlayerTick() {
    final controller = _controller;
    if (controller == null) return;
    final buffering = controller.value.isBuffering;
    if (buffering && !_wasBuffering) {
      MediaAnalytics.instance.buffering(widget.videoUrl);
    }
    _wasBuffering = buffering;
  }

  void _detach() {
    _controller?.removeListener(_onPlayerTick);
    _wasBuffering = false;
  }

  @override
  void dispose() {
    videoRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    WorkoutAudioSettings.instance.enabled.removeListener(_applyVolume);
    WorkoutAudioSettings.instance.volume.removeListener(_applyVolume);
    _detach();
    _controller?.dispose();
    super.dispose();
  }

  Widget _poster() {
    final poster = widget.media?.poster;
    if (poster == null || poster.isEmpty) return const SizedBox.shrink();
    return GlowImage(
      media: MediaImage(
        thumb: poster,
        medium: poster,
        large: poster,
        blurhash: widget.media?.blurhash,
      ),
      fit: widget.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready =
        !_hasError && controller != null && controller.value.isInitialized;

    // The poster stays mounted underneath rather than being swapped out, so the
    // handover has nothing to flash through.
    return Stack(
      fit: StackFit.expand,
      children: [
        _poster(),
        if (ready)
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
      ],
    );
  }
}
