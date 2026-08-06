import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/media.dart';
import '../services/media_analytics.dart';
import '../services/media_downloader.dart';

/// Shared disk cache for every remote image in the app.
///
/// A named manager rather than the package default so the retention policy is
/// ours to set. Workout and Glow media is written by an admin and then changes
/// rarely, so a long stale period turns almost every repeat view into a local
/// read — including on a cold start, which `Image.network` could never do
/// because its cache lives in memory and dies with the process.
class GlowImageCache {
  GlowImageCache._();

  static const String key = 'glow_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 600,
    ),
  );

  /// Drops one entry so the next build refetches it. Used by the retry path.
  static Future<void> evict(String url) async {
    try {
      await instance.removeFile(url);
    } catch (_) {
      // Nothing cached for this url yet — the retry is still worth making.
    }
    await CachedNetworkImageProvider(url, cacheManager: instance).evict();
  }
}

/// The single way this app loads a remote image.
///
/// Wraps [CachedNetworkImage] so every call site gets a memory cache, a disk
/// cache, a fade-in, a placeholder, an error fallback and retry without
/// repeating any of it. Replaces `Image.network`, which re-downloaded the same
/// bytes on every cold start and decoded every image at full source resolution.
class GlowImage extends StatefulWidget {
  /// Null or empty renders [error] — matching the `url == null ? fallback :`
  /// checks this widget replaced, so callers no longer need them.
  ///
  /// Ignored when [media] is set.
  final String? url;

  /// The API's media object. Preferred over [url]: it carries three widths, so
  /// the size actually fetched can match the box being drawn into, and a
  /// blurhash to show while it arrives.
  final MediaImage? media;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// [Alignment] rather than [AlignmentGeometry] because that is what
  /// [CachedNetworkImage] takes.
  final Alignment alignment;

  /// Clips the image. Saves wrapping the call site in a `ClipRRect`.
  final BorderRadius? borderRadius;

  /// Shown while loading. Defaults to [error], so a card holds its shape and
  /// colour instead of flashing empty and then filling in.
  final Widget? placeholder;

  /// Shown when the url is empty or the load fails after every retry.
  final Widget? error;

  /// Draws a spinner over the placeholder. Off by default: on a grid of cards
  /// a dozen spinners is noisier than the images simply appearing.
  final bool showLoader;

  /// Non-null wraps the image in a [Hero] with this tag.
  final Object? heroTag;

  final Duration fadeDuration;

  /// Automatic refetches after a failed load, with backoff.
  final int maxRetries;

  const GlowImage({
    super.key,
    this.url,
    this.media,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.placeholder,
    this.error,
    this.showLoader = false,
    this.heroTag,
    this.fadeDuration = const Duration(milliseconds: 180),
    this.maxRetries = 2,
  });

  @override
  State<GlowImage> createState() => _GlowImageState();
}

class _GlowImageState extends State<GlowImage> {
  int _attempt = 0;
  Timer? _retry;

  /// Decode target, resolved on first layout and then frozen. Cleared only when
  /// the source changes, so a resizing parent can never churn the provider.
  int? _decodePx;

  /// Variant chosen on first layout. Same reasoning as [_decodePx].
  String? _resolvedUrl;

  /// Urls already measured by this widget, so a rebuild does not report the
  /// same load twice and skew the averages towards zero.
  final _measured = <String>{};

