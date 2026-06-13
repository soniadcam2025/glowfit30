import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../config/theme/app_decorations.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class FocusAreaScreen extends StatelessWidget {
  const FocusAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: OnboardingBase(
        step: 4,
        showBack: true,
        titleWidget: AppTypography.screenTitle(
          prefix: "What's your\n",
          highlight: 'Focus area?',
        ),
        onContinue: () {
          if (controller.userProfile.focusAreas != null &&
              controller.userProfile.focusAreas!.isNotEmpty) {
            controller.setFocusAreas(controller.userProfile.focusAreas!);
          }
        },
        content: GetBuilder<OnboardingController>(
          builder: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose up to 3',
                style: AppTypography.onboardingSubtitle(),
              ),
              const SizedBox(height: 28),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _FocusCard(
                    icon: 'assets/icons/firm_abs.svg',
                    label: 'Firm abs',
                    isSelected: controller.userProfile.focusAreas.contains('Firm abs'),
                    onTap: () => controller.toggleFocusArea('Firm abs'),
                  ),
                  _FocusCard(
                    icon: 'assets/icons/toned_legs.svg',
                    label: 'Toned legs',
                    isSelected: controller.userProfile.focusAreas.contains('Toned legs'),
                    onTap: () => controller.toggleFocusArea('Toned legs'),
                  ),
                  _FocusCard(
                    icon: 'assets/icons/bubble_butt.svg',
                    label: 'Bubble butt',
                    isSelected: controller.userProfile.focusAreas.contains('Bubble butt'),
                    onTap: () => controller.toggleFocusArea('Bubble butt'),
                  ),
                  _FocusCard(
                    icon: 'assets/icons/slim_arms.svg',
                    label: 'Slim arms',
                    isSelected: controller.userProfile.focusAreas.contains('Slim arms'),
                    onTap: () => controller.toggleFocusArea('Slim arms'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FocusCardFullWidth(
                icon: 'assets/icons/full_body.svg',
                label: 'Full body',
                isSelected: controller.userProfile.focusAreas.contains('Full body'),
                onTap: () => controller.toggleFocusArea('Full body'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grid card (2-column) ─────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.cardTitle().copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _SelectCircle(isSelected: isSelected),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: isSelected
          ? AppDecorations.selectedCard(child: inner, borderRadius: 16)
          : Container(
              decoration: AppDecorations.unselectedCard(borderRadius: 16),
              child: inner,
            ),
    );
  }
}

// ── Full-width card ──────────────────────────────────────────────────────────

class _FocusCardFullWidth extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusCardFullWidth({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 55,
            height: 55,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppTypography.cardTitle()),
          ),
          _SelectCircle(isSelected: isSelected),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: isSelected
          ? AppDecorations.selectedCard(child: inner, borderRadius: 16)
          : Container(
              decoration: AppDecorations.unselectedCard(borderRadius: 16),
              child: inner,
            ),
    );
  }
}

// ── Shared selection circle ──────────────────────────────────────────────────

class _SelectCircle extends StatelessWidget {
  final bool isSelected;
  const _SelectCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFFF136B) : const Color(0xFFE0E0E0),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 13)
          : null,
    );
  }
}
