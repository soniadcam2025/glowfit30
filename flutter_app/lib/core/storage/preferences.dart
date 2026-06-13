import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class Preferences {
  final GetStorage _getStorage = GetStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============================================
  // Authentication Tokens
  // ============================================

  /// Set access token (stored securely)
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  /// Get access token
  Future<String> getAccessToken() async {
    return await _secureStorage.read(
          key: AppConstants.accessTokenKey,
        ) ??
        '';
  }

  /// Set refresh token (stored securely)
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

  /// Get refresh token
  Future<String> getRefreshToken() async {
    return await _secureStorage.read(
          key: AppConstants.refreshTokenKey,
        ) ??
        '';
  }

  /// Clear authentication tokens
  Future<void> clearAuthTokens() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  /// Check if token exists
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token.isNotEmpty;
  }

  // ============================================
  // User Preferences
  // ============================================

  /// Set user language
  Future<void> setUserLanguage(String language) async {
    await _getStorage.write(AppConstants.userLanguageKey, language);
  }

  /// Get user language
  String getUserLanguage() {
    return _getStorage.read(AppConstants.userLanguageKey) ?? AppConstants.defaultLanguage;
  }

  /// Set user categories
  Future<void> setUserCategories(List<String> categories) async {
    await _getStorage.write(AppConstants.userCategoriesKey, categories);
  }

  /// Get user categories
  List<String> getUserCategories() {
    final categories = _getStorage.read(AppConstants.userCategoriesKey);
    if (categories is List) {
      return List<String>.from(categories);
    }
    return [];
  }

  /// Set user preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    await _getStorage.write(AppConstants.userPreferencesKey, preferences);
  }

  /// Get user preferences
  Map<String, dynamic> getUserPreferences() {
    return _getStorage.read(AppConstants.userPreferencesKey) ?? {};
  }

  /// Check if user is onboarded
  bool isOnboarded() {
    return _getStorage.read(AppConstants.isOnboardedKey) ?? false;
  }

  /// Set onboarded status
  Future<void> setOnboarded(bool value) async {
    await _getStorage.write(AppConstants.isOnboardedKey, value);
  }

  // ============================================
  // Theme Preferences
  // ============================================

  /// Set dark theme preference
  Future<void> setDarkTheme(bool isDark) async {
    await _getStorage.write(AppConstants.isDarkThemeKey, isDark);
  }

  /// Get dark theme preference
  bool isDarkTheme() {
    return _getStorage.read(AppConstants.isDarkThemeKey) ?? true;
  }

  // ============================================
  // General Storage Methods
  // ============================================

  /// Write value
  Future<void> write(String key, dynamic value) async {
    await _getStorage.write(key, value);
  }

  /// Read value
  T? read<T>(String key) {
    return _getStorage.read(key) as T?;
  }

  /// Read value with default
  T readWithDefault<T>(String key, T defaultValue) {
    return _getStorage.read(key) ?? defaultValue;
  }

  /// Remove value
  Future<void> remove(String key) async {
    await _getStorage.remove(key);
  }

  /// Clear all data
  Future<void> clear() async {
    await _getStorage.erase();
    await _secureStorage.deleteAll();
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _getStorage.hasData(key);
  }

  /// Get all keys
  List<String> getAllKeys() {
    return _getStorage.getKeys().toList();
  }

  // ============================================
  // Logout (Clear everything)
  // ============================================

  /// Complete logout
  Future<void> logout() async {
    await clear();
    await setOnboarded(false);
    await setUserLanguage(AppConstants.defaultLanguage);
  }
}
