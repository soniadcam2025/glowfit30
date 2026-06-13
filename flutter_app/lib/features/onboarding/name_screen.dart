import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    final hasText = nameController.text.trim().isNotEmpty;

    return Scaffold(
      body: OnboardingBase(
        step: 5,
        showBack: true,
        titleWidget: AppTypography.screenTitle(
          prefix: 'What should we\ncall ',
          highlight: 'You?',
          inlineTrailing: Image.asset(
            'assets/images/wave_hand.png',
            height: 28,
            width: 28,
            fit: BoxFit.contain,
          ),
        ),
        onContinue: hasText ? () => controller.setName(nameController.text.trim()) : null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's make this personal!",
              style: AppTypography.onboardingSubtitle(),
            ),
            const SizedBox(height: 32),

            // "Your name" label above the card
            Text(
              'Your name',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Input card — person icon | text field | green check
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Person icon — neonMagenta (#E91E63) to match screenshot
                  const Icon(
                    Icons.person,
                    color: AppColors.neonMagenta,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      style: AppTypography.bodyLarge().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: AppTypography.bodyMedium().copyWith(
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 18),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: hasText
                          ? (_) =>
                              controller.setName(nameController.text.trim())
                          : null,
                    ),
                  ),
                  // Green checkmark appears once user types
                  if (hasText) ...[
                    const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                  ] else
                    const SizedBox(width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
