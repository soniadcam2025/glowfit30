import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'change_music_screen.dart';
import 'workout_settings_widgets.dart';

class MusicSettingsScreen extends StatefulWidget {
  const MusicSettingsScreen({super.key});

  @override
  State<MusicSettingsScreen> createState() => _MusicSettingsScreenState();
}

class _MusicSettingsScreenState extends State<MusicSettingsScreen> {
  bool _mute = true;
  bool _voiceGuide = true;
  bool _coachTips = true;
  bool _backgroundMusic = true;
  bool _isPlaying = true;
  double _volume = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsAppBar(title: 'Music Settings'),
              const SizedBox(height: 8),
              const SettingsSectionHeader('MUTE'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mute all workout audio',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600])),
                    Switch(
                      value: _mute,
                      onChanged: (v) => setState(() => _mute = v),
                      activeColor: Colors.white,
                      activeTrackColor: kSettingsPink,
                    ),
                  ],
                ),
              ),
              const SettingsDivider(),
              const SettingsSectionHeader('AUDIO'),
              SettingsToggleRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Voice Guide',
                subtitle: 'Get voice instructions during workout',
                value: _voiceGuide,
                onChanged: (v) => setState(() => _voiceGuide = v),
              ),
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
                  onChangeMusic: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangeMusicScreen()),
                  ),
                  volume: _volume,
                  onVolumeChanged: (v) => setState(() => _volume = v),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
