import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_settings_widgets.dart';

class WorkoutSettingsScreen extends StatefulWidget {
  const WorkoutSettingsScreen({super.key});

  @override
  State<WorkoutSettingsScreen> createState() => _WorkoutSettingsScreenState();
}

class _WorkoutSettingsScreenState extends State<WorkoutSettingsScreen> {
  bool _voiceGuide = true;
  bool _coachTips = true;
  bool _backgroundMusic = true;
  bool _isPlaying = true;
  double _volume = 0.7;
  bool _timeBasedDisplay = true;
  int _prepCountdown = 10;
  int _restTimer = 30;
  bool _keepScreenAwake = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsAppBar(
                title: 'Workout Settings',
                subtitle: 'Customize your workout experience',
              ),
              const SizedBox(height: 8),
              const SettingsSectionHeader('AUDIO'),
              SettingsToggleRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Voice Guide',
                subtitle: 'Get voice instructions during workout',
                value: _voiceGuide,
                onChanged: (v) => setState(() => _voiceGuide = v),
              ),
              const SettingsDivider(),
              SettingsToggleRow(
                icon: Icons.lightbulb_rounded,
                title: 'Coach Tips',
                subtitle: 'Tips and motivation during workout',
                value: _coachTips,
                onChanged: (v) => setState(() => _coachTips = v),
              ),
              const SettingsSectionHeader('MUSIC'),
              SettingsToggleRow(
                icon: Icons.music_note_rounded,
                title: 'Background Music',
                subtitle: 'Play music during workout',
                value: _backgroundMusic,
                onChanged: (v) => setState(() => _backgroundMusic = v),
              ),
              if (_backgroundMusic)
                MusicPlayerCard(
                  isPlaying: _isPlaying,
                  onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                  onChangeMusic: () {},
                  volume: _volume,
                  onVolumeChanged: (v) => setState(() => _volume = v),
                ),
              const SettingsSectionHeader('WORKOUT DISPLAY (Adaptive)'),
              _buildDisplayPreviewRow(),
              const SettingsSectionHeader('TIMER'),
              _buildStepperRow(
                icon: Icons.hourglass_bottom_rounded,
                title: 'Preparation Countdown',
                subtitle: 'Time before workout starts',
                value: _prepCountdown,
                onMinus: () =>
                    setState(() => _prepCountdown = (_prepCountdown - 5).clamp(0, 60)),
                onPlus: () =>
                    setState(() => _prepCountdown = (_prepCountdown + 5).clamp(0, 60)),
              ),
              _buildStepperRow(
                icon: Icons.timer_rounded,
                title: 'Rest Timer',
                subtitle: 'Time between exercises',
                value: _restTimer,
                onMinus: () =>
                    setState(() => _restTimer = (_restTimer - 5).clamp(0, 120)),
                onPlus: () =>
                    setState(() => _restTimer = (_restTimer + 5).clamp(0, 120)),
              ),
              const SettingsSectionHeader('DISPLAY'),
              SettingsToggleRow(
                icon: Icons.smartphone_rounded,
                title: 'Keep Screen Awake',
                subtitle: 'Prevent screen from turning off',
                value: _keepScreenAwake,
                onChanged: (v) => setState(() => _keepScreenAwake = v),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayPreviewRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _displayPreviewCard(
              icon: Icons.access_time_rounded,
              primary: '00:45',
              kcal: '128',
              selected: _timeBasedDisplay,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _timeBasedDisplay = !_timeBasedDisplay),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kSettingsPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: kSettingsPink, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _displayPreviewCard(
              icon: Icons.refresh_rounded,
              primary: '12/15',
              primaryUnit: 'reps',
              kcal: '148',
              selected: !_timeBasedDisplay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayPreviewCard({
    required IconData icon,
    required String primary,
    String? primaryUnit,
    required String kcal,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? kSettingsPink.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? kSettingsPink.withValues(alpha: 0.3) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kSettingsPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: kSettingsPink),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: primary,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kSettingsDarkText),
              ),
              if (primaryUnit != null)
                TextSpan(
                  text: ' $primaryUnit',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                ),
            ]),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
              Text(kcal,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kSettingsPink)),
              Text(' kcal',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kSettingsPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kSettingsPink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700, color: kSettingsDarkText)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          _stepperButton(Icons.remove, onMinus),
          SizedBox(
            width: 56,
            child: Text(
              '$value sec',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kSettingsPink),
            ),
          ),
          _stepperButton(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: kSettingsPink.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: kSettingsPink),
      ),
    );
  }
}
