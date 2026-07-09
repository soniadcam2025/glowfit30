import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_settings_widgets.dart';

class _Track {
  final String name;
  final String subtitle;
  final int bpm;
  final Color color;

  const _Track({
    required this.name,
    required this.subtitle,
    required this.bpm,
    required this.color,
  });
}

const _recentlyImported = [
  _Track(name: 'Morning Run', subtitle: '', bpm: 128, color: Color(0xFFFF136B)),
  _Track(name: 'Energy Boost', subtitle: '', bpm: 135, color: Color(0xFF1A1A2E)),
];

const _musicLibrary = [
  _Track(
      name: 'Fresh Day',
      subtitle: 'Energetic Beats',
      bpm: 128,
      color: Color(0xFFFF136B)),
  _Track(
      name: 'Power Up', subtitle: 'Workout Hits', bpm: 135, color: Color(0xFFFF136B)),
  _Track(
      name: 'Stronger Every Day',
      subtitle: 'Motivation Mix',
      bpm: 135,
      color: Color(0xFFFF136B)),
  _Track(
      name: 'Calm Flow', subtitle: 'Relaxing Vibes', bpm: 92, color: Color(0xFFFF136B)),
];

class ChangeMusicScreen extends StatefulWidget {
  const ChangeMusicScreen({super.key});

  @override
  State<ChangeMusicScreen> createState() => _ChangeMusicScreenState();
}

class _ChangeMusicScreenState extends State<ChangeMusicScreen> {
  String _playingTrack = 'Fresh Day';
  double _volume = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SettingsAppBar(
                      title: 'Change Music',
                      subtitle: 'Select background music for your workout',
                    ),
                    const SizedBox(height: 8),
                    const SettingsSectionHeader('IMPORT MUSIC'),
                    _importRow(
                      icon: Icons.file_download_rounded,
                      title: 'Import from Device',
                      subtitle: 'Add your own MP3 songs',
                    ),
                    _importRow(
                      icon: Icons.folder_rounded,
                      title: 'Browse Files',
                      subtitle: 'Select music from your files',
                    ),
                    SettingsSectionHeader(
                      'RECENTLY IMPORTED',
                      trailing: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View All',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kSettingsPink)),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: kSettingsPink),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (var i = 0; i < _recentlyImported.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: _recentCard(_recentlyImported[i])),
                          ],
                        ],
                      ),
                    ),
                    const SettingsSectionHeader('MUSIC LIBRARY'),
                    ..._musicLibrary.map(_libraryRow),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _volumeBar(),
          ],
        ),
      ),
    );
  }

  Widget _importRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kSettingsDarkText)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentCard(_Track track) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: track.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: track.color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(track.name,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kSettingsDarkText)),
                Text('${track.bpm} BPM',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kSettingsPink)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _playingTrack = track.name),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: kSettingsPink, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _libraryRow(_Track track) {
    final isPlaying = _playingTrack == track.name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: track.color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kSettingsDarkText)),
                Text(track.subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
                Text('${track.bpm} BPM',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kSettingsPink)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _playingTrack = track.name),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isPlaying ? kSettingsPink : kSettingsPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : kSettingsPink,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  Widget _volumeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: kSettingsPink.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('Music Volume',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kSettingsDarkText)),
              const Spacer(),
              Text('${(_volume * 100).round()}%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kSettingsPink)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _volume,
              onChanged: (v) => setState(() => _volume = v),
              activeColor: kSettingsPink,
              inactiveColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }
}
