import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/media_downloader.dart';
import '../../services/media_preloader.dart';
import 'legal_content_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _languages = ['English', 'Hindi', 'Bengali', 'Espanol', 'Brazil'];
const _appearances = ['Light', 'Dark', 'System'];

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  String _language = _languages.first;
  String _appearance = _appearances.last;

  /// Local, not part of the profile: it describes this device's connection and
  /// data plan, which has nothing to do with the account. Syncing it would mean
  /// a choice made on someone's home tablet silently applying to their phone.
  bool _preloadOnCellular = MediaPreloader.instance.allowOnCellular;

  void _setPreloadOnCellular(bool value) {
    setState(() => _preloadOnCellular = value);
    MediaPreloader.instance.allowOnCellular = value;
  }

  /// Offline downloads are the one thing in this app that takes real space on
  /// someone's phone, so the amount is stated plainly and removing it is one
  /// tap away. A storage figure a user cannot find or clear is how an app ends
  /// up uninstalled.
  Widget _downloadsSection() {
    final downloader = MediaDownloader.instance;
    final used = downloader.usedBytes;
    final budget = downloader.budgetBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Offline downloads'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${MediaDownloader.formatBytes(used)} used'
                    '${downloader.fileCount > 0 ? ' · ${downloader.fileCount} files' : ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Limit ${MediaDownloader.formatBytes(budget)}. Downloads older '
                    'than 30 days are removed automatically, and the least used '
                    'go first when the limit is reached.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: used == 0 ? null : _clearDownloads,
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: used == 0 ? Colors.grey[400] : _pink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: budget == 0 ? 0 : (used / budget).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF7F0F5),
            valueColor: const AlwaysStoppedAnimation(_pink),
          ),
        ),
      ],
    );
  }

  Future<void> _clearDownloads() async {
    await MediaDownloader.instance.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloaded media removed.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await Get.find<ApiService>().getProfile();
    if (!mounted) return;
    setState(() {
      final lang = profile?['language'] as String?;
      if (lang != null && _languages.contains(lang)) _language = lang;
      final appearance = profile?['appearance'] as String?;
      if (appearance != null && _appearances.contains(appearance)) {
        _appearance = appearance;
      }
      _loading = false;
    });
  }

  Future<void> _selectLanguage(String lang) async {
    final previous = _language;
    setState(() {
      _language = lang;
      _saving = true;
    });
    final result =
        await Get.find<ApiService>().patchProfile({'language': lang});
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language set to $lang.')),
      );
    } else {
      setState(() => _language = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update. Try again.')),
      );
    }
  }

  Future<void> _selectAppearance(String appearance) async {
    final previous = _appearance;
    setState(() {
      _appearance = appearance;
      _saving = true;
    });
    final result = await Get.find<ApiService>()
        .patchProfile({'appearance': appearance});
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appearance set to $appearance.')),
      );
    } else {
      setState(() => _appearance = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update. Try again.')),
      );
    }
  }

  Widget _pillSelector(
      List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: _saving ? null : () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _pink : const Color(0xFFF7F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Language'),
                          _pillSelector(_languages, _language, _selectLanguage),
                          const SizedBox(height: 26),
                          _label('Appearance'),
                          _pillSelector(
                              _appearances, _appearance, _selectAppearance),
                          const SizedBox(height: 6),
                          Text(
                            'Saved to your account. Full dark-mode theming across the app is a separate upcoming update.',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 26),
                          _label('Data usage'),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeColor: _pink,
                            value: _preloadOnCellular,
                            onChanged: _setPreloadOnCellular,
                            title: Text(
                              'Preload on mobile data',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _darkText),
                            ),
                            subtitle: Text(
                              'The next exercises are downloaded ahead of time so they '
                              'appear instantly. On by default over Wi-Fi only — turn '
                              'this on to do it over mobile data too.',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ),
                          const SizedBox(height: 26),
                          _downloadsSection(),
                          const SizedBox(height: 26),
                          _label('More'),
                          _settingsRow(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy & Terms',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LegalContentScreen()),
                            ),
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
