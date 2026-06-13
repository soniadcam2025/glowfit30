import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBase extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final int step;
  final Widget content;
  final VoidCallback? onContinue;
  final bool showBack;
  final String footerText;

  const OnboardingBase({
    super.key,
    this.title = '',
    required this.content,
    required this.step,
    this.titleWidget,
    this.subtitle,
    this.onContinue,
    this.showBack = true,
    this.footerText = 'You can change this later',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Wave background
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _WaveBackground(),
        ),
        // Content — transparent so wave shows through footer area
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
              // Footer sits over the wave (transparent background)
              _Footer(onContinue: onContinue, footerText: footerText),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveBackground extends StatelessWidget {
  const _WaveBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backPaint = Paint()
      ..color = AppColors.splashGradientStart.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, size.height * 0.55);
    backPath.cubicTo(
      size.width * 0.2, size.height * 0.25,
      size.width * 0.45, size.height * 0.65,
      size.width * 0.65, size.height * 0.38,
    );
    backPath.cubicTo(
      size.width * 0.8, size.height * 0.18,
      size.width * 0.9, size.height * 0.45,
      size.width, size.height * 0.3,
    );
    backPath.lineTo(size.width, size.height);
    backPath.lineTo(0, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    final frontPaint = Paint()
      ..color = AppColors.splashGradientEnd.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, size.height * 0.75);
    frontPath.cubicTo(
      size.width * 0.15, size.height * 0.5,
      size.width * 0.38, size.height * 0.85,
      size.width * 0.55, size.height * 0.62,
    );
    frontPath.cubicTo(
      size.width * 0.72, size.height * 0.42,
      size.width * 0.88, size.height * 0.72,
      size.width, size.height * 0.55,
    );
    frontPath.lineTo(size.width, size.height);
    frontPath.lineTo(0, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final String footerText;

  const _Footer({this.onContinue, required this.footerText});

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
                borderRadius: BorderRadius.circular(23),
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
          const SizedBox(height: 10),
          Text(
            footerText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
