import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../routes/app_pages.dart';

class WeightCurrentScreen extends StatefulWidget {
  const WeightCurrentScreen({super.key});

  @override
  State<WeightCurrentScreen> createState() => _WeightCurrentScreenState();
}

class _WeightCurrentScreenState extends State<WeightCurrentScreen> {
  int _currentWeight = 60;
  int _targetWeight = 50;

  static const int _sliderMin = 40;
  static const int _sliderMax = 120;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wave
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: _WaveBackground(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── "Your current Weight?" ─────────────────────────
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'Your current\n',
                              style: AppTypography.headlineLarge().copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 30,
                              ),
                            ),
                            TextSpan(
                              text: 'Weight?',
                              style: AppTypography.headlineLarge().copyWith(
                                color: AppColors.neonMagenta,
                                fontWeight: FontWeight.w700,
                                fontSize: 30,
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        // ── Current weight pill card ───────────────────────
                        Center(
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4FFF13B0),
                                  blurRadius: 36,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/weight_scale.png',
                                  width: 25,
                                  height: 25,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_currentWeight',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 58,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'kg',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Custom slider ──────────────────────────────────
                        Row(
                          children: [
                            Text(
                              '$_sliderMin',
                              style: const TextStyle(
                                color: Color(0xFF4F4E4E),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: const Color(0xFFFF136B),
                                  inactiveTrackColor: const Color(0xFFE2E2E2),
                                  thumbShape: const _WeightThumbShape(),
                                  overlayShape: SliderComponentShape.noOverlay,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  min: _sliderMin.toDouble(),
                                  max: _sliderMax.toDouble(),
                                  value: _currentWeight.toDouble(),
                                  onChanged: (v) =>
                                      setState(() => _currentWeight = v.round()),
                                ),
                              ),
                            ),
                            Text(
                              '$_sliderMax',
                              style: const TextStyle(
                                color: Color(0xFF4F4E4E),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── "Your target Weight?" ──────────────────────────
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'Your target ',
                              style: AppTypography.headlineMedium().copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 22,
                              ),
                            ),
                            TextSpan(
                              text: 'Weight?',
                              style: AppTypography.headlineMedium().copyWith(
                                color: AppColors.neonMagenta,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 12),

                        // ── Target weight blue card ────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/person_target.png',
                                width: 37,
                                height: 37,
                              ),
                              const SizedBox(width: 12),
                              // Weight number
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: '$_targetWeight',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 44,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' kg',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]),
                              ),
                              const Spacer(),
                              // − button
                              _roundButton(
                                label: '−',
                                onTap: () => setState(() {
                                  if (_targetWeight > 30) _targetWeight--;
                                }),
                              ),
                              const SizedBox(width: 8),
                              // + button
                              _roundButton(
                                label: '+',
                                onTap: () => setState(() {
                                  if (_targetWeight < 150) _targetWeight++;
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Continue footer ────────────────────────────────────────
                _buildFooter(context, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFA7C5FB),
              blurRadius: 7.3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              const Spacer(),
              Text(
                'Step 8 of 10',
                style: AppTypography.labelSmall().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 8 / 10,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E2E2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF136B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient Continue footer ───────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: () {
          controller.profile.value.currentWeight = _currentWeight.toDouble();
          controller.profile.value.targetWeight = _targetWeight.toDouble();
          controller.profile.refresh();
          // Skip weightTarget screen — navigate directly to healthIssues
          controller.currentStep.value = 10;
          Get.toNamed(Routes.healthIssues);
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.0, 0.86),
              end: Alignment(0.98, 0.29),
              colors: [Color(0xFFFF136B), Color(0xFFFF607B)],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: AppTypography.button().copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom slider thumb: white circle with shadow ─────────────────────────────
class _WeightThumbShape extends SliderComponentShape {
  const _WeightThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(34, 34);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Shadow
    canvas.drawCircle(
      center.translate(0, 1),
      17,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.8),
    );
    // White fill
    canvas.drawCircle(center, 17, Paint()..color = Colors.white);
  }
}

// ── Wave background ───────────────────────────────────────────────────────────
class _WaveBackground extends StatelessWidget {
  const _WaveBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backPaint = Paint()
      ..color = AppColors.splashGradientStart.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final backPath = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(size.width * 0.2, size.height * 0.25, size.width * 0.45,
          size.height * 0.65, size.width * 0.65, size.height * 0.38)
      ..cubicTo(size.width * 0.8, size.height * 0.18, size.width * 0.9,
          size.height * 0.45, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, backPaint);

    final frontPaint = Paint()
      ..color = AppColors.splashGradientEnd.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final frontPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(size.width * 0.15, size.height * 0.5, size.width * 0.38,
          size.height * 0.85, size.width * 0.55, size.height * 0.62)
      ..cubicTo(size.width * 0.72, size.height * 0.42, size.width * 0.88,
          size.height * 0.72, size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
