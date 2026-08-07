import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/media.dart';
import '../../services/audio_cue.dart';
import '../../widgets/glow_image.dart';
import 'workout_active_screen.dart';
import 'workout_active_screen_v2.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

/// "READY TO GO!" countdown shown after tapping Continue Workout,
/// before the active exercise screen starts.
class WorkoutReadyScreen extends StatefulWidget {
  final List<ActiveExercise> exercises;
  final int totalKcal;
  final int day;
  final String? dayId;
  final int countdownSeconds;

  const WorkoutReadyScreen({
    super.key,
    required this.exercises,
    required this.totalKcal,
    required this.day,
    this.dayId,
    this.countdownSeconds = 10,
  });

  @override
  State<WorkoutReadyScreen> createState() => _WorkoutReadyScreenState();
}

class _WorkoutReadyScreenState extends State<WorkoutReadyScreen> {
  /// Drives the countdown without a `setState`.
  ///
  /// Calling `setState` once a second rebuilt this entire screen — a full-bleed
  /// network image and a 20-sigma `BackdropFilter` that re-samples everything
  /// beneath it — to change one number. That rebuild is the blinking: the
  /// backdrop re-composites and the image subtree is reconstructed on every
  /// tick. Only the 92px circle actually changes, so only it rebuilds now.
  late final ValueNotifier<int> _secondsLeft;

  Timer? _timer;
  bool _started = false;

  /// The spoken "three · two · one" runs 2.8s, so starting it the moment the
  /// display turns 3 lands it on zero.
  ///
  /// MP4-containered, not the bare `.aac` these were delivered as: a raw ADTS
  /// stream carries no duration, and ExoPlayer reported one of them as 1ms —
  /// which made the cue finish instantly and get disposed before it was
  /// audible. The container holds the real length.
  static const String _countdownCue = 'assets/audio/321.m4a';
  static const String _readyCue = 'assets/audio/readytogo.m4a';

  bool _countdownCuePlayed = false;

  /// The countdown reached zero and the closing cue is playing. Distinct from
  /// [_started], which means the exercise screen has actually been pushed.
  bool _outroRunning = false;

  /// Wall-clock deadline rather than a counter.
  ///
  /// A decrementing counter loses a second every time a tick is dropped, and if
  /// the device stalls it simply stops where it was. Deriving the remaining
  /// time from a fixed end time means a stalled countdown catches up and still
  /// finishes instead of sitting frozen.
  late final DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    _secondsLeft = ValueNotifier(widget.countdownSeconds);
    _endsAt = DateTime.now().add(Duration(seconds: widget.countdownSeconds));

    // Faster than the display rate so a missed tick costs a fraction of a
    // second rather than a whole one.
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final remaining = _endsAt.difference(DateTime.now()).inMilliseconds;
      if (remaining <= 0) {
        unawaited(_runOutro());
        return;
      }
      final left = (remaining / 1000).ceil();
      _secondsLeft.value = left;

      if (left <= 3 && !_countdownCuePlayed) {
        _countdownCuePlayed = true;
        // Not awaited: the countdown keeps running underneath the voice.
        unawaited(AudioCue.instance.play(_countdownCue));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // A cue outliving the screen that started it would talk over the workout.
    unawaited(AudioCue.instance.stop());
    _secondsLeft.dispose();
    super.dispose();
  }

  /// Runs when the countdown expires on its own: hold the circle at zero, say
  /// "ready to go", and only then open the exercise screen.
  ///
  /// Skipping ahead does not come through here — that calls [_start] directly,
  /// which silences the cues. Someone who taps past the countdown has said they
  /// do not want to wait for it, and a voice they cannot skip would be exactly
  /// the wait they declined.
  Future<void> _runOutro() async {
    if (_outroRunning || _started) return;
    _outroRunning = true;
    _timer?.cancel();
    _secondsLeft.value = 0;

    await AudioCue.instance.play(_readyCue);
    if (!mounted) return;
    await _start();
  }

  double _progressFor(int secondsLeft) =>
      1 - (secondsLeft / widget.countdownSeconds);

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    _timer?.cancel();

