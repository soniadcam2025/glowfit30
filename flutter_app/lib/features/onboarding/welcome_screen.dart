import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../routes/app_pages.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Title block
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // "Welcome to"
                  Text(
                    'Welcome to',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge().copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // "GlowFit 30! 👋"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GlowFit 30!',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineLarge().copyWith(
                          color: AppColors.neonMagenta,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to continue your fitness journey',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Google button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () async {
                  final user = await Get.find<AuthService>().signInWithGoogle();
                  if (user != null) {
                    final ob = Get.find<OnboardingController>();
                    // Sync onboarding answers to the server profile
                    final p = ob.userProfile;
                    final payload = <String, dynamic>{};
                    if (p.name?.isNotEmpty == true)       payload['name']         = p.name;
                    if (p.mainGoal != null)               payload['goal']         = p.mainGoal;
                    if (p.fitnessLevel != null)           payload['fitnessLevel'] = p.fitnessLevel;
                    if (p.dietStyle != null)              payload['dietStyle']    = p.dietStyle;
                    if (p.targetWeight != null)           payload['targetWeight'] = p.targetWeight;
                    if (p.focusAreas.isNotEmpty)          payload['focusAreas']   = p.focusAreas;
                    if (p.heightCm != null)               payload['height']       = p.heightCm;
                    if (p.currentWeight != null)          payload['weight']       = p.currentWeight;
                    if (payload.isNotEmpty) {
                      await Get.find<ApiService>().patchProfile(payload);
                    }
                    ob.completeOnboarding();
                  }
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Image.asset(
                          'assets/icons/google_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const _GoogleG(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Terms
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our\n'),
                    TextSpan(
                      text: 'Term of Service',
                      style: const TextStyle(
                        color: Color(0xFFFF136B),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const TextSpan(text: '  and  '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFFFF136B),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fallback Google "G" if asset not uploaded
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw colored arcs approximating Google G
    final paints = [
      Paint()..color = const Color(0xFF4285F4), // blue
      Paint()..color = const Color(0xFF34A853), // green
      Paint()..color = const Color(0xFFFBBC05), // yellow
      Paint()..color = const Color(0xFFEA4335), // red
    ];
    const sweeps = [1.57, 1.57, 0.79, 1.36];
    const starts = [0.0, 1.57, 3.14, 3.93];

    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        starts[i],
        sweeps[i],
        false,
        paints[i]..strokeWidth = 4..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
