import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _languages = ['English', 'Hindi', 'Bengali', 'Espanol', 'Brazil'];
const _languageStorageKey = 'app_settings_language';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _box = GetStorage();
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = _box.read<String>(_languageStorageKey) ?? 'English';
  }

  void _selectLanguage(String lang) {
    setState(() => _language = lang);
    _box.write(_languageStorageKey, lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language set to $lang.')),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Language'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.map((l) {
                        final isSelected = l == _language;
                        return GestureDetector(
                          onTap: () => _selectLanguage(l),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? _pink : const Color(0xFFF7F0F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),
                    _label('More'),
                    _settingsRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy & Terms',
                      onTap: () => _comingSoon('Privacy Policy & Terms'),
                    ),
                    _settingsRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      onTap: () => _comingSoon('Appearance'),
                      showDivider: false,
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _darkText),
          ),
          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: _pink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
          if (showDivider) Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }
}
