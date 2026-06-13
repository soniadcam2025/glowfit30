import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/app_spacing.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: OnboardingBase(
              step: 1,
              showBack: true,
              titleWidget: AppTypography.screenTitle(
                prefix: 'Choose Your\n',
                highlight: 'Language',
                inlineTrailing: Image.asset(
                  'assets/images/earth.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
              ),
              onContinue: () => controller.nextStep(),
              content: GetBuilder<OnboardingController>(
                builder: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "We'll personalize everything for you",
                      style: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _LanguageOption(
                      flag: 'assets/images/usa.png',
                      language: 'English',
                      isSelected: controller.userProfile.language == 'English',
                      onTap: () => controller.selectLanguage('English'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageOption(
                      flag: 'assets/images/india.png',
                      language: 'Hindi',
                      isSelected: controller.userProfile.language == 'Hindi',
                      onTap: () => controller.selectLanguage('Hindi'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageOption(
                      flag: 'assets/images/india.png',
                      language: 'Bengali',
                      isSelected: controller.userProfile.language == 'Bengali',
                      onTap: () => controller.selectLanguage('Bengali'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageOption(
                      flag: 'assets/images/espanol.png',
                      language: 'Espanol',
                      isSelected: controller.userProfile.language == 'Espanol',
                      onTap: () => controller.selectLanguage('Espanol'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageOption(
                      flag: 'assets/images/brazil.png',
                      language: 'Brazil',
                      isSelected: controller.userProfile.language == 'Brazil',
                      onTap: () => controller.selectLanguage('Brazil'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              flag,
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Text(
              language,
              style: AppTypography.bodyLarge().copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.neonMagenta : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonMagenta,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
