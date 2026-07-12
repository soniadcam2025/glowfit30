import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'workout_detail_screen.dart';

const _pink = Color(0xFFFF136B);
const _darkText = Color(0xFF1A1A2E);

const _difficulties = ['All', 'Beginner', 'Intermediate', 'Advanced'];

Color _difficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Intermediate':
      return const Color(0xFFF2994A);
    case 'Advanced':
      return const Color(0xFFEB5757);
    default: // Beginner
      return const Color(0xFF2F80ED);
  }
}

Color _hexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var v = hex.replaceAll('#', '');
  if (v.length == 6) v = 'FF$v';
  final parsed = int.tryParse(v, radix: 16);
  return parsed != null ? Color(parsed) : fallback;
}

/// Browse screen for one workout-library category (e.g. "Abs").
/// Header content comes from the admin-managed WorkoutLibraryCategory row;
/// falls back to the static card art/colors when none is configured yet.
class WorkoutCategoryScreen extends StatefulWidget {
  final String categoryName;
  final String fallbackImage;
  final Color fallbackBackground;
  final Color fallbackTitleColor;

  const WorkoutCategoryScreen({
    super.key,
    required this.categoryName,
    required this.fallbackImage,
    required this.fallbackBackground,
    required this.fallbackTitleColor,
  });

  @override
  State<WorkoutCategoryScreen> createState() => _WorkoutCategoryScreenState();
}

class _WorkoutCategoryScreenState extends State<WorkoutCategoryScreen> {
  Map<String, dynamic>? _category;
  List<dynamic> _items = [];
  bool _loading = true;
  bool _bookmarked = false;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Get.find<ApiService>();
    final results = await Future.wait([
      api.getWorkoutLibraryCategory(widget.categoryName),
      api.getWorkoutLibraryItems(category: widget.categoryName),
    ]);
    if (!mounted) return;
    setState(() {
      _category = results[0] as Map<String, dynamic>?;
      _items = results[1] as List<dynamic>;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredItems => _items
      .cast<Map<String, dynamic>>()
      .where((i) =>
          _filter == 'All' ||
          ((i['difficulty'] as String?) ?? 'Beginner') == _filter)
      .toList();

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(itemId: item['id'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : _buildSheet(),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final heading1 = (_category?['headingLine1'] as String?) ??
        widget.categoryName.toUpperCase();
    final heading2 = (_category?['headingLine2'] as String?) ?? 'WORKOUTS';
    final description = (_category?['description'] as String?) ?? '';
    final tags = (_category?['tags'] as List?) ?? [];
    final heroImageUrl = _category?['heroImageUrl'] as String?;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.fallbackBackground.withValues(alpha: 0.55),
            widget.fallbackBackground,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: (heroImageUrl == null || heroImageUrl.isEmpty)
                  ? Image.asset(
                      widget.fallbackImage,
                      width: 190,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Image.network(
                      heroImageUrl,
                      width: 190,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      _circleButton(
                        icon: _bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _bookmarked ? _pink : _darkText,
                        onTap: () =>
                            setState(() => _bookmarked = !_bookmarked),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    heading1,
                    style: GoogleFonts.poppins(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: _pink,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    heading2,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _darkText,
                      height: 1.1,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 210,
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: _darkText.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in tags.cast<Map<String, dynamic>>())
                          _tagChip(t),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = _darkText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  Widget _tagChip(Map<String, dynamic> tag) {
    final fg = _hexColor(tag['foreground'] as String?, _pink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag['emoji'] as String? ?? '',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            tag['label'] as String? ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHEET (filters + list) ───────────────────────────────────────────────

  Widget _buildSheet() {
    final items = _filteredItems;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in _difficulties) ...[
                          _filterPill(d),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded,
                      size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _items.isEmpty
                            ? 'No workouts in this category yet.\nCheck back soon!'
                            : 'No $_filter workouts here yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 26,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (_, i) => _workoutRow(items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _pink : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _pink : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : _darkText.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  // ─── WORKOUT ROW ──────────────────────────────────────────────────────────

  Widget _workoutRow(Map<String, dynamic> item) {
    final title =
        '${item['titleLine1'] ?? ''} ${item['titleScript'] ?? ''}'.trim();
    final difficulty = (item['difficulty'] as String?) ?? 'Beginner';
    final diffColor = _difficultyColor(difficulty);
    final description = (item['description'] as String?) ?? '';
    final duration = item['durationMinutes'];
    final kcal = (item['kcalLabel'] as String?) ?? '';
    final exerciseCount = (item['_count']?['exercises'] as int?) ?? 0;
    final imageUrl = item['heroImageUrl'] as String?;

    return GestureDetector(
      onTap: () => _openDetail(item),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 96,
              height: 96,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF4E8D), Color(0xFFFF136B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.fitness_center_rounded,
                          color: Colors.white54, size: 30),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFE0EC),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: _pink, size: 30),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.circle, size: 7, color: diffColor),
                    const SizedBox(width: 4),
                    Text(
                      difficulty,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: diffColor,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text('$duration min', style: _metaStyle()),
                    const SizedBox(width: 12),
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text('$kcal kcal', style: _metaStyle()),
                    const SizedBox(width: 12),
                    const Icon(Icons.fitness_center_rounded,
                        size: 13, color: Color(0xFF2F80ED)),
                    const SizedBox(width: 3),
                    Text('$exerciseCount Exercises', style: _metaStyle()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _metaStyle() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      );
}
