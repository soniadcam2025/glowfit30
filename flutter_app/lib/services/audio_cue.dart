import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Plays the short spoken cues bundled with the app.
///
/// Built on `video_player` rather than a new audio dependency: the package is
/// already here and decodes a bare AAC file on both platforms. An audio-only
/// clip allocates no graphics buffers, so these cues stay clear of the decoder
/// pool the exercise clips compete for — which is the constraint that decided
/// the design of the ready screen.
///
/// One cue at a time. They are a sequence, never a chord.
class AudioCue {
  AudioCue._();
  static final AudioCue instance = AudioCue._();

  VideoPlayerController? _controller;

  /// Completed when the current cue ends — by reaching its duration, by timing
  /// out, or by [stop] cutting it short. Without the last of those, stopping a
  /// cue would leave its `play` future hanging until the timeout and report a
  /// cap it never really hit.
  Completer<void>? _finished;

  /// Below this, a reported duration is not believed.
  ///
  /// A bare ADTS `.aac` carries no duration, and ExoPlayer reported one cue as
  /// **1 millisecond**. "Wait until position reaches duration" was then true on
  /// the first frame, so the cue was disposed before a sound came out — silent,
  /// with nothing in the logs. The cues are containered now, which fixes it
  /// properly; this is the guard so the same file never fails the same silent
  /// way again.
  static const Duration _minPlausibleDuration = Duration(milliseconds: 100);

  /// How long to let an untrusted-duration cue run before moving on.
  static const Duration _unknownDurationCap = Duration(seconds: 5);

  /// Plays [asset] and completes when the sound has finished.
  ///
  /// Never throws. A missing or undecodable file should cost the user a sound,
  /// not the start of their workout — every failure path falls through to
  /// completing normally.
  Future<void> play(String asset) async {
    await stop();

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.asset(asset);
      _controller = controller;
      await controller.initialize();

      // Stopped, or superseded by another cue, while this one was opening.
      if (!identical(_controller, controller)) return;

      final player = controller;
      final reported = player.value.duration;
      final trusted = reported >= _minPlausibleDuration;
      if (!trusted) {
        debugPrint(
          '[cue] $asset reported $reported — too short to believe, '
          'letting it run instead of waiting on the position',
        );
      }

      final finished = Completer<void>();
      _finished = finished;
      void onTick() {
        final value = player.value;
        if (!trusted || !value.isInitialized || finished.isCompleted) return;
        if (value.position >= reported) finished.complete();
      }

      player.addListener(onTick);
      await player.play();

      // The listener is the real signal; the timeout is a backstop so a cue
      // that never reports its own end cannot hold up the screen behind it.
      // With an untrusted duration the position will never satisfy the
      // listener, so the cap becomes the only signal — deliberately, because
      // playing a cue too long is a far smaller fault than not playing it.
      await finished.future.timeout(
        trusted ? reported + const Duration(seconds: 1) : _unknownDurationCap,
        onTimeout: () => debugPrint('[cue] $asset ran to the cap'),
      );
      player.removeListener(onTick);
      if (kDebugMode) {
        debugPrint('[cue] $asset done at ${player.value.position} of $reported');
      }
    } catch (error) {
      // Still swallowed — a cue must never break a workout — but no longer
      // invisible. A silent catch here is how "the sound just does not play"
      // becomes unexplainable.
      debugPrint('[cue] $asset failed: $error');
    } finally {
      if (identical(_controller, controller)) _controller = null;
      await controller?.dispose();
    }
  }

  /// Releases whatever `play` is waiting on, so a cue cut short unwinds now
  /// rather than at its timeout.
  void _completePending() {
    final finished = _finished;
    _finished = null;
    if (finished != null && !finished.isCompleted) finished.complete();
  }

  /// Silences whatever is playing. Safe to call when nothing is.
  Future<void> stop() async {
    _completePending();
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (kDebugMode) {
      debugPrint('[cue] stopped at ${controller.value.position}');
    }
    try {
      await controller.pause();
    } catch (_) {
      // Disposing is what matters; a failed pause must not skip it.
    }
    await controller.dispose();
  }
}
