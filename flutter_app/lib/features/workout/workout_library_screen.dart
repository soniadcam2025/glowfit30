import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_pages.dart';
import '../../services/api_service.dart';
import '../../widgets/glow_image.dart';
import 'workout_category_screen.dart';
import 'workout_detail_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

Color _hexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var v = hex.replaceAll('#', '');
  if (v.length == 6) v = 'FF$v';
  final parsed = int.tryParse(v, radix: 16);
  return parsed != null ? Color(parsed) : fallback;
}

class _LibraryCategory {
  final String title;
  final String description;
  final String image;
  final Color background;
  final Color titleColor;

  const _LibraryCategory({
    required this.title,
    required this.description,
    required this.image,
    required this.background,
    required this.titleColor,
  });
}

class _LibrarySection {
  final String title;
  final List<_LibraryCategory> categories;
  const _LibrarySection({required this.title, required this.categories});
}

/// Local illustration used as an image fallback for admin-managed categories
/// that match one of the app's original built-in category names and haven't
/// had a card image uploaded yet.
const _defaultCategoryAssets = {
  'Full Body': 'assets/images/workout_cat_full_body.png',
  'Abs': 'assets/images/workout_cat_abs.png',
  'Arms': 'assets/images/workout_cat_arms.png',
  'Bodyweight Workouts': 'assets/images/workout_cat_bodyweight.png',
  'Bed Workouts': 'assets/images/workout_cat_bed.png',
  'Stretching': 'assets/images/workout_cat_stretching.png',
  'Recovery': 'assets/images/workout_cat_recovery.png',
  'PCOS Friendly': 'assets/images/workout_cat_pcos.png',
  'Postpartum Recovery': 'assets/images/workout_cat_postpartum.png',
  'Knee Friendly': 'assets/images/workout_cat_knee.png',
};

/// Static fallback shown only when the admin hasn't created any workout
/// library categories yet — kept so the screen never looks broken/empty.
const _sections = [
  _LibrarySection(title: 'Body Goals', categories: [
    _LibraryCategory(
      title: 'Full Body',
      description: 'One Workout.\nFull Impact.',
      image: 'assets/images/workout_cat_full_body.png',
      background: Color(0xFFEAE3FA),
      titleColor: Color(0xFF3D2E7C),
    ),
    _LibraryCategory(
      title: 'Abs',
      description: 'Strong Core.\nBetter You.',
      image: 'assets/images/workout_cat_abs.png',
      background: Color(0xFFFBE1EC),
      titleColor: Color(0xFF7C1F44),
    ),
    _LibraryCategory(
      title: 'Arms',
      description: 'Sculpted Arms.\nReal Strength.',
      image: 'assets/images/workout_cat_arms.png',
      background: Color(0xFFDCEAFB),
      titleColor: Color(0xFF1F4C7C),
    ),
  ]),
  _LibrarySection(title: 'Body Weight Workouts', categories: [
    _LibraryCategory(
      title: 'Bodyweight Workouts',
      description: 'No Equipment.\nJust You.',
      image: 'assets/images/workout_cat_bodyweight.png',
      background: Color(0xFFFBE7DA),
      titleColor: Color(0xFF8A4A22),
    ),
    _LibraryCategory(
      title: 'Bed Workouts',
      description: 'Move Before\nYou Rise.',
      image: 'assets/images/workout_cat_bed.png',
      background: Color(0xFFF3DEE6),
      titleColor: Color(0xFF7C2E4C),
    ),
  ]),
  _LibrarySection(title: 'Recovery & Relax', categories: [
    _LibraryCategory(
      title: 'Stretching',
      description: 'Move Freely.\nFeel Better.',
      image: 'assets/images/workout_cat_stretching.png',
      background: Color(0xFFE1F3E5),
      titleColor: Color(0xFF1E8A3C),
    ),
    _LibraryCategory(
      title: 'Recovery',
      description: 'Recover.\nRecharge. Repeat.',
      image: 'assets/images/workout_cat_recovery.png',
      background: Color(0xFFDCEEF3),
      titleColor: Color(0xFF1F6C8A),
    ),
  ]),
  _LibrarySection(title: 'Special Care', categories: [
    _LibraryCategory(
      title: 'PCOS Friendly',
      description: 'Fitness Designed\nFor PCOS.',
      image: 'assets/images/workout_cat_pcos.png',
      background: Color(0xFFFBE1EC),
      titleColor: _pink,
    ),
    _LibraryCategory(
      title: 'Postpartum Recovery',
      description: 'Fitness Designed\nFor Postpartum.',
      image: 'assets/images/workout_cat_postpartum.png',
      background: Color(0xFFF0E2E6),
      titleColor: Color(0xFF5C2A3A),
    ),
    _LibraryCategory(
      title: 'Knee Friendly',
      description: 'Fitness Designed\nFor Knee Care.',
      image: 'assets/images/workout_cat_knee.png',
      background: Color(0xFFE3E9FB),
      titleColor: Color(0xFF2E3E7C),
    ),
  ]),
];

