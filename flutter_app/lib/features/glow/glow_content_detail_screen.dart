import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/media.dart';
import '../../widgets/glow_image.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class _SectionItem {
  final MediaImage? imageUrl;
  final String title;
  final String description;
  const _SectionItem({this.imageUrl, required this.title, required this.description});

  factory _SectionItem.fromJson(Map<String, dynamic> j) => _SectionItem(
        imageUrl: MediaImage.read(j),
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
      );
}

class _Tab {
  final String key;
  final String label;
  final List<_SectionItem> items;
  const _Tab({required this.key, required this.label, required this.items});
}

/// Detail screen for a single Glow Read (article) or Short (video), driven entirely
/// by the API item passed in. Works for both content types — `isVideo` controls
/// whether the hero shows a play button/duration badge.
class GlowContentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isVideo;

  const GlowContentDetailScreen({super.key, required this.item, required this.isVideo});

  @override
  State<GlowContentDetailScreen> createState() => _GlowContentDetailScreenState();
}

class _GlowContentDetailScreenState extends State<GlowContentDetailScreen> {
  late List<_Tab> _tabs;
  int _activeTab = 0;
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _tabs = _parseTabs(widget.item['sections']);
  }

  List<_Tab> _parseTabs(dynamic sections) {
    if (sections is! Map) return [];
    const defs = [
      ('problemCause', 'Problem & Cause'),
      ('solution', 'Solution'),
      ('tips', 'Tips'),
    ];
    final tabs = <_Tab>[];
    for (final (key, label) in defs) {
      final raw = (sections[key] as List?) ?? [];
      if (raw.isEmpty) continue;
      tabs.add(_Tab(
        key: key,
        label: label,
        items: raw.map((e) => _SectionItem.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    }
    return tabs;
  }

  bool get _isPremium => (widget.item['isPremium'] as bool?) ?? false;
  String? get _resultBadge => widget.item['resultBadge'] as String?;
  List<Map<String, dynamic>> get _chips =>
      ((widget.item['chips'] as List?) ?? []).cast<Map<String, dynamic>>();
  String get _plainContent => (widget.item['content'] as String?) ?? '';

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] as String?) ?? '';
    final imageUrl = MediaImage.read(widget.item);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(imageUrl),
            if (_isPremium) _buildPremiumRow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: _darkText),
                  ),
                  if (_resultBadge != null && _resultBadge!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '($_resultBadge) ✨',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _pink),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in _chips)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F0F5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${c['emoji'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${c['label'] ?? ''}',
                                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _notImplemented('Share'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: const Color(0xFFF7F0F5), shape: BoxShape.circle),
                          child: const Icon(Icons.share_rounded, size: 16, color: _darkText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_tabs.isNotEmpty) _buildTabsAndContent() else _buildPlainContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero(MediaImage? imageUrl) {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GlowImage(
            media: imageUrl,
            error: Container(color: const Color(0xFFFFD6E7)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.maybePop(context)),
                    if (_isPremium) _premiumBadge(),
                    _circleIconButton(Icons.bookmark_border_rounded, () => _notImplemented('Save')),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isVideo)
            Center(
              child: GestureDetector(
                onTap: () => _notImplemented('Play video'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, size: 32, color: _pink),
                ),
              ),
            ),
          if (widget.isVideo)
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${widget.item['duration'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _premiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            widget.isVideo ? 'PREMIUM VIDEO' : 'PREMIUM',
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: _darkText),
      ),
    );
  }

  Widget _buildPremiumRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _notImplemented('Watch Ad'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_display_outlined, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text('Watch Ad',
                        style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _notImplemented('Go Premium'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF4E8D), _pink]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Go Premium',
                        style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PLAIN CONTENT (no sections authored) ──────────────────────────────────

  Widget _buildPlainContent() {
    final text = _plainContent;
    if (text.isEmpty) {
      return Text('No content yet.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]));
    }
    return Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.6));
  }

  // ─── TABS + ACCORDION ───────────────────────────────────────────────────────

  static const _tabIcons = <String, IconData>{
    'problemCause': Icons.error_outline_rounded,
    'solution': Icons.emoji_food_beverage_outlined,
    'tips': Icons.lightbulb_outline_rounded,
  };

  static const _tabHeadings = <String, String>{
    'problemCause': 'Understand Your Problem',
    'solution': 'Your Solution',
    'tips': 'Quick Tips',
  };

  // Intro copy is not an authorable field on BeautyPost/GlowShort, so these are
  // generic per tab rather than per post — worded to stay true for any topic.
  static const _tabIntros = <String, String>{
    'problemCause':
        'Learn the main causes and how to identify your condition.',
    'solution': 'Follow these steps to treat and prevent the problem.',
    'tips': 'Small daily habits that make a visible difference.',
  };

  Widget _buildTabsAndContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabBar(),
        const SizedBox(height: 18),
        _buildAccordion(_tabs[_activeTab]),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      // clipped so the active tab's underline follows the rounded corners
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == _activeTab ? _pink : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabIcons[_tabs[i].key] ?? Icons.circle_outlined,
                        size: 15,
                        color: i == _activeTab ? _pink : Colors.grey[400],
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _tabs[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: i == _activeTab ? _pink : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccordion(_Tab tab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tabHeadings[tab.key] ?? tab.label,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tabIntros[tab.key] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        for (final item in tab.items) _buildAccordionCard(tab.key, item),
      ],
    );
  }

  Widget _buildAccordionCard(String tabKey, _SectionItem item) {
    final id = '$tabKey::${item.title}';
    final expanded = !_collapsed.contains(id);
    final hasImage = item.imageUrl != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF2)),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (expanded) {
            _collapsed.add(id);
          } else {
            _collapsed.remove(id);
          }
        }),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              GlowImage(
                media: item.imageUrl,
                width: 96,
                height: 96,
                borderRadius: BorderRadius.circular(12),
                error: Container(
                  width: 96,
                  height: 96,
                  color: const Color(0xFFFFD6E7),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkText,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 6),
                    _buildDescription(item.description),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the description as a bulleted list when the author wrote one
  /// (lines starting with "-", "*" or "•"), otherwise as a plain paragraph.
  Widget _buildDescription(String text) {
    final style = GoogleFonts.poppins(
      fontSize: 12.5,
      color: Colors.grey[600],
      height: 1.55,
    );

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final bulletRe = RegExp(r'^[-*•]\s*');
    final isList = lines.length > 1 && lines.every((l) => bulletRe.hasMatch(l));

    if (!isList) return Text(text, style: style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(line.replaceFirst(bulletRe, ''), style: style),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
