import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  String _selected = '';

  static const _levels = [
    _Level('Sedentary',          'Little or no exercise',   'assets/icons/activity_sedentary.png'),
    _Level('Lightly Active',     '1-3 days per week',       'assets/icons/activity_lightly_active.png'),
    _Level('Moderately Active',  '3-5 days per week',       'assets/icons/activity_moderately_active.png'),
    _Level('Very Active',        '6-7 days per week',       'assets/icons/activity_very_active.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          AppTypography.screenTitle(
                            prefix: "What's your\n",
                            highlight: 'Activity Level?',
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'This helps us customize your workouts.',
                            style: AppTypography.onboardingSubtitle(),
                          ),

                          const SizedBox(height: 24),

                          // Option cards
                          ..._levels.map((level) => _LevelCard(
                            level: level,
                            selected: _selected == level.label,
                            onTap: () => setState(() => _selected = level.label),
                          )),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                _buildFooter(context, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
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
                'Step 11 of 14',
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
              value: 11 / 14,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E2E2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF136B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, OnboardingController controller) {
    final canContinue = _selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: canContinue ? () => controller.setActivityLevel(_selected) : null,
        child: Opacity(
          opacity: canContinue ? 1.0 : 0.5,
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
      ),
    );
  }
}

class _Level {
  final String label;
  final String description;
  final String iconPath;
  const _Level(this.label, this.description, this.iconPath);
}

class _LevelCard extends StatelessWidget {
  final _Level level;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF136B) : const Color(0xFFEEEEEE),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF136B).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: 52,
              height: 52,
              child: Image.asset(
                level.iconPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_run,
                  size: 38,
                  color: Color(0xFFFF136B),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.description,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Radio circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFFF136B) : const Color(0xFFE0E0E0),
              ),
            ),
          ],
        ),
      ),
    );
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
