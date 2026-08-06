import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/media.dart';
import '../../widgets/glow_image.dart';
import 'glow_content_detail_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

String _timeAgo(String? iso) {
  final dt = DateTime.tryParse(iso ?? '')?.toLocal();
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'just now';
}

int _durationMinutes(String? duration) {
  final parts = (duration ?? '0:00').split(':');
  final minutes = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
  final seconds = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final rounded = minutes + (seconds > 0 ? 1 : 0);
  return rounded < 1 ? 1 : rounded;
}

class GlowCategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String fallbackTitle;
  final String fallbackSubtitle;
  final String fallbackEmoji;
  final Color fallbackBackground;

  const GlowCategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.fallbackTitle,
    required this.fallbackSubtitle,
    required this.fallbackEmoji,
    required this.fallbackBackground,
  });

  @override
  State<GlowCategoryDetailScreen> createState() => _GlowCategoryDetailScreenState();
}

class _GlowCategoryDetailScreenState extends State<GlowCategoryDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _category;
  List<dynamic> _shorts = [];
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([
      api.getGlowCategoryDetail(widget.categoryId),
      api.getGlowShorts(categoryId: widget.categoryId),
      api.getGlowReads(categoryId: widget.categoryId),
    ]);
    if (!mounted) return;
    setState(() {
      _category = results[0] as Map<String, dynamic>?;
      _shorts = results[1] as List<dynamic>;
      _posts = results[2] as List<dynamic>;
      _loading = false;
    });
  }

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  String get _title => (_category?['title'] as String?) ?? widget.fallbackTitle;
  String get _subtitle => (_category?['subtitle'] as String?) ?? widget.fallbackSubtitle;
  MediaImage? get _heroImage =>
      MediaImage.read(_category, object: 'heroImage', url: 'heroImageUrl');
  int get _videosCount => (_category?['shortsCount'] as num?)?.toInt() ?? _shorts.length;
  int get _postsCount => (_category?['postsCount'] as num?)?.toInt() ?? _posts.length;
  List<Map<String, dynamic>> get _topics =>
      ((_category?['topics'] as List?) ?? []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _latestMixed {
    final items = <Map<String, dynamic>>[
      ..._posts.map((p) => {...p as Map<String, dynamic>, '_type': 'post'}),
      ..._shorts.map((s) => {...s as Map<String, dynamic>, '_type': 'video'}),
    ];
    items.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    return items.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
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
                        _sectionTitle('Popular Topics'),
                        const SizedBox(height: 10),
                        _buildTopics(),
                        const SizedBox(height: 22),
                        _buildSectionHeader('Top Videos'),
                        const SizedBox(height: 10),
                        _buildVideosGrid(),
                        const SizedBox(height: 22),
                        _buildSectionHeader('Latest Posts & Videos'),
                        const SizedBox(height: 10),
                        _buildLatestGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GlowImage(media: _heroImage, error: _heroFallback()),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.7],
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
                    _circleIconButton(Icons.bookmark_border_rounded, () => _notImplemented('Save')),
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
                  _title,
                  style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800, color: _pink),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white, height: 1.3),
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
      color: widget.fallbackBackground,
      child: Center(
        child: Text(widget.fallbackEmoji, style: const TextStyle(fontSize: 64)),
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

  // ─── STATS CARD ─────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.play_circle_fill_rounded, _pink, '$_videosCount', 'Videos'),
          _statItem(Icons.description_rounded, const Color(0xFF22C55E), '$_postsCount', 'Posts'),
          GestureDetector(
            onTap: () => _notImplemented('Search'),
            child: _statItem(Icons.search_rounded, _pink, null, 'Search'),
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
              ? Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: _darkText))
              : null,
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500])),
      ],
    );
  }

  // ─── POPULAR TOPICS ─────────────────────────────────────────────────────────

  Widget _buildTopics() {
    if (_topics.isEmpty) {
      return Text('No topics added yet.', style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[400]));
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _topics[i];
          final selected = i == 0;
          return GestureDetector(
            onTap: () => _notImplemented('Topic filtering'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _pink : const Color(0xFFF7F0F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${t['emoji'] ?? ''}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    '${t['label'] ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── SECTION HEADER ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _darkText),
      );

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle(title),
        GestureDetector(
          onTap: () => _notImplemented('View All'),
          child: Row(
            children: [
              Text('View All', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _pink)),
              Icon(Icons.chevron_right_rounded, size: 16, color: _pink),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TOP VIDEOS ─────────────────────────────────────────────────────────────

  Widget _buildVideosGrid() {
    if (_shorts.isEmpty) {
      return Text('No videos in this category yet.', style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[400]));
    }
    final items = _shorts.take(4).toList();
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
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GlowContentDetailScreen(item: s, isVideo: true)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GlowImage(
                      media: MediaImage.read(s),
                      borderRadius: BorderRadius.circular(16),
                      error: Container(color: const Color(0xFFFFD6E7)),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                        child: Text('${s['duration'] ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded, size: 34, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(_title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _pink)),
              const SizedBox(height: 2),
              Text(
                '${s['title'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _darkText, height: 1.25),
              ),
              const SizedBox(height: 3),
              Text(
                '${s['views'] ?? ''} • ${_timeAgo(s['createdAt'] as String?)}',
                style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── LATEST POSTS & VIDEOS ──────────────────────────────────────────────────

  Widget _buildLatestGrid() {
    final items = _latestMixed;
    if (items.isEmpty) {
      return Text('No content in this category yet.', style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[400]));
    }
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
      itemBuilder: (_, i) {
        final item = items[i];
        final isVideo = item['_type'] == 'video';
        final metaText = isVideo
            ? '${_durationMinutes(item['duration'] as String?)} min watch'
            : '${item['minutesRead'] ?? 4} min read';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GlowContentDetailScreen(item: item, isVideo: isVideo)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GlowImage(
                      media: MediaImage.read(item),
                      borderRadius: BorderRadius.circular(16),
                      error: Container(color: const Color(0xFFFFD6E7)),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          isVideo ? '${item['duration'] ?? ''}' : 'Post',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    if (isVideo)
                      const Center(child: Icon(Icons.play_circle_fill_rounded, size: 28, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item['title'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _darkText, height: 1.25),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(metaText, style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
