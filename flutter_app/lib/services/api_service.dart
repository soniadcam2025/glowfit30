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
}
