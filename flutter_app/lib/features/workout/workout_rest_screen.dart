import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class WorkoutRestScreen extends StatefulWidget {
  final String nextExerciseName;
  final String nextExerciseImage;
  final String nextExerciseDuration;
  final String nextExerciseKcal;
  final int exerciseNumber;
  final int totalExercises;
  final int restSeconds;

  const WorkoutRestScreen({
    super.key,
    required this.nextExerciseName,
    required this.nextExerciseImage,
    required this.nextExerciseDuration,
    required this.nextExerciseKcal,
    required this.exerciseNumber,
    required this.totalExercises,
    this.restSeconds = 20,
  });

  @override
  State<WorkoutRestScreen> createState() => _WorkoutRestScreenState();
}

class _WorkoutRestScreenState extends State<WorkoutRestScreen> {
  late int _secondsLeft;
  late int _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.restSeconds;
    _totalSeconds = widget.restSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _done();
      }
    });
  }

  void _addTime() => setState(() {
        _secondsLeft += 15;
        _totalSeconds += 15;
      });

  void _done() {
    _timer?.cancel();
    if (mounted) Navigator.pop(context, true);
  }

  double get _progress => 1 - (_secondsLeft / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildBackButton(context),
              const SizedBox(height: 32),
              _buildTimerCircle(),
              const SizedBox(height: 36),
              _buildActionButtons(),
              const SizedBox(height: 36),
              _buildUpNext(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BACK BUTTON ────────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, false),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: _darkText),
      ),
    );
  }

  // ─── TIMER CIRCLE ────────────────────────────────────────────────────────────

  Widget _buildTimerCircle() {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _RestArcPainter(progress: _progress),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REST',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _pink,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: GoogleFonts.poppins(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                    height: 1,
                  ),
                ),
                Text(
                  'SECONDS',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            onTap: _addTime,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: _pink, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '15 sec',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _actionCard(
            onTap: _done,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fast_forward_rounded, color: _pink, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ─── UP NEXT ─────────────────────────────────────────────────────────────────

  Widget _buildUpNext() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UP NEXT',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _pink,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.nextExerciseName,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: Color(0xFF6C5DD3)),
            const SizedBox(width: 4),
            Text(widget.nextExerciseDuration,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[600])),
            _dot(),
            const Text('🔥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(widget.nextExerciseKcal,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[600])),
            _dot(),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Exercise ',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                ),
                TextSpan(
                  text: '${widget.exerciseNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _pink,
                  ),
                ),
                TextSpan(
                  text: ' of ${widget.totalExercises}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            color: const Color(0xFFFFE8F3),
            child: Image.asset(
              widget.nextExerciseImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.fitness_center,
                    size: 60, color: _pink.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('|',
          style: TextStyle(color: Colors.grey[300], fontSize: 14)),
    );
  }
}

// ─── REST ARC PAINTER ────────────────────────────────────────────────────────

class _RestArcPainter extends CustomPainter {
  final double progress;
  const _RestArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _pink.withValues(alpha: 0.15)
        ..strokeWidth = 14
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
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dot at the end of the arc
    if (progress > 0) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        9,
        Paint()..color = _pink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RestArcPainter old) =>
      old.progress != progress;
}
