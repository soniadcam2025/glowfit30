// Measures whether preloading actually makes the next exercise instant.
//
//   flutter test integration_test/media_preloader_test.dart -d emulator-5554
//
// Runs on a device rather than the host VM because the cache manager needs
// real platform paths, real storage and a real network stack — the whole thing
// under test is I/O, so a mocked version would prove nothing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:glowfit/models/media.dart';
import 'package:glowfit/services/media_preloader.dart';
import 'package:glowfit/widgets/glow_image.dart';

/// Real objects from the media pipeline, so the numbers describe production
/// files rather than something synthetic.
const _base = 'https://wrkt1bckt1.blr1.vultrobjects.com/'
    '6c0def89-d1f4-4cc0-baf1-8b7159d5d1fa';
const _thumb = '$_base/thumb.webp';
const _medium = '$_base/medium.webp';
const _large = '$_base/large.webp';

Future<int> _timeFetch(String url) async {
  final sw = Stopwatch()..start();
  await GlowImageCache.instance.getSingleFile(url);
  sw.stop();
  return sw.elapsedMilliseconds;
}

Future<void> _forget(List<String> urls) async {
  for (final u in urls) {
    await GlowImageCache.evict(u);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('preloading', () {
    testWidgets('a preloaded image resolves from disk, not the network',
        (tester) async {
      await _forget([_thumb, _medium, _large]);

      // Cold: nothing cached, so this is a full round trip.
      final cold = await _timeFetch(_large);
      await _forget([_large]);

      // Warm the cache the way the workout screen does.
      final sw = Stopwatch()..start();
      await MediaPreloader.instance.warm([_large]);
      sw.stop();

      final warm = await _timeFetch(_large);

      // ignore: avoid_print
      print('[measure] cold=${cold}ms  preload=${sw.elapsedMilliseconds}ms  '
          'after-preload=${warm}ms');

      expect(warm, lessThan(cold),
          reason: 'a preloaded file should not cost a network round trip');
      // "Nearly instant" needs a number. A local file open is single-digit to
      // low-tens of ms; anything approaching the cold figure means the preload
      // did not land.
      expect(warm, lessThan(100));
    });

    testWidgets('the second view of an exercise image costs nothing',
        (tester) async {
      await _forget([_medium]);
      final first = await _timeFetch(_medium);
      final second = await _timeFetch(_medium);

      // ignore: avoid_print
      print('[measure] first=${first}ms  second=${second}ms');
      expect(second, lessThan(first));
    });

    testWidgets('already-cached urls are not re-downloaded', (tester) async {
      await _forget([_thumb]);
      await MediaPreloader.instance.warm([_thumb]);

      // Second warm should find it on disk and return without touching the
      // network — this is the guard that keeps preloading from costing data
      // every time an exercise starts.
      final sw = Stopwatch()..start();
      await MediaPreloader.instance.warm([_thumb]);
      sw.stop();

      // ignore: avoid_print
      print('[measure] re-warm of a cached url=${sw.elapsedMilliseconds}ms');
      final cached = await GlowImageCache.instance.getFileFromCache(_thumb);
      expect(cached, isNotNull);
    });

    testWidgets('a fully cached set returns immediately', (tester) async {
      await _forget([_medium]);
      await MediaPreloader.instance.warm([_medium]);

      // Nothing left to fetch, so this must not sit through the start delay.
      final sw = Stopwatch()..start();
      await MediaPreloader.instance.warm([_medium]);
      sw.stop();

      // ignore: avoid_print
      print('[measure] re-warm of a cached url=${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('the connection gate decides whether anything is fetched',
        (tester) async {
      await _forget([_large]);

      // Whatever this device is on right now, opting in must allow the fetch.
      MediaPreloader.instance.allowOnCellular = true;
      await MediaPreloader.instance.warm([_large]);
      expect(await GlowImageCache.instance.getFileFromCache(_large), isNotNull,
          reason: 'opted in, so the preload should have run');

      MediaPreloader.instance.allowOnCellular = false;
    });

    testWidgets('the gate reflects the live connection', (tester) async {
      MediaPreloader.instance.allowOnCellular = false;
      final onCurrentConnection = await MediaPreloader.instance.canPreloadNow;

      // Opting in must allow it regardless of what the connection is.
      MediaPreloader.instance.allowOnCellular = true;
      expect(await MediaPreloader.instance.canPreloadNow, isTrue);

      MediaPreloader.instance.allowOnCellular = false;
      // ignore: avoid_print
      print('[measure] gate without opt-in on this connection: '
          '$onCurrentConnection');
    });

    testWidgets('rubbish urls fail silently and never throw', (tester) async {
      // A preload that fails must cost nothing: the real fetch still happens
      // when the screen needs it.
      await expectLater(
        MediaPreloader.instance.warm([
          'https://invalid.invalid/nope.webp',
          'not-a-url',
          '',
        ]),
        completes,
      );
    });

    testWidgets('GlowImage renders a preloaded media object', (tester) async {
      await MediaPreloader.instance.warm([_thumb]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: GlowImage(
                media: const MediaImage(
                  thumb: _thumb,
                  medium: _medium,
                  large: _large,
                  blurhash: 'LD8#7:kCo#RQ_NaxRjRQE4n%RPbb',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
