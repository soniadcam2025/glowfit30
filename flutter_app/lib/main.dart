import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import 'services/media_analytics.dart';
import 'services/media_downloader.dart';
import 'services/workout_audio_settings.dart';
import 'widgets/exercise_video_player.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM handles display automatically in background/terminated state on Android/iOS
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize GetStorage
  await GetStorage.init();

  // Straight after the box opens, so the first clip already plays at the
  // volume the user chose rather than starting loud and correcting itself.
  WorkoutAudioSettings.instance.load();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Loads the offline index and sweeps expired downloads. Awaited because
  // GlowImage asks it for local files during the very first frame, and a
  // half-loaded index would make downloaded media look missing.
  await MediaDownloader.instance.init();

  MediaAnalytics.instance.platform = defaultTargetPlatform.name;

  runApp(const GlowFitApp());
}

class GlowFitApp extends StatefulWidget {
  const GlowFitApp({super.key});

  @override
  State<GlowFitApp> createState() => _GlowFitAppState();
}

class _GlowFitAppState extends State<GlowFitApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Backgrounding is the last reliable moment to send what was measured — a
  /// process that is killed from the background never gets another chance.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      MediaAnalytics.instance.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GlowFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      // Lets a video pause itself the moment a screen is pushed over it. Without
      // this the decoder keeps running behind the rest screen and starves the
      // isolate that drives its countdown.
      navigatorObservers: [videoRouteObserver],
      defaultTransition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
