import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/water_controller.dart';
import 'water_widgets.dart';

/// Goal presets in millilitres, matching the reference design.
const _goalPresets = [1500, 2000, 2500, 3000];

class HydrationSettingsScreen extends StatelessWidget {
  const HydrationSettingsScreen({super.key});

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
                    children: [
                      _buildDailyGoalCard(),
                      const SizedBox(height: 12),
                      _buildReminderCard(),
                      const SizedBox(height: 12),
                      _buildQuietHoursRow(context),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.volume_up_rounded,
                        color: const Color(0xFFF59E0B),
                        title: 'Sound',
                        subtitle: 'Play a sound with reminders',
                        value: _c.soundEnabled.value,
                        onChanged: (v) => _c.soundEnabled.value = v,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.vibration_rounded,
                        color: const Color(0xFFEC4899),
                        title: 'Vibration',
                        subtitle: 'Vibrate with reminders',
                        value: _c.vibrationEnabled.value,
                        onChanged: (v) => _c.vibrationEnabled.value = v,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.nightlight_round,
                        color: const Color(0xFF8B5CF6),
                        title: 'Smart Mode',
                        subtitle:
                            'We\'ll adjust reminders based on your drinking patterns to keep you on track.',
                        value: _c.smartMode.value,
                        onChanged: (v) => _c.smartMode.value = v,
                      ),
                      const SizedBox(height: 22),
                      WaterPrimaryButton(
                        label: 'Save Changes',
                        icon: Icons.check_circle_rounded,
                        onTap: () async {
                          final ok = await _c.saveSettings();
                          if (!context.mounted) return;
                          // Only leave the screen on success — popping after a
                          // failure would hide the fact that nothing saved.
                          if (ok) Navigator.of(context).maybePop();
                          Get.snackbar(
                            ok ? 'Saved' : 'Not saved',
                            ok
                                ? 'Hydration settings updated'
                                : 'Could not save. Check your connection.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          WaterCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Hydration Settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: waterDark,
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  // ─── DAILY GOAL ────────────────────────────────────────────────────────────

  Widget _buildDailyGoalCard() {
    final selected = _goalPresets.indexOf(_c.goalMl.value);

    return WaterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WaterIconBadge(icon: Icons.water_drop_rounded, color: waterBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Goal',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: waterDark,
                      ),
                    ),
                    Text(
                      'How much water do you want to drink daily?',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepper(Icons.remove_rounded, () => _c.nudgeGoal(-100)),
              const SizedBox(width: 26),
              Text(
                _c.goalLabel,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: waterDark,
                ),
              ),
              const SizedBox(width: 26),
              _stepper(Icons.add_rounded, () => _c.nudgeGoal(100)),
            ],
          ),
          const SizedBox(height: 16),
          // "Custom" is a fifth pill that stays selected whenever the goal is
          // not one of the presets — e.g. after using the +/- stepper.
          WaterPillGroup(
            labels: [
              ..._goalPresets.map((ml) => '${(ml / 1000).toStringAsFixed(1)} L'),
              'Custom',
            ],
            selected: selected >= 0 ? selected : _goalPresets.length,
            onSelected: (i) {
              if (i < _goalPresets.length) _c.setGoalMl(_goalPresets[i]);
            },
          ),
        ],
      ),
    );
  }

  Widget _stepper(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E0E4)),
        ),
        child: Icon(icon, size: 20, color: waterDark),
      ),
    );
  }

  // ─── SMART REMINDER ────────────────────────────────────────────────────────

  Widget _buildReminderCard() {
    return WaterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WaterIconBadge(
                icon: Icons.notifications_rounded,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminder',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: waterDark,
                      ),
                    ),
                    Text(
                      'Remind me to drink water.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _switch(_c.smartReminder.value, (v) => _c.smartReminder.value = v),
            ],
          ),
          // The interval only matters when reminders are on, so it collapses
          // with the toggle rather than sitting there inert.
          if (_c.smartReminder.value) ...[
            const SizedBox(height: 16),
            Text(
              'Reminder Interval',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: waterDark,
              ),
            ),
            Text(
              'How often should we remind you?',
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            WaterPillGroup(
              labels: ReminderInterval.values.map((e) => e.label).toList(),
              selected: ReminderInterval.values.indexOf(_c.interval.value),
              onSelected: (i) => _c.interval.value = ReminderInterval.values[i],
            ),
          ],
        ],
      ),
    );
  }

  // ─── QUIET HOURS ───────────────────────────────────────────────────────────

  Widget _buildQuietHoursRow(BuildContext context) {
    return WaterCard(
      child: Row(
        children: [
          const WaterIconBadge(
            icon: Icons.nightlight_round,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiet Hours',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                Text(
                  'No reminders during this time.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _pickQuietHours(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _c.quietHoursLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFF8B5CF6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickQuietHours(BuildContext context) async {
    final from = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _c.quietFromHour.value, minute: 0),
      helpText: 'Quiet hours start',
    );
    if (from == null || !context.mounted) return;

    final to = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _c.quietToHour.value, minute: 0),
      helpText: 'Quiet hours end',
    );
    if (to == null) return;

    _c.quietFromHour.value = from.hour;
    _c.quietToHour.value = to.hour;
  }

  // ─── TOGGLE ROW ────────────────────────────────────────────────────────────

  Widget _buildToggleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return WaterCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WaterIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: waterDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _switch(value, onChanged),
        ],
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: waterPink,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey[300],
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
