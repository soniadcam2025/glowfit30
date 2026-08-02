import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import 'glow_common.dart';

/// "View All" destination for Glow Reads.
///
/// Same visual language as the category detail screen, but scoped to *all*
/// content rather than one category — the Popular Topics row doubles as a
/// category filter, with "All" first.
class GlowReadsHubScreen extends StatefulWidget {
  const GlowReadsHubScreen({super.key});

  @override
  State<GlowReadsHubScreen> createState() => _GlowReadsHubScreenState();
}

class _GlowReadsHubScreenState extends State<GlowReadsHubScreen> {
  bool _loading = true;
  List<dynamic> _posts = [];
  List<dynamic> _shorts = [];
  List<dynamic> _categories = [];
  int _selectedTopic = 0; // 0 == "All"

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([
      api.getGlowReads(),
      api.getGlowShorts(),
      api.getGlowCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _posts = results[0];
      _shorts = results[1];
      _categories = results[2];
      _loading = false;
    });
  }

  List<String> get _topicLabels => [
        'All',
        ..._categories.map((c) => (c as Map<String, dynamic>)['title'] as String? ?? ''),
      ];

  String? get _activeCategoryId {
    if (_selectedTopic == 0 || _selectedTopic > _categories.length) return null;
    return (_categories[_selectedTopic - 1] as Map<String, dynamic>)['id'] as String?;
  }

  List<dynamic> _filter(List<dynamic> src) {
    final id = _activeCategoryId;
    if (id == null) return src;
    return src
        .where((e) => glowCategoryIdOf(e as Map<String, dynamic>) == id)
        .toList();
  }

  List<dynamic> get _filteredPosts => _filter(_posts);
  List<dynamic> get _filteredShorts => _filter(_shorts);

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
      body: _loading
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
                    _buildHero(),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatsCard(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Topics',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: glowDarkText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlowFilterChips(
                            labels: _topicLabels,
                            selected: _selectedTopic,
                            onSelected: (i) => setState(() => _selectedTopic = i),
                          ),
                          const SizedBox(height: 22),
                          GlowSectionHeader(
                            title: 'Top Videos',
                            onViewAll: () => _notImplemented('Top Videos list'),
                          ),
                          const SizedBox(height: 10),
                          _buildVideosGrid(),
                          const SizedBox(height: 22),
                          const GlowSectionHeader(title: 'Latest Posts & Videos'),
                          const SizedBox(height: 10),
                          _buildLatestGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── HERO ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    // No dedicated hero asset exists for "all reads", so the newest post's
    // image stands in — falling back to the brand gradient.
    String? heroImage;
    for (final p in _posts) {
      final url = (p as Map<String, dynamic>)['imageUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        heroImage = url;
        break;
      }
    }

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (heroImage != null)
            Image.network(heroImage, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _heroFallback())
          else
            _heroFallback(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.75],
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
                    GlowCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    GlowCircleIconButton(
                      icon: Icons.bookmark_border_rounded,
                      onTap: () => _notImplemented('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glow Reads',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: glowPink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Everything you need to know for healthy, glowing and beautiful skin',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Text('📖', style: TextStyle(fontSize: 64))),
    );
  }

  // ─── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.play_circle_fill_rounded, glowPink,
              '${_filteredShorts.length}', 'Videos'),
          _statItem(Icons.description_rounded, const Color(0xFF22C55E),
              '${_filteredPosts.length}', 'Posts'),
          GestureDetector(
            onTap: () => _notImplemented('Search'),
            child: _statItem(Icons.search_rounded, glowPink, null, 'Search'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String? value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: value != null
              ? Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: glowDarkText))
              : null,
        ),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500])),
      ],
    );
  }

  // ─── GRIDS ─────────────────────────────────────────────────────────────────

  Widget _buildVideosGrid() {
    final items = _filteredShorts.take(4).toList();
    if (items.isEmpty) return _emptyNote('No videos here yet.');
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
      itemBuilder: (_, i) {
        final s = items[i] as Map<String, dynamic>;
        return GlowVideoCard(item: s, categoryLabel: _categoryTitleOf(s));
      },
    );
  }

  Widget _buildLatestGrid() {
    final items = glowMixedFeed(_filteredPosts, _filteredShorts);
    if (items.isEmpty) return _emptyNote('No content here yet.');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) => GlowMixedCard(item: items[i]),
    );
  }

  Widget _emptyNote(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[400])),
      );
}
