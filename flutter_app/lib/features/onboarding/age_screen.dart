import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  int _age = 25;
  static const int _minAge = 16;
  static const int _maxAge = 60;

  // Arc: starts at 210° (bottom-left), sweeps 240° clockwise to 90° (bottom-right)
  static const double _startDeg = 150.0;
  static const double _sweepDeg = 240.0;

  void _updateAge(Offset localPos, Offset center) {
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    double angleDeg = atan2(dy, dx) * 180 / pi;
    if (angleDeg < 0) angleDeg += 360;

    // Arc goes clockwise from startDeg (decreasing angle).
    // How far counter-clockwise is this point from startDeg = distance into arc.
    double normalized = _startDeg - angleDeg;
    if (normalized < 0) normalized += 360;

    if (normalized <= _sweepDeg) {
      final fraction = normalized / _sweepDeg;
      setState(() {
        _age = (_minAge + fraction * (_maxAge - _minAge))
            .round()
            .clamp(_minAge, _maxAge);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: OnboardingBase(
        step: 6,
        showBack: true,
        titleWidget: AppTypography.screenTitle(
          prefix: 'Your ',
          highlight: 'Age?',
        ),
        onContinue: () => controller.setAge(_age),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'It helps us create the perfect plan for you.',
              style: AppTypography.onboardingSubtitle(),
            ),
            const SizedBox(height: 36),

            // Circular arc dial
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) =>
                      _updateAge(d.localPosition, const Offset(130, 130)),
                  onTapDown: (d) =>
                      _updateAge(d.localPosition, const Offset(130, 130)),
                  child: CustomPaint(
                    painter: _ArcDialPainter(
                      age: _age,
                      minAge: _minAge,
                      maxAge: _maxAge,
                      startDeg: _startDeg,
                      sweepDeg: _sweepDeg,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_age',
                            style: AppTypography.displayLarge().copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 56,
                            ),
                          ),
                          Text(
                            'years',
                            style: AppTypography.bodyMedium().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Info text
            Center(
              child: Text(
                "We'll customize workouts perfect\nfor your age.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcDialPainter extends CustomPainter {
  final int age;
  final int minAge;
  final int maxAge;
  final double startDeg;
  final double sweepDeg;

  const _ArcDialPainter({
    required this.age,
    required this.minAge,
    required this.maxAge,
    required this.startDeg,
    required this.sweepDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final startRad = startDeg * pi / 180;
    final sweepRad = sweepDeg * pi / 180;

    final fraction = (age - minAge) / (maxAge - minAge);
    final currentSweep = fraction * sweepRad;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Inner pink glow circle ──────────────────────────────────────────────
    final innerRadius = radius - 16;

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB6C1).withValues(alpha: 0.45),
          const Color(0xFFFDE8EE).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawCircle(center, innerRadius, haloPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFFFCEEF4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 10, innerPaint);

    // ── Track arc — use NEGATIVE sweep so Impeller (Vulkan) renders clockwise
    //    (over the top), not counter-clockwise (through the bottom).
    final trackPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startRad, -sweepRad, false, trackPaint);

    // ── Progress arc with pink → purple → blue gradient ────────────────────
    if (currentSweep > 0.01) {
      final endAngle = startRad - sweepRad; // clockwise end in Impeller
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF5C6BC0), // indigo-blue  (at startRad angle)
            Color(0xFFAD4FC8), // purple
            Color(0xFFE91E63), // hot pink     (at startRad - sweepRad angle)
          ],
          stops: const [0.0, 0.5, 1.0],
          startAngle: endAngle,
          endAngle: startRad,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startRad, -currentSweep, false, progressPaint);
    }

    // ── Thumb circle ───────────────────────────────────────────────────────
    // Negative sweep → thumb moves clockwise (decreasing angle from startRad)
    final thumbAngle = startRad - currentSweep;
    final thumbPos = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    canvas.drawCircle(
      thumbPos.translate(0, 2),
      15,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(thumbPos, 14, Paint()..color = Colors.white);

    canvas.drawCircle(
      thumbPos,
      14,
      Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Min / Max labels ───────────────────────────────────────────────────
    final labelRadius = radius + 26;

    // minAge label at arc start (startRad = lower-left)
    final startLabelPos = Offset(
      center.dx + labelRadius * cos(startRad),
      center.dy + labelRadius * sin(startRad),
    );
    _drawLabel(canvas, '$minAge', startLabelPos);

    // maxAge label at arc end (startRad - sweepRad = lower-right)
    final endAngleFinal = startRad - sweepRad;
    final endLabelPos = Offset(
      center.dx + labelRadius * cos(endAngleFinal),
      center.dy + labelRadius * sin(endAngleFinal),
    );
    _drawLabel(canvas, '$maxAge', endLabelPos);
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ArcDialPainter old) => old.age != age;
}