    // Cuts off a cue mid-word when the user skips ahead, which is the point:
    // they asked not to wait. A no-op when the countdown ran its course, since
    // the closing cue has already finished by then.
    await AudioCue.instance.stop();
    if (!mounted) return;

    // Using the Liquid Glass v2 active screen. To switch back to the
    // original design, change WorkoutActiveScreenV2 → WorkoutActiveScreen here.
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutActiveScreenV2(
          totalKcal: widget.totalKcal,
          day: widget.day,
          dayId: widget.dayId,
          exercises: widget.exercises,
        ),
      ),
    );
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        widget.exercises.isNotEmpty ? widget.exercises.first.name : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed exercise media ────────────────────────────────
          _buildExerciseMedia(),

          // ── Top overlay controls ─────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(
                    color: Colors.black38,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.white),
                    onTap: () => Navigator.pop(context),
                  ),
                  _roundButton(
                    color: Colors.white70,
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: _darkText),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Liquid Glass "READY TO GO" panel ────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: _buildGlassReadyPanel(firstName),
          ),
        ],
      ),
    );
  }

  // ─── LIQUID GLASS READY PANEL ──────────────────────────────────────────────

  Widget _buildGlassReadyPanel(String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                const Color(0xFFFFF3F7).withValues(alpha: 0.03),
                Colors.white.withValues(alpha: 0.02),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'READY TO GO !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 96,
                    child: Center(child: _buildCountdownCircle()),
                  ),
                  Positioned(
                    right: 4,
                    // Only tapping this arrow jumps ahead instantly; the
                    // circle itself no longer responds to taps — the
                    // countdown otherwise runs its course on its own.
                    child: GestureDetector(
                      onTap: _start,
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 26, color: _darkText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MEDIA ───────────────────────────────────────────────────────────────────

  /// The first exercise's clip, as its poster frame.
  ///
  /// The poster is a still taken from the clip itself, so this shows the
  /// exercise the user is about to do rather than the day's cover image.
  ///
  /// Deliberately an image and not a paused player. Opening the clip here as
  /// well as on the exercise screen puts two codec instances on one clip, and
  /// on a device with software codecs that exhausts the graphics buffer pool —
  /// the decoder then spends tens of seconds failing to dequeue an output
  /// buffer, which the user sees as the clip playing in bursts. A still costs
  /// nothing and looks the same.
  Widget _buildExerciseMedia() {
    final first = widget.exercises.isNotEmpty ? widget.exercises.first : null;
    final poster = first?.video?.poster;
    if (poster == null || poster.isEmpty) return _buildExerciseImage();

    return GlowImage(
      media: MediaImage(
        thumb: poster,
        medium: poster,
        large: poster,
        blurhash: first?.video?.blurhash,
      ),
      error: _buildExerciseImage(),
    );
  }

  Widget _buildExerciseImage() {
    final first = widget.exercises.isNotEmpty ? widget.exercises.first : null;
    final path = first?.imagePath ?? '';

    final fallback = Container(
      color: const Color(0xFFFFE8F3),
      child: Center(
        child: Icon(Icons.fitness_center,
            size: 80, color: _pink.withValues(alpha: 0.4)),
      ),
    );

    if (path.isEmpty) return fallback;
    if (path.startsWith('http')) {
      return GlowImage(url: path, media: first?.image, error: fallback);
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  // ─── OVERLAY CONTROLS ────────────────────────────────────────────────────────

  Widget _roundButton({
    required Color color,
    required Icon icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: icon),
      ),
    );
  }

  // ─── COUNTDOWN CIRCLE ────────────────────────────────────────────────────────

  /// The only part of this screen that changes each tick.
  Widget _buildCountdownCircle() {
    return ValueListenableBuilder<int>(
      valueListenable: _secondsLeft,
      builder: (context, secondsLeft, _) => SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _ReadyArcPainter(progress: _progressFor(secondsLeft)),
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration:
                  const BoxDecoration(color: _pink, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$secondsLeft',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── READY ARC PAINTER ─────────────────────────────────────────────────────────

class _ReadyArcPainter extends CustomPainter {
  final double progress;
  const _ReadyArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _pink.withValues(alpha: 0.25)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = _pink
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ReadyArcPainter old) =>
      old.progress != progress;
}
