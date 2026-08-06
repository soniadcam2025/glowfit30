import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../models/media.dart';
import '../../widgets/glow_image.dart';
import 'glow_common.dart';

/// "View All" destination for Shorts & Quick Tips.
///
/// Section membership comes from admin-controlled flags on GlowShort
/// (`isFeatured` / `isTrending` / `isQuickTip`) rather than being derived from
/// sort order, view counts or duration — featuring a clip is an editorial
/// decision, not a side effect of how the list happens to sort.
class GlowShortsHubScreen extends StatefulWidget {
  const GlowShortsHubScreen({super.key});

  @override
  State<GlowShortsHubScreen> createState() => _GlowShortsHubScreenState();
}

class _GlowShortsHubScreenState extends State<GlowShortsHubScreen> {
  bool _loading = true;
  List<dynamic> _shorts = [];
  List<dynamic> _categories = [];
  int _selectedFilter = 0; // 0 == "All Videos"
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([
      api.getGlowShorts(),
      api.getGlowCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _shorts = results[0];
      _categories = results[1];
      _loading = false;
    });
  }

  List<String> get _filterLabels => [
        'All Videos',
        ..._categories.map((c) => (c as Map<String, dynamic>)['title'] as String? ?? ''),
      ];

  String? get _activeCategoryId {
    if (_selectedFilter == 0 || _selectedFilter > _categories.length) return null;
    return (_categories[_selectedFilter - 1] as Map<String, dynamic>)['id'] as String?;
  }

  /// Category filter + search box applied together.
  List<Map<String, dynamic>> get _visible {
    final id = _activeCategoryId;
    final q = _query.trim().toLowerCase();
    return _shorts.cast<Map<String, dynamic>>().where((s) {
      if (id != null && glowCategoryIdOf(s) != id) return false;
      if (q.isEmpty) return true;
      return ('${s['title'] ?? ''}').toLowerCase().contains(q);
    }).toList();
  }

  Map<String, dynamic>? get _featured {
    for (final s in _visible) {
      if (s['isFeatured'] == true) return s;
    }
    return null;
  }

  List<Map<String, dynamic>> get _rest {
    final f = _featured;
    return _visible.where((s) => s != f).toList();
  }

  List<Map<String, dynamic>> get _trending =>
      _visible.where((s) => s['isTrending'] == true).toList();

  List<Map<String, dynamic>> get _quickTips =>
      _visible.where((s) => s['isQuickTip'] == true).toList();

  String _categoryTitleOf(Map<String, dynamic> item) {
    final id = glowCategoryIdOf(item);
    if (id == null) return '';
    for (final c in _categories) {
      final m = c as Map<String, dynamic>;
      if (m['id'] == id) return (m['title'] as String?) ?? '';
    }
    return '';
  }

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: glowPink))
            : RefreshIndicator(
                color: glowPink,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSearchRow(),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: GlowFilterChips(
                          labels: _filterLabels,
                          selected: _selectedFilter,
                          onSelected: (i) => setState(() => _selectedFilter = i),
                          leadingIconForFirst: Icons.play_arrow_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_featured != null) ...[
                              _buildFeaturedCard(_featured!),
                              const SizedBox(height: 14),
                            ],
                            _buildShortsGrid(),
                            if (_trending.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              GlowSectionHeader(
                                title: 'Trending Now 🔥',
                                onViewAll: () => _notImplemented('Trending list'),
                              ),
                              const SizedBox(height: 10),
                              _buildHorizontalRow(_trending),
                            ],
                            if (_quickTips.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              GlowSectionHeader(
                                title: 'Quick Tips ⚡',
                                onViewAll: () => _notImplemented('Quick Tips list'),
                              ),
                              const SizedBox(height: 10),
                              _buildQuickTipsRow(),
                            ],
                            if (_visible.isEmpty) _buildEmptyState(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: glowBorder),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  size: 26, color: glowDarkText),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Shorts & Quick Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: glowDarkText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Short videos, quick results',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 4),
                    const Text('🌸', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: glowBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 19, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.poppins(fontSize: 12.5, color: glowDarkText),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search skincare, haircare, tips, routines …',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(Icons.close_rounded,
                        size: 17, color: Colors.grey[500]),
                  )
                else
                  Icon(Icons.mic_none_rounded, size: 18, color: glowPink),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _notImplemented('Filters'),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: glowPink, shape: BoxShape.circle),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ─── FEATURED ──────────────────────────────────────────────────────────────

  Widget _buildFeaturedCard(Map<String, dynamic> s) {
    final img = MediaImage.read(s);
    return GestureDetector(
      onTap: () => openGlowItem(context, s, isVideo: true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1.35,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GlowImage(media: img, error: Container(color: glowPlaceholder)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: glowPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Featured',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 100,
                top: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s['title'] ?? ''}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: glowDarkText,
                        height: 1.2,
                      ),
                    ),
                    if ((s['content'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        s['content'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                          color: glowPink, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text('${s['views'] ?? ''}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[700])),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${s['duration'] ?? ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GRID / ROWS ───────────────────────────────────────────────────────────

  Widget _buildShortsGrid() {
    final items = _rest;
    if (items.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) => GlowVideoCard(
        item: items[i],
        categoryLabel: _categoryTitleOf(items[i]),
      ),
    );
  }

  Widget _buildHorizontalRow(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = items[i];
          final img = MediaImage.read(s);
          return GestureDetector(
            onTap: () => openGlowItem(context, s, isVideo: true),
            child: SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GlowImage(
                        media: img, error: Container(color: glowPlaceholder)),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${s['duration'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white)),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s['title'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.25),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  size: 11, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text('${s['views'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 9.5, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          size: 30, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickTipsRow() {
    final items = _quickTips;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = items[i];
          final img = MediaImage.read(s);
          return GestureDetector(
            onTap: () => openGlowItem(context, s, isVideo: true),
            child: SizedBox(
              width: 128,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GlowImage(
                        media: img, error: Container(color: glowPlaceholder)),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: Text('⚡', style: TextStyle(fontSize: 15)),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 22,
                      child: Text(
                        '${s['title'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 6,
                      child: Text('${s['duration'] ?? ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          _query.isNotEmpty
              ? 'No shorts match "$_query".'
              : 'No shorts in this category yet.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[500]),
        ),
      ),
    );
  }
}
