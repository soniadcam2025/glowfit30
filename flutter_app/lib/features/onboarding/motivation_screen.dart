import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class MotivationScreen extends StatelessWidget {
  const MotivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: OnboardingBase(
        step: 2,
        titleWidget: AppTypography.screenTitle(
          prefix: 'What ',
          highlight: 'Motivates',
          suffix: '\nYou the most?',
        ),
        showBack: true,
        onContinue: () {
          if (controller.userProfile.motivations.isNotEmpty) {
            controller.setMotivations(controller.userProfile.motivations);
          }
        },
        content: GetBuilder<OnboardingController>(
          builder: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose up to 2',
                style: AppTypography.onboardingSubtitle(),
              ),
              const SizedBox(height: 24),
              // 2. Grid of 6 motivation cards
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  _MotivationCard(
                    icon: 'assets/images/star_2.png',
                    label: 'Look\nbetter',
                    value: 'Look better',
                    isSelected: controller.userProfile.motivations
                        .contains('Look better'),
                    onTap: () => controller.toggleMotivation('Look better'),
                  ),
                  _MotivationCard(
                    icon: 'assets/images/get_toned_fit.png',
                    label: 'Get toned\n& fit',
                    value: 'Get toned & fit',
                    isSelected: controller.userProfile.motivations
                        .contains('Get toned & fit'),
                    onTap: () => controller.toggleMotivation('Get toned & fit'),
                  ),
                  _MotivationCard(
                    icon: 'assets/images/feel_confident.png',
                    label: 'Feel\nconfident',
                    value: 'Feel confident',
                    isSelected: controller.userProfile.motivations
                        .contains('Feel confident'),
                    onTap: () => controller.toggleMotivation('Feel confident'),
                  ),
                  _MotivationCard(
                    icon: 'assets/images/boost_energy.png',
                    label: 'Boost\nenergy',
                    value: 'Boost energy',
                    isSelected: controller.userProfile.motivations
                        .contains('Boost energy'),
                    onTap: () => controller.toggleMotivation('Boost energy'),
                  ),
                  _MotivationCard(
                    icon: 'assets/images/reduce_stress.png',
                    label: 'Reduce\nstress',
                    value: 'Reduce stress',
                    isSelected: controller.userProfile.motivations
                        .contains('Reduce stress'),
                    onTap: () => controller.toggleMotivation('Reduce stress'),
                  ),
                  _MotivationCard(
                    icon: 'assets/images/live_healthier.png',
                    label: 'Live\nhealthier',
                    value: 'Live healthier',
                    isSelected: controller.userProfile.motivations
                        .contains('Live healthier'),
                    onTap: () => controller.toggleMotivation('Live healthier'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 5. Bottom banner — gradient bg, semi bold text, 56x56 icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    transform: GradientRotation(87.69 * 3.14159 / 180),
                    colors: [
                      Color(0xFFFBF0FF),
                      Color(0xFFEDB5FF),
                      Color(0xFFFAEAFF),
                    ],
                    stops: [0.0026, 0.4841, 0.9844],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/medal.png',
                      height: 56,
                      width: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your goals, your way.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            "We're here to support you!",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _MotivationCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Selected: pink shadow; Unselected: purple shadow
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF136B), Color(0xFFFF607B)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF617B).withValues(alpha: 0.45)
                  : const Color(0xFF612077).withValues(alpha: 0.17),
              blurRadius: 17.3,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        // 2px padding = gradient stroke width
        padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(isSelected ? 10 : 12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      icon,
                      height: 36,
                      width: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF136B), Color(0xFFFF607B)],
                          )
                        : null,
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!, width: 2),
                    color: isSelected ? null : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 11),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
