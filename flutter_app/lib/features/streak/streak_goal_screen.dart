import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../services/api_service.dart';
import '../water/water_widgets.dart';

/// Goal presets, in days.
const _presets = [7, 14, 21, 30];

/// Set Day Streak Goal.
///
/// The streak itself is the *workout* streak already shown on the home screen
/// (consecutive days with a completed workout, computed by the API). This screen
/// only chooses what it counts towards — `streakGoalDays` on the profile, which
/// nothing stored before.
class StreakGoalScreen extends StatefulWidget {
  const StreakGoalScreen({super.key});

  @override
  State<StreakGoalScreen> createState() => _StreakGoalScreenState();
}

class _StreakGoalScreenState extends State<StreakGoalScreen> {
  final _home = Get.find<HomeController>();
  late int _goal = _home.streakGoalDays.value;
  bool _saving = false;

  int get _streak => _home.streak.value;
  double get _progress => _goal == 0 ? 0 : (_streak / _goal).clamp(0.0, 1.0);
  int get _percent => (_progress * 100).round();
  int get _daysLeft => (_goal - _streak).clamp(0, _goal);

  Future<void> _save() async {
    setState(() => _saving = true);
    final res = await Get.find<ApiService>().patchProfile({'streakGoalDays': _goal});
    if (!mounted) return;
    setState(() => _saving = false);

    final ok = res != null;
    if (ok) {
      _home.streakGoalDays.value = _goal;
      Navigator.of(context).maybePop();
    }
    Get.snackbar(
      ok ? 'Goal saved' : 'Not saved',
      ok ? 'Your streak goal is now $_goal days' : 'Could not save. Check your connection.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: waterBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(child: _buildRing()),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '$_percent% of your goal',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: waterPink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _daysLeft == 0
                            ? 'Goal reached — set a bigger one!'
                            : '$_daysLeft days left to reach your goal',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Choose Your Goal',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: waterDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGoalTiles(),
                    const SizedBox(height: 16),
                    _buildEncouragementCard(),
                    const SizedBox(height: 26),
                    WaterPrimaryButton(
                      label: _saving ? 'Saving…' : 'Save Goal',
                      onTap: _saving ? () {} : _save,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          WaterCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Set Day Streak Goal',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: waterDark,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 18))),
          ),
        ],
      ),
    );
  }

  // ─── RING ──────────────────────────────────────────────────────────────────

  Widget _buildRing() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              size: const Size(220, 220),
              painter: _StreakRingPainter(value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 2),
              // Baseline-aligned so "12" and "/30" sit on the same line, as in
              // the design, despite the size difference.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_streak',
                    style: GoogleFonts.poppins(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: waterDark,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/$_goal',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Day Streak',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── GOAL TILES ────────────────────────────────────────────────────────────

  Widget _buildGoalTiles() {
    return Row(
      children: [
        for (var i = 0; i < _presets.length; i++) ...[
          Expanded(child: _goalTile(_presets[i])),
          if (i != _presets.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _goalTile(int days) {
    final selected = _goal == days;
    return GestureDetector(
      onTap: () => setState(() => _goal = days),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: selected ? waterPink : const Color(0xFFFDEEF3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : waterPink,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Days',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle_rounded, size: 17, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncouragementCard() {
    return WaterCard(
      color: const Color(0xFFFDEEF3),
      child: Row(
        children: [
          const WaterIconBadge(icon: Icons.track_changes_rounded, color: waterPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay consistent for $_goal days',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Build a powerful habit and unlock your best self.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  final double progress;
  _StreakRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final center = (Offset.zero & size).center;
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = waterPinkSoft.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = waterPink
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StreakRingPainter old) => old.progress != progress;
}
