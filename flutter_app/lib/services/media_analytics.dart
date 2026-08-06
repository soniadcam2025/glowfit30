import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/network/api_client.dart';

/// One measurement taken while loading media.
class MediaEvent {
  final String type;
  final int? ms;
  final int? bytes;
  final bool? cacheHit;
  final bool ok;
  final String? url;

  const MediaEvent(
    this.type, {
    this.ms,
    this.bytes,
    this.cacheHit,
    this.ok = true,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (ms != null) 'ms': ms,
        if (bytes != null) 'bytes': bytes,
        if (cacheHit != null) 'cacheHit': cacheHit,
        'ok': ok,
        if (url != null && url!.isNotEmpty) 'url': url,
      };
}

/// Records how media actually behaves on real devices.
///
/// The numbers the media work was done for — how long an image takes to appear,
/// how long a video waits before its first frame, how often the cache does its
/// job — cannot be measured from a laptop on a fast connection. This collects
/// them where they happen and ships them in batches.
///
/// Everything here is best-effort and fire-and-forget. Telemetry that can slow
/// a screen down, or fail one, is worse than no telemetry: it would degrade the
/// very thing it exists to measure.
class MediaAnalytics {
  MediaAnalytics._();
  static final MediaAnalytics instance = MediaAnalytics._();

  /// Flush when the buffer reaches this, so a heavy screen does not accumulate
  /// hundreds of events before anything is sent.
  static const _batchSize = 25;

  /// ...or when this much time has passed, so a quiet session still reports.
  static const _flushAfter = Duration(seconds: 30);

  /// Hard ceiling. If the network is down for a whole session the oldest
  /// measurements are dropped rather than growing without bound.
  static const _maxBuffered = 200;

  final _buffer = <MediaEvent>[];
  Timer? _timer;
  bool _sending = false;

  /// Off in tests and any build that has no API client registered.
  bool enabled = true;

  String? platform;
  String? appVersion;

  void record(MediaEvent event) {
    if (!enabled) return;
    _buffer.add(event);
    if (_buffer.length > _maxBuffered) {
      _buffer.removeRange(0, _buffer.length - _maxBuffered);
    }
    if (_buffer.length >= _batchSize) {
      unawaited(flush());
    } else {
      _timer ??= Timer(_flushAfter, () => unawaited(flush()));
    }
  }

  // ── Convenience recorders, so call sites read as what they measure ────────

  void imageLoad({required int ms, required bool cacheHit, int? bytes, String? url}) =>
      record(MediaEvent('image_load', ms: ms, cacheHit: cacheHit, bytes: bytes, url: url));

  void imageFailed(String url) =>
      record(MediaEvent('image_load', ok: false, url: url));

  void videoStart({required int ms, String? url}) =>
      record(MediaEvent('video_start', ms: ms, url: url));

  void videoStartFailed(String url) =>
      record(MediaEvent('video_start', ok: false, url: url));

  /// The player ran out of buffer mid-playback. The count of these is the
  /// clearest signal that a clip is too big or the connection too slow.
  void buffering(String url) => record(MediaEvent('buffer', url: url));

  void downloadOk({required int bytes, String? url}) =>
      record(MediaEvent('download_ok', bytes: bytes, cacheHit: false, url: url));

  void downloadFailed(String url) =>
      record(MediaEvent('download_fail', ok: false, url: url));

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_sending || _buffer.isEmpty || !enabled) return;
    if (!Get.isRegistered<ApiClient>()) return;

    final batch = List<MediaEvent>.from(_buffer);
    _buffer.clear();
    _sending = true;
    try {
      await Get.find<ApiClient>().post('/media-metrics', data: {
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
        'events': batch.map((e) => e.toJson()).toList(),
      });
      if (kDebugMode) debugPrint('[metrics] sent ${batch.length} event(s)');
    } catch (_) {
      // Put them back so a dropped connection does not lose the window, but
      // never let a retry queue grow past the ceiling.
      _buffer.insertAll(0, batch);
      if (_buffer.length > _maxBuffered) {
        _buffer.removeRange(0, _buffer.length - _maxBuffered);
      }
    } finally {
      _sending = false;
    }
  }
}

/// Times a media operation and reports it once, whatever the outcome.
///
/// Exists so call sites cannot accidentally report twice or forget the failure
/// path — the two ways a hand-rolled stopwatch usually goes wrong.
class MediaTimer {
  final Stopwatch _sw = Stopwatch()..start();
  bool _reported = false;

  int get elapsedMs => _sw.elapsedMilliseconds;

  /// Returns the measured duration so a caller can log or assert on it.
  int? report(void Function(int ms) send) {
    if (_reported) return null;
    _reported = true;
    _sw.stop();
    final ms = _sw.elapsedMilliseconds;
    send(ms);
    return ms;
  }
}
