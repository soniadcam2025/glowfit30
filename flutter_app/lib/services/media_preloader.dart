import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import '../models/media.dart';
import '../widgets/glow_image.dart';

/// Fetches media the user is about to need, before they ask for it.
///
/// A workout is the case that matters: the next exercise is known the moment
/// the current one starts, and it is thirty seconds away. Downloading it during
/// that window turns the transition from a network round trip into a disk read.
///
/// Deliberately conservative about when it runs. Preloading is spending someone
/// else's data on a guess, so it only happens on an unmetered connection unless
/// the user has opted in, and it is capped in both breadth and concurrency.
class MediaPreloader {
  MediaPreloader._();
  static final MediaPreloader instance = MediaPreloader._();

  static const _cellularKey = 'preload_on_cellular';

  /// How many items one call may fetch. Two exercises' worth of image and
  /// poster is the working set; beyond that it is speculation paid for in data.
  static const _maxPerCall = 6;

  /// Parallel downloads.
  ///
  /// One, not two. An exercise screen is streaming video off the same
  /// connection, and a progressive MP4 starves the moment something else takes
  /// the bandwidth: it plays from its initial buffer, reaches the end of it and
  /// stops dead. Preloading is by definition less urgent than the frame the
  /// user is watching, so it gets a single lane.
  static const _concurrency = 1;

  /// How long to wait before a preload starts.
  ///
  /// Long enough for the media the user actually opened to get its buffer in
  /// first. Preloading the next exercise the instant the current one begins is
  /// exactly the wrong moment — that is when the video needs the network most.
  static const _startDelay = Duration(seconds: 8);

  final _inFlight = <String>{};
  final _box = GetStorage();

  /// Off by default: nobody expects a fitness app to spend their mobile data on
  /// files they have not asked for yet.
  bool get allowOnCellular => _box.read<bool>(_cellularKey) ?? false;

  set allowOnCellular(bool value) => _box.write(_cellularKey, value);

  /// Whether a preload would run right now.
  ///
  /// Public so a settings screen can say what the current choice actually means
  /// on this connection, rather than describing a rule and leaving the user to
  /// guess which side of it they are on.
  Future<bool> get canPreloadNow => _allowed();

  /// Wi-Fi, ethernet, or the user said yes to cellular.
  Future<bool> _allowed() async {
    if (allowOnCellular) return true;
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (_) {
      // Unknown connection type — assume metered and stay off.
      return false;
    }
  }

  /// Warms the disk cache for [urls]. Silent and best-effort throughout: a
  /// preload that fails costs nothing, because the real fetch still happens
  /// when the screen actually needs it.
  Future<void> warm(Iterable<String?> urls) async {
    final wanted = urls
        .whereType<String>()
        .where((u) => u.isNotEmpty && u.startsWith('http'))
        .toSet()
        .where((u) => !_inFlight.contains(u))
        .take(_maxPerCall)
        .toList();

    if (wanted.isEmpty) return;

    // Drop anything already on disk *before* anything else happens. Measuring
    // this showed a fully-cached set still sitting through the whole start
    // delay doing nothing, holding its urls marked in-flight the entire time —
    // which on a replayed workout is every call.
    final missing = <String>[];
    for (final url in wanted) {
      if (await _cached(url)) continue;
      missing.add(url);
    }
    if (missing.isEmpty) return;

    if (!await _allowed()) {
      if (kDebugMode) {
        debugPrint('[preload] skipped ${missing.length} — metered connection');
      }
      return;
    }

    _inFlight.addAll(missing);
    try {
      await Future<void>.delayed(_startDelay);
      if (kDebugMode) debugPrint('[preload] warming ${missing.length} file(s)');
      for (var i = 0; i < missing.length; i += _concurrency) {
        final batch = missing.skip(i).take(_concurrency);
        await Future.wait(batch.map(_fetch));
      }
    } finally {
      _inFlight.removeAll(missing);
    }
  }

  Future<bool> _cached(String url) async {
    try {
      return await GlowImageCache.instance.getFileFromCache(url) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetch(String url) async {
    try {
      // Re-checked here as well: the delay above is long enough that the screen
      // itself may have fetched this in the meantime.
      if (await _cached(url)) return;
      await GlowImageCache.instance.downloadFile(url, key: url);
      if (kDebugMode) debugPrint('[preload] cached $url');
    } catch (_) {
      // Offline, 404, whatever. Not worth surfacing.
    }
  }

  /// Preloads the images and posters for the next few items in a sequence.
  ///
  /// Takes the whole list and an index rather than pre-sliced urls so callers
  /// cannot accidentally preload the item already on screen.
  Future<void> warmNext<T>(
    List<T> items,
    int currentIndex, {
    int lookahead = 2,
    required Iterable<String?> Function(T) urlsOf,
  }) {
    final next = <String?>[];
    for (var i = currentIndex + 1; i <= currentIndex + lookahead; i++) {
      if (i < 0 || i >= items.length) continue;
      next.addAll(urlsOf(items[i]));
    }
    return warm(next);
  }
}

/// Every url worth having ahead of time for one media object.
///
/// Thumb as well as the display size: a list or grid the user lands on next
/// asks for the small one, and it is cheap enough that fetching both is still
/// less than one full-size image.
Iterable<String?> preloadUrlsFor({MediaImage? image, MediaVideo? video}) sync* {
  if (image != null) {
    yield image.thumb;
    yield image.medium ?? image.large;
  }
  if (video != null) {
    // The poster, never the clip: a video is megabytes and the player streams
    // it on demand, but the poster is what removes the blank frame.
    yield video.poster;
  }
}
