import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glow_content_detail_screen.dart';
import 'glow_short_story_screen.dart';

/// Shared constants, helpers and cards for the Glow feature.
///
/// Extracted so the Glow screen, the category detail screen and the two "View
/// All" hubs render identical cards and route taps the same way, rather than
/// each keeping its own copy.

const glowPink = Color(0xFFFF136B);
const glowDarkText = Color(0xFF1A1A2E);
const glowPlaceholder = Color(0xFFFFD6E7);
const glowBorder = Color(0xFFECEEF2);

String glowTimeAgo(String? iso) {
  final dt = DateTime.tryParse(iso ?? '')?.toLocal();
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'just now';
}

int glowDurationMinutes(String? duration) {
  final parts = (duration ?? '0:00').split(':');
  final minutes = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
  final seconds = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final rounded = minutes + (seconds > 0 ? 1 : 0);
  return rounded < 1 ? 1 : rounded;
}

/// Total seconds for a "m:ss" duration string. Used to separate genuine
/// quick tips from longer shorts.
int glowDurationSeconds(String? duration) {
  final parts = (duration ?? '0:00').split(':');
  final m = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
  final s = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return m * 60 + s;
}

bool glowHasTips(Map<String, dynamic> item) {
  final sections = item['sections'];
  return sections is Map && (((sections['tips'] as List?) ?? []).isNotEmpty);
}

/// Single entry point for opening any Glow item, so every surface routes the
/// same way: a Short with authored tips gets the full-screen story player,
/// everything else gets the tabbed detail screen.
void openGlowItem(BuildContext context, Map<String, dynamic> item, {required bool isVideo}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => (isVideo && glowHasTips(item))
          ? GlowShortStoryScreen(item: item)
          : GlowContentDetailScreen(item: item, isVideo: isVideo),
    ),
  );
}

/// Sorts posts+shorts into one newest-first feed, tagging each with `_type`.
List<Map<String, dynamic>> glowMixedFeed(
  List<dynamic> posts,
  List<dynamic> shorts, {
  int take = 6,
}) {
  final items = <Map<String, dynamic>>[
    ...posts.map((p) => {...p as Map<String, dynamic>, '_type': 'post'}),
    ...shorts.map((s) => {...s as Map<String, dynamic>, '_type': 'video'}),
  ];
  items.sort((a, b) {
    final da = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(0);
    final db = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(0);
    return db.compareTo(da);
  });
  return items.take(take).toList();
}

String? glowCategoryIdOf(Map<String, dynamic> item) => item['categoryId'] as String?;

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

class GlowCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlowCircleIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: glowDarkText),
      ),
    );
  }
}

class GlowSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const GlowSectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: glowDarkText,
            ),
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: glowPink,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 16, color: glowPink),
              ],
            ),
          ),
      ],
    );
  }
}

/// Horizontal pill row used for Popular Topics / category filters.
class GlowFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final IconData? leadingIconForFirst;

  const GlowFilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.leadingIconForFirst,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Text(
        'No topics added yet.',
        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[400]),
      );
    }
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSel = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? glowPink : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSel ? glowPink : glowBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0 && leadingIconForFirst != null) ...[
                    Icon(leadingIconForFirst,
                        size: 14, color: isSel ? Colors.white : glowPink),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : Colors.grey[700],
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
}

/// Video tile used by "Top Videos" grids.
class GlowVideoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String categoryLabel;
  const GlowVideoCard({super.key, required this.item, required this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final img = item['imageUrl'] as String?;
    return GestureDetector(
      onTap: () => openGlowItem(context, item, isVideo: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (img != null && img.isNotEmpty)
                      ? Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: glowPlaceholder))
                      : Container(color: glowPlaceholder),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${item['duration'] ?? ''}',
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 34, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (categoryLabel.isNotEmpty)
            Text(categoryLabel.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w700, color: glowPink)),
          const SizedBox(height: 2),
          Text(
            '${item['title'] ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: glowDarkText,
                height: 1.25),
          ),
          const SizedBox(height: 3),
          Text(
            '${item['views'] ?? ''} • ${glowTimeAgo(item['createdAt'] as String?)}',
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Mixed post/video tile used by "Latest Posts & Videos" grids. Shows a
/// Post/Video badge so the two content types stay distinguishable.
class GlowMixedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const GlowMixedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item['_type'] == 'video';
    final img = item['imageUrl'] as String?;
    final meta = isVideo
        ? '${glowDurationMinutes(item['duration'] as String?)} min watch'
        : '${item['minutesRead'] ?? 4} min read';

    return GestureDetector(
      onTap: () => openGlowItem(context, item, isVideo: isVideo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (img != null && img.isNotEmpty)
                      ? Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: glowPlaceholder))
                      : Container(color: glowPlaceholder),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVideo ? glowPink : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVideo ? 'Video' : 'Post',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isVideo ? Colors.white : glowDarkText,
                      ),
                    ),
                  ),
                ),
                if (isVideo)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${item['duration'] ?? ''}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                if (isVideo)
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        size: 30, color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item['title'] ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: glowDarkText,
                height: 1.25),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[500]),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  meta,
                  style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
                ),
              ),
              Icon(Icons.bookmark_border_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }
}
