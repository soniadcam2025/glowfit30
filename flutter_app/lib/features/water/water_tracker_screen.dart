import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/water_controller.dart';
import 'hydration_settings_screen.dart';
import 'water_widgets.dart';

/// Quick-add presets, in millilitres.
const _quickAdds = [250, 500, 750, 1000];

class WaterTrackerScreen extends StatelessWidget {
  const WaterTrackerScreen({super.key});

  WaterController get _c => Get.find<WaterController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: waterBg,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: WaterRing(
                          progress: _c.progress,
                          consumedLabel: _c.consumedLabel,
                          goalLabel: _c.goalLabel,
                          percent: _c.percent,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildStatus(),
                      const SizedBox(height: 22),
                      _sectionTitle('Quick Add'),
                      const SizedBox(height: 10),
                      _buildQuickAdd(context),
                      if (_c.goalReached) ...[
                        const SizedBox(height: 16),
                        _buildGoalCompleteCard(),
                      ] else ...[
                        const SizedBox(height: 16),
                        _buildSmartTipCard(),
                      ],
                      const SizedBox(height: 20),
                      _buildRecentHeader(),
                      const SizedBox(height: 10),
                      _buildRecentIntake(),
                      if (!_c.goalReached) ...[
                        const SizedBox(height: 14),
                        _buildConsistencyTip(),
                      ],
                      const SizedBox(height: 22),
                      WaterPrimaryButton(
                        label: 'Add More Water',
                        icon: Icons.water_drop_rounded,
                        onTap: () => showCustomAmountSheet(context),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

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
              'Water Tracker',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: waterDark,
              ),
            ),
          ),
          WaterCircleButton(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HydrationSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATUS ────────────────────────────────────────────────────────────────

  Widget _buildStatus() {
    return Column(
      children: [
        Text(
          _c.statusHeadline,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: waterPink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _c.statusSubline,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[600]),
        ),
        if (_c.goalReached && _c.remindersPausedToday.value) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF0E6EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reminders paused for today',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: waterDark,
                  ),
                ),
                const SizedBox(width: 6),
                const WaterDropIcon(size: 15),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── QUICK ADD ─────────────────────────────────────────────────────────────

  Widget _buildQuickAdd(BuildContext context) {
    return Row(
      children: [
        for (final ml in _quickAdds) ...[
          Expanded(child: _quickAddTile(ml)),
          const SizedBox(width: 8),
        ],
        Expanded(child: _customTile(context)),
      ],
    );
  }

  Widget _quickAddTile(int ml) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _c.addWater(ml);
      },
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0E6EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WaterGlassIcon(size: 28),
            const SizedBox(height: 6),
            Text(
              ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}L' : '${ml}ml',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: waterDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customTile(BuildContext context) {
    return GestureDetector(
      onTap: () => showCustomAmountSheet(context),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: waterPinkSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: waterPinkSoft.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: waterPink),
            ),
            const SizedBox(height: 6),
            Text(
              'Custom',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: waterPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CARDS ─────────────────────────────────────────────────────────────────

  Widget _buildGoalCompleteCard() {
    return WaterCard(
      color: const Color(0xFFE9F9EE),
      child: Row(
        children: [
          const WaterIconBadge(
            icon: Icons.emoji_events_rounded,
            color: Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Hydration Goal Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Great job! Keep it up and stay consistent.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+250 ml bonus hydration',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            kWaterGoalCompleteArt,
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) => const SizedBox(width: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTipCard() {
    return WaterCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE7EF), Color(0xFFFFF1F5)],
      ),
      child: Row(
        children: [
          const WaterIconBadge(icon: Icons.lightbulb_outline_rounded, color: waterPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You\'re slightly behind today.\nTry to drink one glass before 4 PM.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            kWaterSmartTipArt,
            width: 52,
            height: 52,
            errorBuilder: (_, __, ___) => const SizedBox(width: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyTip() {
    return WaterCard(
      color: const Color(0xFFEFF6FF),
      child: Row(
        children: [
          const WaterIconBadge(icon: Icons.info_outline_rounded, color: Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip: Consistency is key!',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Small sips throughout the day keep you hydrated and energized.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const WaterDropIcon(size: 26),
        ],
      ),
    );
  }

  // ─── RECENT INTAKE ─────────────────────────────────────────────────────────

  Widget _buildRecentHeader() {
    return Row(
      children: [
        Expanded(child: _sectionTitle('Recent Intake')),
        GestureDetector(
          onTap: () => Get.snackbar('Coming soon', 'Full intake history',
              snackPosition: SnackPosition.BOTTOM),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: waterPink,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: waterPink),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentIntake() {
    if (_c.entries.isEmpty) {
      return WaterCard(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: Text(
            'Nothing logged yet today.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500]),
          ),
        ),
      );
    }

    return WaterCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (final e in _c.entries.take(5)) _intakeRow(e),
        ],
      ),
    );
  }

  Widget _intakeRow(WaterEntry e) {
    final h = e.at.hour % 12 == 0 ? 12 : e.at.hour % 12;
    final m = e.at.minute.toString().padLeft(2, '0');
    final suffix = e.at.hour >= 12 ? 'PM' : 'AM';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const WaterGlassIcon(size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${e.amountMl}ml',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: waterDark,
              ),
            ),
          ),
          Text(
            '$h:$m $suffix',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey[500]),
            onSelected: (v) {
              if (v == 'delete') _c.removeEntry(e.id);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: waterDark,
        ),
      );
}

// ─── CUSTOM AMOUNT SHEET ─────────────────────────────────────────────────────

/// Bottom sheet for logging an exact amount. Presets fill the field rather than
/// logging immediately, so the value is always confirmed by the primary button —
/// the design shows the amount echoed in that button's label.
void showCustomAmountSheet(BuildContext context) {
  final c = Get.find<WaterController>();
  final controller = TextEditingController(text: '350');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final amount = int.tryParse(controller.text.trim()) ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Custom Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add the exact amount of water you drank.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: WaterDropIcon(size: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E0E4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: waterDark,
                                ),
                              ),
                            ),
                            Text(
                              'ml',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final preset in [100, 150, 200, 300]) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.text = preset.toString();
                            setState(() {});
                          },
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: const Color(0xFFE8E0E4)),
                            ),
                            child: Text(
                              '$preset ml',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (preset != 300) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Opacity(
                  // Disabled rather than hidden, so the button never jumps.
                  opacity: amount > 0 ? 1 : 0.5,
                  child: WaterPrimaryButton(
                    label: 'Add $amount ml',
                    icon: Icons.check_circle_rounded,
                    onTap: () {
                      if (amount <= 0) return;
                      c.addWater(amount);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