class WorkoutLibraryScreen extends StatefulWidget {
  const WorkoutLibraryScreen({super.key});

  @override
  State<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends State<WorkoutLibraryScreen> {
  bool _bookmarked = false;
  List<dynamic> _libraryItems = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([
      api.getWorkoutLibraryItems(featured: true),
      api.getWorkoutLibraryCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _libraryItems = results[0];
      _categories = results[1];
    });
  }

  Map<String, dynamic>? get _featured =>
      _libraryItems.isNotEmpty ? _libraryItems.first as Map<String, dynamic> : null;

  /// Groups admin-managed categories by their `section` field, preserving
  /// the order categories were first seen in (categories already arrive
  /// sorted by the admin's `order` field).
  List<MapEntry<String, List<dynamic>>> get _groupedSections {
    final map = <String, List<dynamic>>{};
    for (final cat in _categories) {
      final section = ((cat as Map)['section'] as String?) ?? 'Body Goals';
      map.putIfAbsent(section, () => []).add(cat);
    }
    return map.entries.toList();
  }

  void _openCategoryByName(
    String name, {
    required String fallbackImage,
    required Color fallbackBackground,
    required Color fallbackTitleColor,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCategoryScreen(
          categoryName: name,
          fallbackImage: fallbackImage,
          fallbackBackground: fallbackBackground,
          fallbackTitleColor: fallbackTitleColor,
        ),
      ),
    );
  }

  void _openFeaturedWorkout() {
    final featured = _featured;
    if (featured == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No featured workout configured yet.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(itemId: featured['id'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 18),
              _buildHeroCard(),
              if (_categories.isNotEmpty)
                for (final section in _groupedSections) ...[
                  const SizedBox(height: 26),
                  _buildSectionHeader(section.key),
                  const SizedBox(height: 12),
                  _buildDynamicCategoryRow(section.value),
                ]
              else
                for (final section in _sections) ...[
                  const SizedBox(height: 26),
                  _buildSectionHeader(section.title),
                  const SizedBox(height: 12),
                  _buildCategoryRow(section.categories),
                ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Workout ',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _darkText,
                ),
              ),
              TextSpan(
                text: 'Library',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _pink,
                ),
              ),
            ]),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _bookmarked = !_bookmarked),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 20,
              color: _bookmarked ? _pink : _darkText,
            ),
          ),
        ),
      ],
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: GoogleFonts.poppins(fontSize: 14, color: _darkText),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Search workouts, programs ...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          Icon(Icons.mic_none_rounded, color: _pink, size: 22),
        ],
      ),
    );
  }

  // ─── HERO CARD ────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    final featured = _featured;
    final heroImageUrl = featured?['heroImageUrl'] as String?;
    final titleLine1 = (featured?['titleLine1'] as String?) ?? 'BELLY FAT';
    final titleScript = (featured?['titleScript'] as String?) ?? 'Blast';
    final description = (featured?['description'] as String?) ??
        'Strong core. Confident you.';
    final durationMinutes = featured?['durationMinutes'];
    final tags = (featured?['tags'] as List?) ?? [];
    final firstTag = tags.isNotEmpty ? tags.first as Map<String, dynamic> : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 288,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            (heroImageUrl == null || heroImageUrl.isEmpty)
                ? Image.asset(
                    'assets/images/workout_library_hero.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroFallbackBg(),
                  )
                : GlowImage(url: heroImageUrl, error: _heroFallbackBg()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RECOMMENDED FOR YOU',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titleLine1.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: _darkText,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    titleScript,
                    style: GoogleFonts.dancingScript(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: _pink,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (durationMinutes != null) ...[
                        Icon(Icons.access_time_rounded,
                            size: 15, color: _darkText.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text('$durationMinutes min',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: _darkText)),
                      ],
                      if (firstTag != null) ...[
                        const SizedBox(width: 14),
                        Text(firstTag['emoji'] as String? ?? '🔥',
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(firstTag['label'] as String? ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: _darkText)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: _darkText),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _openFeaturedWorkout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: _pink,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _pink.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Workout',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0EC), Color(0xFFFFC1DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.self_improvement_rounded,
            size: 70, color: _pink.withValues(alpha: 0.4)),
      ),
    );
  }

  // ─── SECTIONS ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _darkText,
      ),
    );
  }

  Widget _buildCategoryRow(List<_LibraryCategory> categories) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildCategoryCard(categories[i]),
      ),
    );
  }

  Widget _buildCategoryCard(_LibraryCategory c) {
    return _buildCategoryCardRaw(
      title: c.title,
      tagline: c.description,
      background: c.background,
      titleColor: c.titleColor,
      image: Image.asset(
        c.image,
        width: 130,
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
      onTap: () => _openCategoryByName(
        c.title,
        fallbackImage: c.image,
        fallbackBackground: c.background,
        fallbackTitleColor: c.titleColor,
      ),
    );
  }

  Widget _buildDynamicCategoryRow(List<dynamic> categories) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            _buildDynamicCategoryCard(categories[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildDynamicCategoryCard(Map<String, dynamic> cat) {
    final name = cat['name'] as String? ?? '';
    final tagline = (cat['cardTagline'] as String?)?.trim();
    final background =
        _hexColor(cat['cardBackground'] as String?, const Color(0xFFEAE3FA));
    final titleColor =
        _hexColor(cat['cardTitleColor'] as String?, const Color(0xFF3D2E7C));
    final cardImageUrl = cat['cardImageUrl'] as String?;
    final defaultAsset = _defaultCategoryAssets[name];

    Widget fallbackImage() => defaultAsset != null
        ? Image.asset(
            defaultAsset,
            width: 130,
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        : const SizedBox.shrink();

    return _buildCategoryCardRaw(
      title: name,
      tagline: (tagline == null || tagline.isEmpty)
          ? (cat['description'] as String? ?? '')
          : tagline,
      background: background,
      titleColor: titleColor,
      image: GlowImage(
        url: cardImageUrl,
        width: 130,
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        error: fallbackImage(),
      ),
      onTap: () => _openCategoryByName(
        name,
        fallbackImage: defaultAsset ?? 'assets/images/workout_cat_full_body.png',
        fallbackBackground: background,
        fallbackTitleColor: titleColor,
      ),
    );
  }

  Widget _buildCategoryCardRaw({
    required String title,
    required String tagline,
    required Color background,
    required Color titleColor,
    required Widget image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(right: -10, bottom: 0, child: image),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: titleColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tagline,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: titleColor.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      (svg: 'assets/icons/nav_home.svg', png: null, label: 'Home'),
      (svg: 'assets/icons/nav_workout.svg', png: null, label: 'Workout'),
      (svg: 'assets/icons/nav_diet.svg', png: null, label: 'Diet'),
      (svg: 'assets/icons/nav_progress.svg', png: null, label: 'Progress'),
      (
        svg: null,
        png: 'assets/icons/glowfit_ico_selected.png',
        label: 'GlowFit'
      ),
    ];
    const workoutIndex = 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == workoutIndex;
              final color = selected ? _pink : Colors.grey[500]!;
              return GestureDetector(
                onTap: () {
                  if (i == workoutIndex) return;
                  switch (i) {
                    case 0:
                      Get.offAllNamed(Routes.home);
                      break;
                    case 2:
                      Get.offAllNamed(Routes.diet);
                      break;
                    case 3:
                      Get.offAllNamed(Routes.progress);
                      break;
                    case 4:
                      Get.offAllNamed(Routes.glow);
                      break;
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.svg != null)
                      SvgPicture.asset(
                        item.svg!,
                        width: 26,
                        height: 26,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    else
                      Image.asset(
                        item.png!,
                        width: 26,
                        height: 26,
                        color: color,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.auto_awesome_rounded,
                          size: 26,
                          color: color,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
