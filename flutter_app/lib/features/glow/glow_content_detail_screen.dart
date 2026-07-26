import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

class _SectionItem {
  final String? imageUrl;
  final String title;
  final String description;
  const _SectionItem({this.imageUrl, required this.title, required this.description});

  factory _SectionItem.fromJson(Map<String, dynamic> j) => _SectionItem(
        imageUrl: j['imageUrl'] as String?,
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
    final imageUrl = widget.item['imageUrl'] as String?;

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

  Widget _buildHero(String? imageUrl) {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFFD6E7)))
              : Container(color: const Color(0xFFFFD6E7)),
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

  Widget _buildTabsAndContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: i == _activeTab ? const Color(0xFFFFF0F6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        bottom: BorderSide(color: i == _activeTab ? _pink : Colors.transparent, width: 2),
                      ),
                    ),
                    child: Text(
                      _tabs[i].label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: i == _activeTab ? _pink : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Divider(color: Colors.grey[200], height: 24),
        _buildAccordion(_tabs[_activeTab]),
      ],
    );
  }

  Widget _buildAccordion(_Tab tab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Understand Your ${tab.label == 'Problem & Cause' ? 'Problem' : tab.label}',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _darkText),
        ),
        const SizedBox(height: 12),
        for (final item in tab.items) _buildAccordionCard(tab.key, item),
      ],
    );
  }

  Widget _buildAccordionCard(String tabKey, _SectionItem item) {
    final id = '$tabKey::${item.title}';
    final expanded = !_collapsed.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (expanded) {
                _collapsed.add(id);
              } else {
                _collapsed.remove(id);
              }
            }),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(item.imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFFFFD6E7)))
                      : Container(width: 48, height: 48, color: const Color(0xFFFFD6E7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _darkText),
                  ),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Text(
              item.description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
