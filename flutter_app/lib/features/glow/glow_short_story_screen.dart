import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../models/media.dart';
import '../../services/media_preloader.dart';
import '../../widgets/glow_image.dart';

import 'glow_content_detail_screen.dart';

const _pink = Color(0xFFFF136B);

/// One tip inside a Short. Mirrors the `sections.tips[]` shape already authored
/// in the admin panel (`{imageUrl, title, description}`), so no schema change
/// was needed to drive this screen.
class _Tip {
  final MediaImage? imageUrl;
  final String? videoUrl;

  /// Poster and dimensions for [videoUrl], when the API sent the object.
  final MediaVideo? video;
  final String title;
  final String description;
  const _Tip({
    this.imageUrl,
    this.videoUrl,
    this.video,
    required this.title,
    required this.description,
  });

  bool get hasVideo => (videoUrl ?? '').isNotEmpty;

  factory _Tip.fromJson(Map<String, dynamic> j) => _Tip(
        imageUrl: MediaImage.read(j),
        videoUrl: j['videoUrl'] as String?,
        video: MediaVideo.read(j),
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
      );
}

/// Full-screen, story-style viewer for a Glow Short.
///
/// Note on the scrubber: `GlowShort` carries a `duration` string and a still
/// image but no video URL, so there is nothing to actually play. The progress
/// bar is therefore a timed story pager — it advances through the authored tips
/// over the stated duration. If a real `videoUrl` is added later, swap
/// [_controller] for a VideoPlayerController and the layout stays as-is.
class GlowShortStoryScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const GlowShortStoryScreen({super.key, required this.item});

  @override
  State<GlowShortStoryScreen> createState() => _GlowShortStoryScreenState();
}

