import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/constants/app_constants.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/storage/preferences.dart';
import '../../routes/app_pages.dart';
import '../../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppConstants.animationDuration),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _checkAuthAndRoute();
      // _checkAuthAndRoute is async but fire-and-forget is fine here
    });
  }

  Future<void> _checkAuthAndRoute() async {
    final prefs = Get.find<Preferences>();
    final hasToken = await prefs.hasAccessToken();
    final controller = Get.find<OnboardingController>();

    if (hasToken && controller.isComplete) {
      // Valid session — register FCM token for already-logged-in users
      Get.find<NotificationService>().registerToken();
      Get.offAllNamed(Routes.home);
      return;
    }

    if (controller.isComplete && !hasToken) {
      // Completed onboarding before but JWT was cleared (e.g. expiry/401)
      // Send to welcome screen so user can re-authenticate with Google
      Get.offAllNamed(Routes.welcome);
      return;
    }

    // No JWT and not fully onboarded — check Firebase for mid-onboarding resume
    final firebaseUser = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (firebaseUser != null && controller.currentStep.value > 1) {
      Get.offAllNamed(controller.resumeRoute);
      return;
    }

    // New user — stay on splash and show Get Started
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero_woman.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Image.asset(
                      'assets/images/glowfit_logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingLarge),
                    child: Column(
                      children: [
                        Text(
                          '30-Days Smart Fitness for Women',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSmall().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Workout • Diet • Beauty • Transformation',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingLarge),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.language),
                          child: Container(
                            width: double.infinity,
                            height: AppConstants.buttonHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.neonMagenta, AppColors.neonPink],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonMagenta.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: AppTypography.button().copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Your best version starts today ',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall().copyWith(color: AppColors.textSecondary),
                            ),
                            Image.asset(
                              'assets/images/star1.png',
                              height: 18,
                              width: 18,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