  @override
  void didUpdateWidget(GlowImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.media?.large != widget.media?.large) {
      _retry?.cancel();
      _retry = null;
      _attempt = 0;
      _decodePx = null;
      _resolvedUrl = null;
    }
  }

  /// Records how long this image took to become available, and whether it came
  /// from disk.
  ///
  /// Measured through the cache manager rather than by wrapping the render
  /// path, which would mean rebuilding the image widget by hand and risking a
  /// visual change to every image in the app for the sake of a number. The
  /// second request costs nothing: flutter_cache_manager de-duplicates
  /// concurrent fetches of the same key, so this joins the download
  /// [CachedNetworkImage] already started instead of issuing another.
  ///
  /// It therefore measures time-to-bytes, not time-to-pixels — decode is not
  /// included. Bytes is the part that varies by hundreds of milliseconds and
  /// the part the media pipeline was built to change.
  Future<void> _measure(String url) async {
    if (!_measured.add(url)) return;
    final timer = MediaTimer();
    try {
      final cached = await GlowImageCache.instance.getFileFromCache(url);
      if (cached != null) {
        timer.report((ms) => MediaAnalytics.instance.imageLoad(
              ms: ms,
              cacheHit: true,
              bytes: cached.file.lengthSync(),
              url: url,
            ));
        return;
      }
      final file = await GlowImageCache.instance.getSingleFile(url, key: url);
      timer.report((ms) => MediaAnalytics.instance.imageLoad(
            ms: ms,
            cacheHit: false,
            bytes: file.lengthSync(),
            url: url,
          ));
    } catch (_) {
      MediaAnalytics.instance.imageFailed(url);
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  /// A failed load is usually a dropped connection rather than a missing
  /// object, so it is worth trying again before showing the fallback for good.
  /// Backs off so a genuinely dead url costs two quick requests, not a loop.
  void _scheduleRetry(String url) {
    if (_retry != null || _attempt >= widget.maxRetries) return;

    _retry = Timer(Duration(milliseconds: 500 << _attempt), () async {
      _retry = null;
      await GlowImageCache.evict(url);
      if (!mounted) return;
      setState(() => _attempt++);
    });
  }

  Widget _fallback() {
    if (widget.error != null) return widget.error!;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const ColoredBox(color: Color(0xFFF2F2F5)),
    );
  }

  Widget _placeholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    // The blurhash beats every other placeholder: it is the right colours in
    // roughly the right places, decoded from ~30 characters that already
    // arrived with the JSON, so the card is never blank and never wrong.
    final hash = widget.media?.blurhash;
    if (hash != null && hash.isNotEmpty && !widget.showLoader) {
      return BlurHash(hash: hash, imageFit: widget.fit, color: Colors.transparent);
    }

    if (!widget.showLoader) return _fallback();
    return Stack(
      fit: StackFit.expand,
      children: [
        _fallback(),
        const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF136B)),
            ),
          ),
        ),
      ],
    );
  }

  /// Decode target, in device pixels, fixed for as long as the url is.
  ///
  /// Decoding a 3000px photo for a 44px thumbnail is what makes a grid stutter,
  /// so the decode is sized to the box it will occupy. Only one dimension is
  /// ever passed: Flutter infers the other and preserves the aspect ratio, where
  /// giving it both would stretch the bitmap.
  ///
  /// Computed once and then held. Deriving it from live constraints on every
  /// build was a mistake: any parent that resizes — an animating countdown, a
  /// rebuilding timer screen — could push the value across a bucket boundary,
  /// which changes the decode target, which makes CachedNetworkImage resolve a
  /// new provider, which drops back to the placeholder and fades in again. That
  /// is the flicker. Worse, when the parent sizes itself to the image, the new
  /// decode changes the layout that produced it and the two feed each other,
  /// pinning the UI thread and leaving taps unanswered.
  int? _decodeFor(BuildContext context, BoxConstraints c) {
    if (_decodePx != null) return _decodePx;

    final w = _finite(widget.width) ?? (c.hasBoundedWidth ? c.maxWidth : null);
    final h = _finite(widget.height) ?? (c.hasBoundedHeight ? c.maxHeight : null);

    final sides = [w, h].whereType<double>().where((v) => v.isFinite && v > 0);
    if (sides.isEmpty) return null;

    var px = sides.reduce(math.max) * MediaQuery.devicePixelRatioOf(context);

    // Under BoxFit.cover the source is scaled by its *shorter* side, so a wide
    // image in a small square box is rendered wider than the box. Only small
    // boxes need that headroom. Applying it to a full-bleed image — as this
    // used to — asked for 1856px on a 1233px-wide screen: half again the width,
    // so more than twice the bitmap, on the busiest screen in the app.
    if (px < 600) px *= 1.5;

    const bucket = 64;
    _decodePx = ((px / bucket).ceil() * bucket).clamp(bucket, 1600);
    return _decodePx;
  }

  static double? _finite(double? v) =>
      (v != null && v.isFinite && v > 0) ? v : null;

  /// Resolves which variant to fetch once the box is known, then keeps it.
  ///
  /// With a [MediaImage] this is where the three widths pay off: a 400px tile
  /// asks for the 400px file rather than the 1200px one.
  ///
  /// Pinned for the same reason as the decode target. Re-deriving it per build
  /// meant a parent that resized a few pixels could flip the choice from thumb
  /// to medium, which is a different url, a different provider, and a visible
  /// reload of an image that was already on screen.
  String? _urlFor(BuildContext context, BoxConstraints c) {
    if (_resolvedUrl != null) return _resolvedUrl;

    final media = widget.media;
    if (media == null) {
      final url = widget.url?.trim();
      _resolvedUrl = (url == null || url.isEmpty) ? null : url;
      return _resolvedUrl;
    }

    final box = _finite(widget.width) ?? (c.hasBoundedWidth ? c.maxWidth : null);
    _resolvedUrl = media.urlFor(box, MediaQuery.devicePixelRatioOf(context));
    return _resolvedUrl;
  }

  Widget _image() {
    return LayoutBuilder(builder: (context, constraints) {
      final url = _urlFor(context, constraints);
      if (url == null || url.isEmpty) return _fallback();

      // A downloaded copy is used directly, so an offline workout shows its
      // pictures and not a row of grey boxes. Nothing to measure or retry here:
      // reading a local file has no network cost and cannot half-fail.
      final local = MediaDownloader.instance.fileFor(url);
      if (local != null) {
        return Image.file(
          local,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
          cacheWidth: _decodeFor(context, constraints),
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }

      unawaited(_measure(url));

      return CachedNetworkImage(
        // Bumping the key on retry forces a fresh resolve of the provider.
        key: ValueKey('$url#$_attempt'),
        imageUrl: url,
        cacheManager: GlowImageCache.instance,
        cacheKey: url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        fadeInDuration: widget.fadeDuration,
        fadeOutDuration: const Duration(milliseconds: 80),
        memCacheWidth: _decodeFor(context, constraints),
        // Keeps the previous frame on screen while the next url loads, rather
        // than dropping to the placeholder. Matters in the Shorts story player,
        // where the image changes as you tap through tips.
        useOldImageOnUrlChange: true,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _fallback(),
        errorListener: (_) => _scheduleRetry(url),
      );
    });
  }

  /// True when there is anything at all to fetch.
  bool get _hasSource {
    final m = widget.media;
    if (m != null && (m.thumb ?? m.medium ?? m.large) != null) return true;
    final u = widget.url?.trim();
    return u != null && u.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _hasSource ? _image() : _fallback();

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    if (widget.heroTag != null) {
      child = Hero(tag: widget.heroTag!, child: child);
    }
    return child;
  }
}
