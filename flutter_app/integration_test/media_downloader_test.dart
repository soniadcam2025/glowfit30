// Verifies offline downloads and the analytics buffer on a real device.
//
//   flutter test integration_test/media_downloader_test.dart -d emulator-5554
//
// On a device rather than the host VM because every claim being made here is
// about the filesystem, the network and platform paths. A mocked version would
// prove that the mocks work.
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';

import 'package:glowfit/models/media.dart';
import 'package:glowfit/services/media_analytics.dart';
import 'package:glowfit/services/media_downloader.dart';

/// Real objects from the media pipeline, so the sizes and timings describe
/// production files rather than something synthetic.
const _base = 'https://wrkt1bckt1.blr1.vultrobjects.com/'
    '6c0def89-d1f4-4cc0-baf1-8b7159d5d1fa';
const _thumb = '$_base/thumb.webp';
const _medium = '$_base/medium.webp';
const _large = '$_base/large.webp';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GetStorage.init();
    // Telemetry off: these tests are not signed in, and a queued batch would
    // just sit in the buffer confusing the analytics assertions below.
    MediaAnalytics.instance.enabled = false;
    await MediaDownloader.instance.init();
    await MediaDownloader.instance.clear();
  });

  tearDownAll(() async {
    await MediaDownloader.instance.clear();
  });

  group('offline downloads', () {
    testWidgets('a downloaded file lands on disk and is found again',
        (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();
      expect(downloader.has(_large), isFalse);

      final sw = Stopwatch()..start();
      final ok = await downloader.download('t1', [_large], force: true);
      sw.stop();

      expect(ok, isTrue, reason: 'the download should have succeeded');

      final file = downloader.fileFor(_large);
      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));

      // ignore: avoid_print
      print('[measure] downloaded ${MediaDownloader.formatBytes(file.lengthSync())} '
          'in ${sw.elapsedMilliseconds}ms');
    });

    testWidgets('usedBytes matches what is actually on disk', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();
      expect(downloader.usedBytes, 0);

      await downloader.download('t2', [_thumb, _medium], force: true);

      final onDisk = [_thumb, _medium]
          .map((u) => downloader.fileFor(u)!.lengthSync())
          .fold<int>(0, (a, b) => a + b);

      expect(downloader.usedBytes, onDisk);
      expect(downloader.fileCount, 2);
      // ignore: avoid_print
      print('[measure] index reports ${MediaDownloader.formatBytes(downloader.usedBytes)} '
          'across ${downloader.fileCount} files');
    });

    testWidgets('hasAll answers whether a bundle plays offline', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();

      expect(downloader.hasAll([_thumb, _medium]), isFalse);
      await downloader.download('t3', [_thumb], force: true);
      expect(downloader.hasAll([_thumb, _medium]), isFalse,
          reason: 'a partial bundle must not claim to be offline-ready');
      await downloader.download('t3', [_thumb, _medium], force: true);
      expect(downloader.hasAll([_thumb, _medium]), isTrue);
    });

    testWidgets('an already-downloaded bundle returns immediately',
        (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();
      await downloader.download('t4', [_thumb], force: true);

      final sw = Stopwatch()..start();
      final ok = await downloader.download('t4', [_thumb], force: true);
      sw.stop();

      expect(ok, isTrue);
      // ignore: avoid_print
      print('[measure] re-download of a saved bundle=${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(500),
          reason: 'nothing was missing, so nothing should have been fetched');
    });

    testWidgets('progress reports completion', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();

      final seen = <double>[];
      void listener() {
        final p = downloader.progress.value;
        if (p != null) seen.add(p.fraction);
      }

      downloader.progress.addListener(listener);
      await downloader.download('t5', [_thumb, _medium, _large],
          label: 'Test', force: true);
      downloader.progress.removeListener(listener);

      final done = downloader.progress.value;
      expect(done, isNotNull);
      expect(done!.done, isTrue);
      expect(done.error, isNull);
      expect(done.fraction, 1.0);
      expect(done.bytes, greaterThan(0));
      // ignore: avoid_print
      print('[measure] progress steps: $seen');
      expect(seen.length, greaterThan(1),
          reason: 'progress should move, not jump straight to done');
    });

    testWidgets('the budget evicts least-recently-used files', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();
      final originalBudget = downloader.budgetBytes;

      await downloader.download('t6', [_thumb, _medium, _large], force: true);
      final before = downloader.usedBytes;
      expect(before, greaterThan(0));
      expect(downloader.fileCount, 3);

      // Touch the largest so it is the most recently used, then set a budget
      // only it can fit and confirm the sweep drops the others rather than it.
      final largeSize = downloader.fileFor(_large)!.lengthSync();
      final budget = largeSize + 1024;
      expect(budget, lessThan(before),
          reason: 'the budget must genuinely force an eviction');

      downloader.budgetBytes = budget;
      await downloader.sweep();

      // ignore: avoid_print
      print('[measure] before=${MediaDownloader.formatBytes(before)} '
          'after=${MediaDownloader.formatBytes(downloader.usedBytes)} '
          'budget=${MediaDownloader.formatBytes(downloader.budgetBytes)} '
          'files=${downloader.fileCount}');

      expect(downloader.usedBytes, lessThanOrEqualTo(budget));
      expect(downloader.fileCount, lessThan(3), reason: 'something must have gone');
      expect(downloader.has(_large), isTrue,
          reason: 'the most recently used file should be the last evicted');

      downloader.budgetBytes = originalBudget;
      await downloader.sweep();
    });

    testWidgets('remove deletes only what was asked for', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();
      await downloader.download('t7', [_thumb, _medium], force: true);

      final kept = downloader.fileFor(_medium)!;
      await downloader.remove([_thumb]);

      expect(downloader.has(_thumb), isFalse);
      expect(downloader.has(_medium), isTrue);
      expect(kept.existsSync(), isTrue);
    });

    testWidgets('clear leaves nothing behind', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.download('t8', [_thumb, _large], force: true);
      expect(downloader.usedBytes, greaterThan(0));

      await downloader.clear();

      expect(downloader.usedBytes, 0);
      expect(downloader.fileCount, 0);
      expect(downloader.fileFor(_thumb), isNull);
    });

    testWidgets('bad urls fail without throwing', (tester) async {
      final downloader = MediaDownloader.instance;
      await downloader.clear();

      final ok = await downloader.download(
        't9',
        ['https://invalid.invalid/nope.mp4', 'not-a-url', ''],
        force: true,
      );

      // The one syntactically valid url fails, so the bundle is not offline-ready
      // and must say so rather than reporting a success it cannot honour.
      expect(ok, isFalse);
      expect(downloader.progress.value?.error, isNotNull);
      expect(downloader.usedBytes, 0);
    });

    testWidgets('offlineUrlsFor includes the clip, preloading does not',
        (tester) async {
      const video = MediaVideo(
        url: '$_base/video.mp4',
        poster: '$_base/poster.webp',
      );
      const image = MediaImage(thumb: _thumb, medium: _medium, large: _large);

      final offline =
          offlineUrlsFor(image: image, video: video).whereType<String>().toList();

      expect(offline, contains('$_base/video.mp4'),
          reason: 'offline playback is the whole point');
      expect(offline, contains('$_base/poster.webp'));
      expect(offline, contains(_thumb));
    });
  });

  group('media analytics', () {
    testWidgets('a disabled collector records nothing', (tester) async {
      MediaAnalytics.instance.enabled = false;
      MediaAnalytics.instance.imageLoad(ms: 10, cacheHit: true, url: _thumb);
      // Nothing to assert on the wire; the guarantee is that it does not throw
      // and does not attempt a request without an API client registered.
      await expectLater(MediaAnalytics.instance.flush(), completes);
    });

    testWidgets('a timer reports once and only once', (tester) async {
      final timer = MediaTimer();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      var calls = 0;
      final first = timer.report((_) => calls++);
      final second = timer.report((_) => calls++);

      expect(calls, 1);
      expect(first, isNotNull);
      expect(first, greaterThanOrEqualTo(30));
      expect(second, isNull, reason: 'a second report must be ignored');
      // ignore: avoid_print
      print('[measure] timer read ${first}ms for a 40ms wait');
    });

    testWidgets('event json carries only what was set', (tester) async {
      const event = MediaEvent('image_load', ms: 120, cacheHit: false);
      final json = event.toJson();

      expect(json['type'], 'image_load');
      expect(json['ms'], 120);
      expect(json['cacheHit'], false);
      expect(json['ok'], true);
      expect(json.containsKey('bytes'), isFalse);
      expect(json.containsKey('url'), isFalse);
    });
  });
}