class _GlowShortStoryScreenState extends State<GlowShortStoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Tip> _tips;
  late final Duration _total;
  int _index = 0;
  bool _paused = false;

  /// Only the currently visible tip holds a player; it is torn down on every
  /// step so we never keep N decoders alive for an N-tip short.
  VideoPlayerController? _video;

  /// Guards against a slow video init landing after the user already moved on.
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
    _tips = _parseTips(widget.item['sections']);
    _total = _parseDuration(widget.item['duration'] as String?);

    _controller = AnimationController(vsync: this, duration: _slice)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _startTip();
  }

  /// Fallback step length when a tip has no clip: an equal slice of the
  /// short's stated duration.
  Duration get _slice => _tips.isEmpty
      ? _total
      : Duration(microseconds: _total.inMicroseconds ~/ _tips.length);

  /// Loads whatever the current tip needs and starts its progress segment.
  /// With a clip, the segment runs for the clip's real length so the bar and
  /// the video stay in step; otherwise it falls back to [_slice].
  /// Images and poster frames for the tips after this one.
  ///
  /// A story player is the strongest case for preloading there is: the next
  /// step is one tap away and always the same one, so fetching it during the
  /// current step is the difference between an instant advance and a stall.
  void _preloadUpcoming() {
    MediaPreloader.instance.warmNext<_Tip>(
      _tips,
      _index,
      urlsOf: (t) => preloadUrlsFor(image: t.imageUrl, video: t.video),
    );
  }

  Future<void> _startTip() async {
    _preloadUpcoming();
    final token = ++_initToken;
    final old = _video;
    _video = null;
    await old?.dispose();

    final tip = _tips[_index];
    if (!tip.hasVideo) {
      if (!mounted || token != _initToken) return;
      _controller.duration = _slice;
      _controller.forward(from: 0);
      return;
    }

    final c = VideoPlayerController.networkUrl(Uri.parse(tip.videoUrl!));
    try {
      await c.initialize();
    } catch (_) {
      // Bad or unreachable clip — fall back to the still image rather than
      // stranding the user on a blank step.
      await c.dispose();
      if (!mounted || token != _initToken) return;
      _controller.duration = _slice;
      _controller.forward(from: 0);
      return;
    }

    if (!mounted || token != _initToken) {
      await c.dispose();
      return;
    }

    await c.setLooping(false);
    await c.setVolume(1);
    await c.play();
    setState(() => _video = c);
    _controller.duration =
        c.value.duration.inMilliseconds > 0 ? c.value.duration : _slice;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _initToken++; // invalidate any in-flight initialize()
    _video?.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── DATA ──────────────────────────────────────────────────────────────────

  List<_Tip> _parseTips(dynamic sections) {
    if (sections is Map) {
      final raw = (sections['tips'] as List?) ?? [];
      final tips = raw
          .whereType<Map<String, dynamic>>()
          .map(_Tip.fromJson)
          .where((t) => t.title.isNotEmpty || t.description.isNotEmpty)
          .toList();
      if (tips.isNotEmpty) return tips;
    }
    // No authored tips — fall back to a single card built from the plain content
    // so the screen still renders rather than showing an empty shell.
    final content = (widget.item['content'] as String?) ?? '';
    return [
      _Tip(
        title: (widget.item['title'] as String?) ?? '',
        description: content,
        imageUrl: MediaImage.read(widget.item),
      ),
    ];
  }

  /// Parses "0:45" / "1:20" / "45" into a Duration. Defaults to 45s so the
  /// pager still runs if the field is malformed.
  Duration _parseDuration(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const Duration(seconds: 45);
    final parts = raw.trim().split(':');
    try {
      if (parts.length == 1) return Duration(seconds: int.parse(parts[0]));
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(parts[1]),
      );
    } catch (_) {
      return const Duration(seconds: 45);
    }
  }

  String get _title => (widget.item['title'] as String?) ?? '';
  String get _subtitle => (widget.item['content'] as String?) ?? '';
  MediaImage? get _heroImage => MediaImage.read(widget.item);

  bool get _isPremium => (widget.item['isPremium'] as bool?) ?? false;

  /// Premium shorts give the first tip away as a preview and gate the rest.
  static const _freeTips = 1;
  bool get _gated => _isPremium && _index >= _freeTips - 1;

  /// True when the admin authored "Problem & Cause" / "Solution" cards. The
  /// story pager only renders `tips`, so without this escape hatch that content
  /// would be saved but never shown anywhere.
  bool get _hasDetailSections {
    final s = widget.item['sections'];
    if (s is! Map) return false;
    for (final k in ['problemCause', 'solution']) {
      if (((s[k] as List?) ?? []).isNotEmpty) return true;
    }
    return false;
  }

  void _openDetails() {
    _controller.stop();
    _video?.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlowContentDetailScreen(item: widget.item, isVideo: true),
      ),
    ).then((_) {
      if (!mounted || _paused || _gated) return;
      _controller.forward();
      _video?.play();
    });
  }

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  List<Map<String, dynamic>> get _chips =>
      ((widget.item['chips'] as List?) ?? []).cast<Map<String, dynamic>>();

  String get _categoryLabel {
    // GlowCategory's display field is `title` (there is no `name` column).
    final cat = widget.item['category'];
    if (cat is Map && (cat['title'] as String?)?.isNotEmpty == true) {
      return cat['title'] as String;
    }
    return 'Beauty Tips';
  }

  /// Splits the title so the last two words render in the script accent face,
  /// matching "5 Easy Tips for / Glowing Skin". Short titles stay on one line.
  (String, String) get _splitTitle {
    final words = _title.trim().split(RegExp(r'\s+'));
    if (words.length < 3) return ('', _title.trim());
    return (
      words.sublist(0, words.length - 2).join(' '),
      words.sublist(words.length - 2).join(' '),
    );
  }

  // ─── NAVIGATION ────────────────────────────────────────────────────────────

  void _next() {
    // Premium shorts stop at the end of the free preview.
    if (_gated) {
      _controller.stop();
      _video?.pause();
      setState(() {});
      return;
    }
    if (_index >= _tips.length - 1) {
      _controller.stop();
      _video?.pause();
      return; // Hold on the last tip rather than dumping the user out.
    }
    setState(() => _index++);
    _startTip();
  }

  void _prev() {
    if (_index == 0) {
      _startTip();
      return;
    }
    setState(() => _index--);
    _startTip();
  }

  void _setPaused(bool v) {
    if (_paused == v) return;
    setState(() => _paused = v);
    if (v) {
      _controller.stop();
      _video?.pause();
    } else {
      _controller.forward();
      _video?.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Swipe up advances, swipe down goes back a tip — matches the
        // "Swipe up for next tip" affordance at the bottom of the design.
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _next();
          if (v > 200) _prev();
        },
        // Long-press to pause is the standard story convention.
        onLongPressStart: (_) => _setPaused(true),
        onLongPressEnd: (_) => _setPaused(false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            _buildScrim(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 10),
                        if (_subtitle.isNotEmpty) _buildSubtitle(),
                        if (_chips.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildChips(),
                        ],
                        const SizedBox(height: 18),
                        _buildScrubber(),
                        const SizedBox(height: 16),
                        _buildTipCard(),
                        if (_hasDetailSections) ...[
                          const SizedBox(height: 12),
                          _buildDetailsLink(),
                        ],
                        const SizedBox(height: 14),
                        if (_gated) _buildPremiumRow() else _buildSwipeHint(),
                      ],
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

  // ─── BACKGROUND ────────────────────────────────────────────────────────────

  /// Each step shows its own media: the tip's clip if it has one, otherwise the
  /// tip's own image, falling back to the short's cover image only when the tip
  /// has neither.
  Widget _buildBackground() {
    final v = _video;
    if (v != null && v.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: v.value.size.width,
          height: v.value.size.height,
          child: VideoPlayer(v),
        ),
      );
    }

    // While a clip is still opening, its own poster frame is the closest thing
    // to what is about to appear — closer than the tip's cover image — so the
    // handover to video has nothing to jump through.
    final tip = _tips[_index];
    final poster = tip.video?.poster;

    return GlowImage(
      media: (poster != null && poster.isNotEmpty)
          ? MediaImage(
              thumb: poster,
              medium: poster,
              large: poster,
              blurhash: tip.video?.blurhash,
            )
          : tip.imageUrl ?? _heroImage,
      error: _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A2E3D), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// Dark gradient so the white type stays legible over any photo.
  Widget _buildScrim() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.45),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.28, 0.55, 1.0],
        ),
      ),
    );
  }

  // ─── TOP BAR ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildSegments()),
          const SizedBox(width: 12),
          if (_isPremium) ...[
            _buildPremiumBadge(),
            const SizedBox(width: 8),
          ],
          _buildCategoryPill(),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSegments() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        children: [
          for (var i = 0; i < _tips.length; i++) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: i < _index
                      ? 1.0
                      : i == _index
                          ? _controller.value
                          : 0.0,
                  minHeight: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation(_pink),
                ),
              ),
            ),
            if (i != _tips.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: _pink),
          const SizedBox(width: 6),
          Text(
            _categoryLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TITLE / SUBTITLE / CHIPS ──────────────────────────────────────────────

  Widget _buildTitle() {
    final (lead, accent) = _splitTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lead.isNotEmpty)
          Text(
            lead,
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.15,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                accent,
                style: GoogleFonts.dancingScript(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: _pink,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text('✨', style: TextStyle(fontSize: 20)),
          ],
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        color: Colors.white.withValues(alpha: 0.92),
        height: 1.45,
      ),
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Text(
              '# ${(c['label'] as String?) ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ─── SCRUBBER ──────────────────────────────────────────────────────────────

  Widget _buildScrubber() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Overall progress across every tip, so the clock reads as one video.
        final overall =
            _tips.isEmpty ? 0.0 : (_index + _controller.value) / _tips.length;
        final elapsed = Duration(
          microseconds: (_total.inMicroseconds * overall).round(),
        );
        return Column(
          children: [
            LayoutBuilder(
              builder: (_, box) {
                final w = box.maxWidth;
                return SizedBox(
                  height: 14,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: w * overall,
                        decoration: BoxDecoration(
                          color: _pink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: (w * overall - 6).clamp(0.0, w - 12),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_fmt(elapsed)} / ${_fmt(_total)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── TIP CARD ──────────────────────────────────────────────────────────────

  Widget _buildTipCard() {
    final tip = _tips[_index];
    // Thumbnails preview the tips that come after this one.
    final upcoming = _tips
        .skip(_index + 1)
        .where((t) => t.imageUrl != null)
        .toList();
    final shown = upcoming.take(2).toList();
    final more = upcoming.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FB8), Color(0xFFFFC2D8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tip ${_index + 1} of ${_tips.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.description.isNotEmpty ? tip.description : tip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (shown.isNotEmpty) ...[
            const SizedBox(width: 10),
            _buildThumbs(shown, more),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbs(List<_Tip> shown, int more) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                GlowImage(
                  media: shown[i].imageUrl,
                  width: 44,
                  height: 44,
                  error: Container(
                    width: 44,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                // The "2+" badge sits on the last visible thumbnail.
                if (i == shown.length - 1 && more > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Text(
                        '$more+',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (i != shown.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  // ─── PREMIUM ───────────────────────────────────────────────────────────────

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown once the free preview runs out. Mirrors the Watch Ad / Go Premium
  /// pair on the content detail screen — both are stubs there too, since no ad
  /// SDK or payment backend exists yet.
  Widget _buildPremiumRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Unlock the remaining ${_tips.length - _freeTips} tips',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _premiumButton(
                label: 'Watch Ad',
                icon: Icons.play_circle_outline_rounded,
                filled: false,
                onTap: () => _notImplemented('Watch Ad'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _premiumButton(
                label: 'Go Premium',
                icon: Icons.workspace_premium_rounded,
                filled: true,
                onTap: () => _notImplemented('Go Premium'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _premiumButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? _pink : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Escape hatch to the tabbed detail screen so "Problem & Cause" / "Solution"
  /// cards authored in the admin remain reachable from a Short.
  Widget _buildDetailsLink() {
    return GestureDetector(
      onTap: _openDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'View full details',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SWIPE HINT ────────────────────────────────────────────────────────────

  Widget _buildSwipeHint() {
    final isLast = _index >= _tips.length - 1;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white.withValues(alpha: isLast ? 0.35 : 0.9),
            size: 26,
          ),
          Text(
            isLast ? '✨ That\'s the last tip ✨' : '✨ Swipe up for next tip ✨',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: isLast ? 0.6 : 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
