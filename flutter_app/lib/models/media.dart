/// Media objects returned by the API.
///
/// Every endpoint now returns an `image` object beside each `imageUrl`, and a
/// `video` object beside each `videoUrl`. The strings are unchanged, so parsing
/// accepts either shape: [fromAny] takes the object when it is there and falls
/// back to the plain url when it is not. Nothing in the app has to know which
/// endpoints have been migrated.
library;

class MediaImage {
  /// 400px — grid tiles, list thumbnails, avatars.
  final String? thumb;

  /// 800px — cards, half-width heroes.
  final String? medium;

  /// 1200px — full-bleed heroes.
  final String? large;

  final int? width;
  final int? height;
  final String? mime;
  final int? size;

  /// ~30 chars decoding to a blurred approximation of the image. Renders before
  /// any bytes arrive, so a card is never blank.
  final String? blurhash;

  const MediaImage({
    this.thumb,
    this.medium,
    this.large,
    this.width,
    this.height,
    this.mime,
    this.size,
    this.blurhash,
  });

  /// Aspect ratio, when the API knew it. Lets a layout reserve the right space
  /// before the image loads instead of jumping when it arrives.
  double? get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : null;

  /// Accepts the new object, a bare url string, or null.
  static MediaImage? fromAny(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : MediaImage(thumb: value, medium: value, large: value);
    }
    if (value is! Map) return null;

    return MediaImage(
      thumb: value['thumb'] as String?,
      medium: value['medium'] as String?,
      large: value['large'] as String?,
      width: (value['width'] as num?)?.toInt(),
      height: (value['height'] as num?)?.toInt(),
      mime: value['mime'] as String?,
      size: (value['size'] as num?)?.toInt(),
      blurhash: value['blurhash'] as String?,
    );
  }

  /// Reads `image` if the API sent one, otherwise the legacy `imageUrl`.
  static MediaImage? read(Map? map, {String object = 'image', String url = 'imageUrl'}) {
    if (map == null) return null;
    return fromAny(map[object]) ?? fromAny(map[url]);
  }

  /// Smallest variant that still covers [displayWidth] logical pixels.
  ///
  /// Picking by the box rather than always taking `large` is the entire point of
  /// having three sizes: a 400px thumb in a grid tile is a twentieth of the
  /// bytes of the 1200px version and looks identical at that size.
  String? urlFor(double? displayWidth, double devicePixelRatio) {
    final candidates = [thumb, medium, large];
    if (candidates.every((c) => c == null)) return null;
    if (displayWidth == null || !displayWidth.isFinite || displayWidth <= 0) {
      return large ?? medium ?? thumb;
    }

    final px = displayWidth * devicePixelRatio;
    // Same 1.5x margin the decoder uses: under BoxFit.cover a wide image in a
    // square box is rendered wider than the box.
    final needed = px * 1.5;

    if (needed <= 400 && thumb != null) return thumb;
    if (needed <= 800 && medium != null) return medium;
    return large ?? medium ?? thumb;
  }
}

class MediaVideo {
  final String? url;

  /// Still frame, as a WebP image. Shown instantly while the player opens, so
  /// there is no black rectangle before the first frame.
  final String? poster;

  final double? duration;
  final int? width;
  final int? height;
  final String? mime;
  final int? size;
  final String? blurhash;

  const MediaVideo({
    this.url,
    this.poster,
    this.duration,
    this.width,
    this.height,
    this.mime,
    this.size,
    this.blurhash,
  });

  bool get isPlayable => url != null && url!.isNotEmpty;

  static MediaVideo? fromAny(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : MediaVideo(url: value);
    if (value is! Map) return null;

    return MediaVideo(
      url: value['url'] as String?,
      poster: value['poster'] as String?,
      duration: (value['duration'] as num?)?.toDouble(),
      width: (value['width'] as num?)?.toInt(),
      height: (value['height'] as num?)?.toInt(),
      mime: value['mime'] as String?,
      size: (value['size'] as num?)?.toInt(),
      blurhash: value['blurhash'] as String?,
    );
  }

  static MediaVideo? read(Map? map, {String object = 'video', String url = 'videoUrl'}) {
    if (map == null) return null;
    return fromAny(map[object]) ?? fromAny(map[url]);
  }
}
