import 'package:flutter/foundation.dart' show kDebugMode;

class AppConstants {
  AppConstants._();

  // API Configuration
  // Debug builds hit the local API via 10.0.2.2 (the Android emulator's route to the
  // host machine's localhost). Release builds always hit production.
  static const String baseUrl =
      kDebugMode ? 'http://10.0.2.2:4000/api' : 'https://api.glowfit30.com/api';
  static const String apiTimeout = '30000';
  static const int maxRetries = 3;
  static const int retryDelay = 1000;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userLanguageKey = 'user_language';
  static const String userCategoriesKey = 'user_categories';
  static const String userPreferencesKey = 'user_preferences';
  static const String isDarkThemeKey = 'is_dark_theme';
  static const String isOnboardedKey = 'is_onboarded';

  // App Info
  static const String appName = 'GlowFit';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Default Values
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'hi', 'bn', 'es', 'pt'];
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);

  // Pagination
  static const int pageSize = 20;
  static const int initialLoadSize = 10;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 800);

  // Cache Durations
  static const Duration contentCacheDuration = Duration(hours: 6);
  static const Duration userCacheDuration = Duration(hours: 24);
}
