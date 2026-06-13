import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';

class BeautyGoalsScreen extends StatefulWidget {
  const BeautyGoalsScreen({super.key});

  @override
  State<BeautyGoalsScreen> createState() => _BeautyGoalsScreenState();
}

class _BeautyGoalsScreenState extends State<BeautyGoalsScreen> {
  final _selected = <String>{};
  static const int _maxSelect = 4;

  static const _groups = [
    _Group('Skin', [
      _Goal('Clear skin',   'assets/icons/beauty_clear_skin.png'),
      _Goal('Glowing skin', 'assets/icons/beauty_glowing_skin.png'),
      _Goal('Even tone',    'assets/icons/beauty_even_tone.png'),
    ]),
    _Group('Hair', [
      _Goal('Hair Growth',    'assets/icons/beauty_hair_growth.png'),
      _Goal('Less hair fall', 'assets/icons/beauty_less_hair_fall.png'),
      _Goal('Reduce dandruff','assets/icons/beauty_reduce_dandruff.png'),
    ]),
  ];

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else if (_selected.length < _maxSelect) {
        _selected.add(label);
      }
    });
  }

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
                            highlight: 'Beauty goals?',
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Choose up to 4',
                            style: AppTypography.onboardingSubtitle(),
                          ),

                          const SizedBox(height: 20),

                          // Grouped sections
                          ..._groups.map((group) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.title,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...group.goals.map((goal) => _GoalCard(
                                goal: goal,
                                selected: _selected.contains(goal.label),
                                onTap: () => _toggle(goal.label),
                              )),
                              const SizedBox(height: 8),
                            ],
                          )),

                          const SizedBox(height: 16),
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
                'Step 14 of 14',
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
              value: 1.0,
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
        onTap: canContinue ? () => controller.setBeautyGoals(_selected.toList()) : null,
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
                  "Let's Go!",
                  style: AppTypography.button().copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🚀', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Group {
  final String title;
  final List<_Goal> goals;
  const _Group(this.title, this.goals);
}

class _Goal {
  final String label;
  final String iconPath;
  const _Goal(this.label, this.iconPath);
}

class _GoalCard extends StatelessWidget {
  final _Goal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF136B) : const Color(0xFFEEEEEE),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                goal.iconPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  size: 34,
                  color: Color(0xFFFF136B),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                goal.label,
                style: TextStyle(
                  color: selected ? Colors.black : const Color(0xFF555555),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
