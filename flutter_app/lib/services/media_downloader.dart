import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/media.dart';
import 'media_analytics.dart';
import 'media_preloader.dart';

/// State of one bundle download, for a progress indicator to render.
@immutable
class DownloadProgress {
  /// Identifies what is being downloaded — a workout id, usually.
  final String id;
  final String label;
  final int completed;
  final int total;

  /// Bytes written so far across the whole bundle.
  final int bytes;
  final bool done;
  final bool cancelled;
  final String? error;

  const DownloadProgress({
    required this.id,
    required this.label,
    required this.completed,
    required this.total,
    this.bytes = 0,
    this.done = false,
    this.cancelled = false,
    this.error,
  });

  /// File-count based rather than byte based: total size is unknown until every
  /// header has come back, and a bar that jumps backwards as it learns the real
  /// total is worse than a coarse one that only moves forward.
  double get fraction => total == 0 ? 0 : completed / total;

  bool get running => !done && !cancelled && error == null;

  DownloadProgress copyWith({
    int? completed,
    int? bytes,
    bool? done,
    bool? cancelled,
    String? error,
  }) =>
      DownloadProgress(
        id: id,
        label: label,
        completed: completed ?? this.completed,
        total: total,
        bytes: bytes ?? this.bytes,
        done: done ?? this.done,
        cancelled: cancelled ?? this.cancelled,
        error: error ?? this.error,
      );
}

class _Entry {
  final String file;
  final int bytes;
  final int savedAt;
  int lastUsed;

