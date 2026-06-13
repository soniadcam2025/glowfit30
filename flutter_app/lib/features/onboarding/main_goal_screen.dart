import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_decorations.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/app_spacing.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class MainGoalScreen extends StatelessWidget {
  const MainGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: OnboardingBase(
        step: 3,
        showBack: true,
        titleWidget: AppTypography.screenTitle(
          prefix: "What's your\n",
          highlight: 'Main goal?',
        ),
        onContinue: () {
          if (controller.userProfile.mainGoal != null &&
              controller.userProfile.mainGoal!.isNotEmpty) {
            controller.setMainGoal(controller.userProfile.mainGoal!);
          }
        },
        content: GetBuilder<OnboardingController>(
          builder: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose one',
                style: AppTypography.onboardingSubtitle(),
              ),
              const SizedBox(height: 24),
              _GoalCard(
                image: 'assets/images/Loss_weight.png',
                title: 'Loss weight',
                subtitle: 'and stay fit',
                value: 'Loss weight',
                isSelected: controller.userProfile.mainGoal == 'Loss weight',
                onTap: () => controller.setMainGoalSelection('Loss weight'),
              ),
              const SizedBox(height: 12),
              _GoalCard(
                image: 'assets/images/Lift_tone.png',
                title: 'Lift & tone',
                subtitle: 'glutes',
                value: 'Lift & tone',
                isSelected: controller.userProfile.mainGoal == 'Lift & tone',
                onTap: () => controller.setMainGoalSelection('Lift & tone'),
              ),
              const SizedBox(height: 12),
              _GoalCard(
                image: 'assets/images/Losebellyfat.png',
                title: 'Lose',
                subtitle: 'belly fat',
                value: 'Lose belly fat',
                isSelected: controller.userProfile.mainGoal == 'Lose belly fat',
                onTap: () => controller.setMainGoalSelection('Lose belly fat'),
              ),
              const SizedBox(height: 12),
              _GoalCard(
                image: 'assets/images/buildmuscles.png',
                title: 'Build muscles',
                subtitle: '& strength',
                value: 'Build muscles',
                isSelected: controller.userProfile.mainGoal == 'Build muscles',
                onTap: () => controller.setMainGoalSelection('Build muscles'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerContent = Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: Image.asset(
            image,
            width: 100,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 110,
              color: const Color(0xFFF5F5F5),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle()),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.cardSubtitle()),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFFF136B)
                  : const Color(0xFFE0E0E0),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: isSelected
          ? AppDecorations.selectedCard(height: 110, child: innerContent)
          : Container(
              height: 110,
              decoration: AppDecorations.unselectedCard(),
              child: innerContent,
            ),
    );
  }
}
