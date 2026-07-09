import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kSettingsPink = Color(0xFFFF136B);
const kSettingsDarkText = Color(0xFF1A1A2E);

/// Shared back-button + title app bar used across the workout settings screens.
class SettingsAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SettingsAppBar({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: kSettingsDarkText),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kSettingsDarkText,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SettingsSectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.6,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kSettingsDarkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: kSettingsPink,
          ),
        ],
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey[100]);
  }
}

/// The "Fresh Day" now-playing card with transport controls + volume slider,
/// shown under Background Music on both the Workout Settings and Music
/// Settings screens.
class MusicPlayerCard extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onChangeMusic;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const MusicPlayerCard({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onChangeMusic,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: kSettingsPink.withValues(alpha: 0.12),
                  child: const Icon(Icons.self_improvement_rounded,
                      color: kSettingsPink, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fresh Day',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kSettingsDarkText)),
                    Text('Energetic Beats',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 13, color: kSettingsPink),
                        const SizedBox(width: 3),
                        Text('00:45',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kSettingsDarkText)),
                        Text(' / 02:46',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onChangeMusic,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: kSettingsPink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.library_music_rounded,
                          size: 14, color: kSettingsPink),
                      const SizedBox(width: 4),
                      Text('Change',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kSettingsPink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.skip_previous_rounded, color: Colors.grey[400], size: 26),
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: kSettingsPink, shape: BoxShape.circle),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Icon(Icons.skip_next_rounded, color: Colors.grey[400], size: 26),
              Icon(Icons.repeat_rounded, color: kSettingsPink, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.volume_up_rounded, size: 18, color: Colors.grey[500]),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: onVolumeChanged,
                    activeColor: kSettingsPink,
                    inactiveColor: Colors.grey[200],
                  ),
                ),
              ),
              Text('${(volume * 100).round()}%',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kSettingsPink)),
            ],
          ),
        ],
      ),
    );
  }
}
