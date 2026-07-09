import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late int _secondsLeft;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _start();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress => 1 - (_secondsLeft / widget.countdownSeconds);

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    _timer?.cancel();

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
          // ── Full-bleed exercise image ────────────────────────────────
          _buildExerciseImage(),

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

  // ─── IMAGE ───────────────────────────────────────────────────────────────────

  Widget _buildExerciseImage() {
    final path =
        widget.exercises.isNotEmpty ? widget.exercises.first.imagePath : '';

    final fallback = Container(
      color: const Color(0xFFFFE8F3),
      child: Center(
        child: Icon(Icons.fitness_center,
            size: 80, color: _pink.withValues(alpha: 0.4)),
      ),
    );

    if (path.isEmpty) return fallback;
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
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

  Widget _buildCountdownCircle() {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _ReadyArcPainter(progress: _progress),
        child: Center(
          child: Container(
            width: 68,
            height: 68,
            decoration:
                const BoxDecoration(color: _pink, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$_secondsLeft',
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
