import 'package:get/get.dart';
import '../core/network/api_client.dart';

class ApiService extends GetxService {
  final ApiClient _client = Get.find<ApiClient>();

  dynamic _data(dynamic response) {
    try {
      final body = response.data as Map<String, dynamic>;
      return body['data'];
    } catch (_) {
      return null;
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> firebaseAuth(String idToken) async {
    try {
      final r = await _client.post('/auth/firebase', data: {'idToken': idToken});
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final r = await _client.get('/profile');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['profile'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFcmToken(String token) async {
    try {
      await _client.patch('/profile/fcm-token', data: {'fcmToken': token});
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> patchProfile(Map<String, dynamic> data) async {
    try {
      final r = await _client.patch('/profile', data: data);
      final d = _data(r) as Map<String, dynamic>?;
      return d?['profile'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Workouts ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getWorkouts() async {
    try {
      final r = await _client.get('/workouts');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['items'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getWorkoutDays(String workoutId) async {
    try {
      final r = await _client.get('/workouts/$workoutId/days');
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDayExercises(String dayId) async {
    try {
      final r = await _client.get('/workouts/days/$dayId/exercises');
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Workout Library ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getWorkoutLibraryItems({
    String? category,
    bool? featured,
  }) async {
    try {
      final query = <String, dynamic>{
        if (category != null) 'category': category,
        if (featured != null) 'featured': '$featured',
      };
      final r = await _client.get(
        '/workout-library',
        queryParameters: query.isEmpty ? null : query,
      );
      final d = _data(r) as Map<String, dynamic>?;
      return d?['items'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getWorkoutLibraryCategories() async {
    try {
      final r = await _client.get('/workout-library/categories');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['categories'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getWorkoutLibraryCategory(String name) async {
    try {
      final r = await _client.get('/workout-library/categories');
      final d = _data(r) as Map<String, dynamic>?;
      final categories = d?['categories'] as List<dynamic>? ?? [];
      return categories.cast<Map<String, dynamic>?>().firstWhere(
            (c) => (c?['name'] as String?)?.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWorkoutLibraryItem(String id) async {
    try {
      final r = await _client.get('/workout-library/$id');
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Glow ──────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGlowCategories() async {
    try {
      final r = await _client.get('/glow/categories');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['categories'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getGlowReads() async {
    try {
      final r = await _client.get('/beauty');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['items'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getGlowShorts() async {
    try {
      final r = await _client.get('/glow/shorts');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['shorts'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Progress ─────────────────────────────────────────────────────────────────

  Future<bool> logProgress({
    required String workoutDayId,
    int? caloriesBurned,
    int? durationMin,
  }) async {
    try {
      await _client.post('/progress', data: {
        'workoutDayId': workoutDayId,
        if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
        if (durationMin != null) 'durationMin': durationMin,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProgress() async {
    try {
      final r = await _client.get('/progress');
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Diet ─────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getDietPlans() async {
    try {
      final r = await _client.get('/diet');
      final d = _data(r) as Map<String, dynamic>?;
      return d?['items'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Server-resolved diet for the given program day: picks the plan matching
  /// the user's diet style and returns that day's meals (cycling through the
  /// configured days when the program is longer than the meal rotation).
  Future<Map<String, dynamic>?> getDietToday(int day) async {
    try {
      final r = await _client.get('/diet/today?day=$day');
      return _data(r) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