  _Entry({
    required this.file,
    required this.bytes,
    required this.savedAt,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() =>
      {'f': file, 'b': bytes, 's': savedAt, 'u': lastUsed};

  static _Entry? fromJson(dynamic v) {
    if (v is! Map) return null;
    final file = v['f'];
    if (file is! String) return null;
    return _Entry(
      file: file,
      bytes: (v['b'] as num?)?.toInt() ?? 0,
      savedAt: (v['s'] as num?)?.toInt() ?? 0,
      lastUsed: (v['u'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Keeps a workout's media on the device so it plays with no network at all.
///
/// Distinct from [MediaPreloader], and deliberately so. Preloading is a guess
/// about the next thirty seconds, held in a cache the system may evict at any
/// time. This is a promise: the user asked for a workout to be available
/// offline, so the files live in application support — which is not swept by
/// the OS — and stay until they expire, the budget forces them out, or the user
/// removes them.
///
/// It also downloads the video itself, which preloading never does. That is the
/// whole point: a streamed clip is useless on a train.
class MediaDownloader {
  MediaDownloader._();
  static final MediaDownloader instance = MediaDownloader._();

  static const _indexKey = 'media_downloads_index';
  static const _budgetKey = 'media_downloads_budget_bytes';
  static const _dirName = 'media_downloads';

  /// Default ceiling for downloaded media.
  ///
  /// 512 MB is a few workouts' worth of video. Large enough to be useful,
  /// small enough that a fitness app is never the reason a phone runs out of
  /// space — the failure mode users actually notice and uninstall over.
  static const _defaultBudget = 512 * 1024 * 1024;

  /// Files older than this are removed on the next sweep. Exercise clips do get
  /// replaced, and a download kept forever eventually shows the wrong movement.
  static const _maxAge = Duration(days: 30);

  /// One at a time. Same reasoning as the preloader: a download competing with
  /// the video the user is watching is what starves a progressive stream.
  static const _concurrency = 1;

  final _box = GetStorage();
  final _dio = Dio();

  Directory? _dir;
  Map<String, _Entry> _index = {};
  bool _ready = false;
  CancelToken? _cancel;

  /// Current job, or null when idle. A [ValueNotifier] rather than a stream so
  /// a widget can bind to it directly and always sees the latest state on
  /// rebuild, including one that mounts mid-download.
  final ValueNotifier<DownloadProgress?> progress = ValueNotifier(null);

  int get budgetBytes => _box.read<int>(_budgetKey) ?? _defaultBudget;

  /// Only the ceiling is clamped.
  ///
  /// There is deliberately no floor. A floor would silently substitute a
  /// different budget than the one asked for — which is how a "keep nothing on
  /// this device" setting turns into a phone quietly holding megabytes anyway.
  /// Zero is a coherent instruction: sweep everything and keep nothing.
  set budgetBytes(int value) {
    _box.write(_budgetKey, value.clamp(0, 8 * 1024 * 1024 * 1024));
    unawaited(sweep());
  }

  /// Total bytes currently held on disk.
  int get usedBytes =>
      _index.values.fold<int>(0, (sum, e) => sum + e.bytes);

  int get fileCount => _index.length;

  bool get isDownloading => progress.value?.running ?? false;

  /// Loads the index and cleans up. Safe to call more than once.
  Future<void> init() async {
    if (_ready) return;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/$_dirName');
      if (!await dir.exists()) await dir.create(recursive: true);
      _dir = dir;

      final raw = _box.read<String>(_indexKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _index = {
            for (final entry in decoded.entries)
              if (_Entry.fromJson(entry.value) case final e?)
                entry.key.toString(): e,
          };
        }
      }
      _ready = true;
      await sweep();
    } catch (e) {
      // A device that will not give us a directory simply has no offline
      // support. Everything else in the app keeps working.
      if (kDebugMode) debugPrint('[download] init failed: $e');
      _ready = true;
    }
  }

  /// Local file for [url], or null if it was never downloaded.
  ///
  /// Touches the entry so the budget evicts genuinely unused files first rather
  /// than merely old ones.
  File? fileFor(String? url) {
    if (url == null || url.isEmpty) return null;
    final entry = _index[url];
    final dir = _dir;
    if (entry == null || dir == null) return null;
    final file = File('${dir.path}/${entry.file}');
    if (!file.existsSync()) {
      // Deleted behind our back. Drop the stale record so callers stop being
      // told a file exists when it does not.
      _index.remove(url);
      unawaited(_persist());
      return null;
    }
    entry.lastUsed = DateTime.now().millisecondsSinceEpoch;
    return file;
  }

  bool has(String? url) => fileFor(url) != null;

  /// Whether every url in [urls] is on disk — i.e. this bundle plays offline.
  bool hasAll(Iterable<String?> urls) {
    final wanted = urls.whereType<String>().where((u) => u.isNotEmpty);
    if (wanted.isEmpty) return false;
    return wanted.every(has);
  }

  /// Downloads [urls] and reports progress as it goes.
  ///
  /// Respects the same connection rule as preloading: this can be tens of
  /// megabytes, and spending that on someone's mobile plan without being asked
  /// is not a decision an app gets to make. [force] is for the case where the
  /// user pressed a download button, which *is* being asked.
  Future<bool> download(
    String id,
    Iterable<String?> urls, {
    String label = 'Workout',
    bool force = false,
  }) async {
    await init();

    if (isDownloading) return false;

    final wanted = urls
        .whereType<String>()
        .where((u) => u.isNotEmpty && u.startsWith('http'))
        .toSet()
        .toList();
    if (wanted.isEmpty) return false;

    final missing = wanted.where((u) => !has(u)).toList();
    if (missing.isEmpty) {
      progress.value = DownloadProgress(
        id: id,
        label: label,
        completed: wanted.length,
        total: wanted.length,
        done: true,
      );
      return true;
    }

    if (!force && !await MediaPreloader.instance.canPreloadNow) {
      progress.value = DownloadProgress(
        id: id,
        label: label,
        completed: 0,
        total: missing.length,
        error: 'Waiting for Wi-Fi',
      );
      return false;
    }

    final cancel = CancelToken();
    _cancel = cancel;
    var state = DownloadProgress(
      id: id,
      label: label,
      completed: 0,
      total: missing.length,
    );
    progress.value = state;

    var bytes = 0;
    var failures = 0;

    try {
      for (var i = 0; i < missing.length; i += _concurrency) {
        if (cancel.isCancelled) break;
        final batch = missing.skip(i).take(_concurrency);
        final results = await Future.wait(
          batch.map((u) => _fetch(u, cancel)),
        );
        for (final written in results) {
          if (written == null) {
            failures += 1;
          } else {
            bytes += written;
          }
        }
        state = state.copyWith(
          completed: (i + _concurrency).clamp(0, missing.length),
          bytes: bytes,
        );
        progress.value = state;
      }
    } finally {
      _cancel = null;
      await _persist();
      await sweep();
    }

    if (cancel.isCancelled) {
      progress.value = state.copyWith(cancelled: true);
      return false;
    }

    // Partial success is still a failure for the promise being made: the user
    // was told this workout would work offline, and a missing clip means it
    // will not.
    final ok = failures == 0;
    progress.value = state.copyWith(
      completed: missing.length,
      bytes: bytes,
      done: true,
      error: ok ? null : '$failures file(s) failed',
    );
    return ok;
  }

  void cancel() => _cancel?.cancel('cancelled by user');

  /// Downloads everything needed to run [items] offline, video included.
  Future<bool> downloadBundle<T>(
    String id,
    List<T> items, {
    String label = 'Workout',
    bool force = false,
    required Iterable<String?> Function(T) urlsOf,
  }) {
    final urls = <String?>[];
    for (final item in items) {
      urls.addAll(urlsOf(item));
    }
    return download(id, urls, label: label, force: force);
  }

  Future<int?> _fetch(String url, CancelToken cancel) async {
    final dir = _dir;
    if (dir == null) return null;

    final name = _nameFor(url);
    final target = File('${dir.path}/$name');
    // Written under a temp name and renamed on success, so an interrupted
    // download can never be mistaken for a complete file later.
    final temp = File('${target.path}.part');

    try {
      await _dio.download(
        url,
        temp.path,
        cancelToken: cancel,
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );
      if (!await temp.exists()) return null;
      final size = await temp.length();
      if (size <= 0) {
        await temp.delete();
        return null;
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);

      final now = DateTime.now().millisecondsSinceEpoch;
      _index[url] = _Entry(file: name, bytes: size, savedAt: now, lastUsed: now);
      MediaAnalytics.instance.downloadOk(bytes: size, url: url);
      if (kDebugMode) debugPrint('[download] $url (${_mb(size)})');
      return size;
    } catch (e) {
      try {
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
      if (cancel.isCancelled) return null;
      MediaAnalytics.instance.downloadFailed(url);
      if (kDebugMode) debugPrint('[download] failed $url: $e');
      return null;
    }
  }

  /// Removes expired files, then the least recently used until the total fits
  /// the budget. Runs after every download and on startup.
  Future<void> sweep() async {
    final dir = _dir;
    if (dir == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - _maxAge.inMilliseconds;

    final expired = _index.entries
        .where((e) => e.value.savedAt < cutoff)
        .map((e) => e.key)
        .toList();
    for (final url in expired) {
      await _remove(url);
    }

    // Least recently used first, because "downloaded longest ago" and "least
    // wanted" are different things — a workout done every morning is old and
    // should be the last thing evicted.
    if (usedBytes > budgetBytes) {
      final byUse = _index.entries.toList()
        ..sort((a, b) => a.value.lastUsed.compareTo(b.value.lastUsed));
      for (final entry in byUse) {
        if (usedBytes <= budgetBytes) break;
        await _remove(entry.key);
      }
    }

    await _cleanOrphans();
    await _persist();
  }

  /// Deletes files on disk the index does not know about — leftovers from an
  /// interrupted write or a wiped index, which would otherwise occupy space
  /// nothing will ever reclaim.
  Future<void> _cleanOrphans() async {
    final dir = _dir;
    if (dir == null) return;
    try {
      final known = _index.values.map((e) => e.file).toSet();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (known.contains(name)) continue;
        await entity.delete();
      }
    } catch (_) {
      // Housekeeping only.
    }
  }

  Future<void> _remove(String url) async {
    final entry = _index.remove(url);
    final dir = _dir;
    if (entry == null || dir == null) return;
    try {
      final file = File('${dir.path}/${entry.file}');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Removes everything. Backs the "clear downloads" control in settings.
  Future<void> clear() async {
    await init();
    for (final url in _index.keys.toList()) {
      await _remove(url);
    }
    await _cleanOrphans();
    await _persist();
    progress.value = null;
  }

  /// Removes one bundle's files without touching anything else.
  Future<void> remove(Iterable<String?> urls) async {
    await init();
    for (final url in urls.whereType<String>()) {
      await _remove(url);
    }
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _box.write(
        _indexKey,
        jsonEncode({for (final e in _index.entries) e.key: e.value.toJson()}),
      );
    } catch (_) {}
  }

  /// Hashed, not derived from the url path: two different assets can share a
  /// basename ("video.mp4" is every clip in this bucket), and the raw url
  /// contains characters no filesystem accepts.
  String _nameFor(String url) {
    final digest = sha1.convert(utf8.encode(url)).toString();
    final dot = url.lastIndexOf('.');
    final slash = url.lastIndexOf('/');
    final ext = (dot > slash && dot > 0 && url.length - dot <= 6)
        ? url.substring(dot).split('?').first
        : '';
    return '$digest$ext';
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// Human-readable size, for a settings row.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return _mb(bytes);
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Every url needed to run one media object with no network.
///
/// Unlike [preloadUrlsFor] this includes the clip itself — offline playback is
/// the entire reason the feature exists.
Iterable<String?> offlineUrlsFor({MediaImage? image, MediaVideo? video}) sync* {
  if (image != null) {
    yield image.thumb;
    yield image.medium ?? image.large;
  }
  if (video != null) {
    yield video.poster;
    yield video.url;
  }
}
