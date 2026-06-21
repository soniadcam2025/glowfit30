import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed looping video player for an exercise demo clip.
/// Falls back to nothing visible on error — caller should show a
/// placeholder image/icon behind this widget.
class ExerciseVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize(widget.videoUrl);
  }

  @override
  void didUpdateWidget(ExerciseVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _initialize(widget.videoUrl);
    }
  }

  void _initialize(String url) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    controller.initialize().then((_) {
      if (!mounted) return;
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError || controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
