import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBase extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final int step;
  final Widget content;
  final VoidCallback? onContinue;
  final bool showBack;

  const OnboardingBase({
    super.key,
    this.title = '',
    required this.content,
    required this.step,
    this.titleWidget,
    this.subtitle,
    this.onContinue,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // White background only for header + scrollable body
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(step: step, showBack: showBack),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (titleWidget != null)
                                titleWidget!
                              else if (title.isNotEmpty)
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (title.isNotEmpty) const SizedBox(height: 24),
                              content,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Footer(onContinue: onContinue),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  final bool showBack;

  const _Header({required this.step, required this.showBack});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => controller.goBack(),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
            )
          else
            const SizedBox(width: 20),
          const SizedBox(width: 10),
          Text(
            'Step $step of 10',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: step / 10,
                minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF146B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback? onContinue;

  const _Footer({this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(0.0, 0.86),
                  end: Alignment(0.98, 0.29),
                  colors: [Color(0xFFFF136B), Color(0xFFFF607B)],
                ),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
        ],
      ),
    );
  }
}
