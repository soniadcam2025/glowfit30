import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  bool _isFt = true;

  // Ft/In state
  int _ft = 5;
  int _inches = 4;

  // Cm state
  int _cm = 170;

  late final FixedExtentScrollController _ftCtrl;
  late final FixedExtentScrollController _inCtrl;
  late final FixedExtentScrollController _cmCtrl;

  static const double _itemH = 46.0;
  static const int _visibleCount = 9;
  static const double _pickerH = _itemH * _visibleCount;

  static const int _ftMin = 1;
  static const int _ftMax = 9;
  static const int _inMin = 0;
  static const int _inMax = 11;
  static const int _cmMin = 100;
  static const int _cmMax = 250;

  @override
  void initState() {
    super.initState();
    _ftCtrl = FixedExtentScrollController(initialItem: _ft - _ftMin);
    _inCtrl = FixedExtentScrollController(initialItem: _inches - _inMin);
    _cmCtrl = FixedExtentScrollController(initialItem: _cm - _cmMin);
  }

  @override
  void dispose() {
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _cmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wave bottom background (same as OnboardingBase)
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: _WaveBackground(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _buildHeader(context),

                // ── Body ────────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Your current\n',
                                    style: AppTypography.headlineLarge().copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 30,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Height?',
                                    style: AppTypography.headlineLarge().copyWith(
                                      color: AppColors.neonMagenta,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Cm / Ft toggle
                            _buildToggle(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Drum picker
                      Expanded(
                        child: _isFt ? _buildFtPicker() : _buildCmPicker(),
                      ),
                    ],
                  ),
                ),

                // ── Footer ──────────────────────────────────────────────────
                _buildFooter(context, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final progress = 7 / 10;
    return Padding(
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
                'Step 7 of 10',
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
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E2E2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF136B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cm / Ft toggle ────────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x96E2E2E2),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleOption('Cm', _isFt == false),
            _toggleOption('Ft', _isFt == true),
          ],
        ),
      ),
    );
  }

  Widget _toggleOption(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _isFt = label == 'Ft'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.neonMagenta : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.titleSmall().copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Ft + In two-column drum picker ────────────────────────────────────────
  Widget _buildFtPicker() {
    return Row(
      children: [
        Expanded(
          child: _drumColumn(
            controller: _ftCtrl,
            itemCount: _ftMax - _ftMin + 1,
            labelOf: (i) => (i + _ftMin).toString(),
            unit: 'Ft',
            onChanged: (i) => setState(() => _ft = i + _ftMin),
          ),
        ),
        Expanded(
          child: _drumColumn(
            controller: _inCtrl,
            itemCount: _inMax - _inMin + 1,
            labelOf: (i) => i.toString(),
            unit: 'In',
            onChanged: (i) => setState(() => _inches = i + _inMin),
          ),
        ),
      ],
    );
  }

  // ── Cm single-column drum picker ──────────────────────────────────────────
  Widget _buildCmPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _drumColumn(
        controller: _cmCtrl,
        itemCount: _cmMax - _cmMin + 1,
        labelOf: (i) => (i + _cmMin).toString(),
        unit: 'Cm',
        onChanged: (i) => setState(() => _cm = i + _cmMin),
      ),
    );
  }

  // ── Generic drum picker column ────────────────────────────────────────────
  Widget _drumColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelOf,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    const highlightH = _itemH;
    const topOffset = (_pickerH - highlightH) / 2;

    return SizedBox(
      height: _pickerH,
      child: Stack(
        children: [
          // ── Numbers ────────────────────────────────────────────────────
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemH,
            perspective: 0.001,
            diameterRatio: 200,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) => Center(
                child: Text(
                  labelOf(index),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // ── Pink horizontal highlight at selected row ───────────────────
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: highlightH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFF136B).withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Top white fade ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: _pickerH * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom white fade ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: _pickerH * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),

          // ── Unit label (Ft / In / Cm) at selected row ──────────────────
          Positioned(
            top: topOffset,
            right: 12,
            child: IgnorePointer(
              child: SizedBox(
                height: highlightH,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFFFF136B),
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer with gradient Continue button ──────────────────────────────────
  Widget _buildFooter(BuildContext context, OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: () => controller.setHeight(
          _isFt ? null : _cm,
          _isFt ? _ft : null,
          _isFt ? _inches : null,
        ),
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
                'Continue',
                style: AppTypography.button().copyWith(
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
    );
  }
}

// ── Wave background (same as OnboardingBase) ──────────────────────────────────
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
