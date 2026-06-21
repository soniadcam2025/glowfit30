import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class NotificationService extends GetxService {
  final _fcm = FirebaseMessaging.instance;

  static const _channelId = 'glowfit_notifications';

  @override
  Future<void> onInit() async {
    super.onInit();
    await _requestPermission();
    await _setAndroidForegroundOptions();
    _setupForegroundHandler();
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  /// Show heads-up notifications while app is in foreground on Android
  Future<void> _setAndroidForegroundOptions() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        Get.snackbar(
          notification.title ?? 'GlowFit',
          notification.body ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF7C3AED),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          icon: const Icon(Icons.fitness_center, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    });

    // Notification tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification tapped: ${message.data}');
      // Navigate based on data payload if needed in future
    });
  }

  /// Call this after the user successfully logs in and has a JWT stored.
  Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final api = Get.find<ApiService>();
      await api.saveFcmToken(token);

      _fcm.onTokenRefresh.listen((newToken) async {
        await api.saveFcmToken(newToken);
      });
    } catch (_) {
      // Non-fatal
    }
  }

  static String get channelId => _channelId;
}
