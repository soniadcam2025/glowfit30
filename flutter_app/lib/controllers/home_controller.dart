import 'package:get/get.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  // User
  final userName     = ''.obs;
  final photoUrl     = ''.obs;

  // Progress
  final streak       = 0.obs;
  final currentDay   = 1.obs;
  final totalDays    = 30.obs;
  final todayKcal    = 0.obs;
  final todayMinutes = 0.obs;
  final completedDayIds = <String>[].obs;

  // Active workout
  final workoutId    = ''.obs;
  final workoutTitle = 'Full Body Fat Burn'.obs;
  final workoutLevel = 'Beginner'.obs;
  final goalText     = 'WEIGHT LOSS'.obs;
  final exerciseCount = 0.obs;

  // UI state
  final isLoading = true.obs;
  final hasError  = false.obs;

  double get progressPercent =>
      totalDays.value > 0 ? currentDay.value / totalDays.value : 0;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading(true);
    hasError(false);

    try {
      final api = Get.find<ApiService>();

      final results = await Future.wait([
        api.getProfile(),
        api.getProgress(),
        api.getWorkouts(),
      ]);

      final profile  = results[0] as Map<String, dynamic>?;
      final progress = results[1] as Map<String, dynamic>?;
      final workouts = results[2] as List<dynamic>;

      if (profile != null) {
        userName(profile['name'] as String? ?? '');
        photoUrl(profile['photoUrl'] as String? ?? '');
        final goal = profile['goal'] as String? ?? 'Loss weight';
        goalText(_goalToDisplay(goal));
      }

      if (progress != null) {
        final stats = progress['stats'] as Map<String, dynamic>? ?? {};
        streak((stats['streak'] as num?)?.toInt() ?? 0);
        final sessions = (stats['totalSessions'] as num?)?.toInt() ?? 0;
        currentDay(sessions + 1);
        todayKcal((stats['totalCalories'] as num?)?.toInt() ?? 0);
        todayMinutes((stats['totalMinutes'] as num?)?.toInt() ?? 0);

        final completions = progress['completions'] as List<dynamic>? ?? [];
        completedDayIds.value = completions
            .map((c) => (c as Map<String, dynamic>)['workoutDayId'] as String)
            .toList();
      }

      if (workouts.isNotEmpty) {
        final userGoal = profile?['goal'] as String?;
        Map<String, dynamic>? match;
        if (userGoal != null) {
          match = workouts
              .cast<Map<String, dynamic>>()
              .firstWhereOrNull((w) => w['goal'] == userGoal);
        }
        final w = (match ?? workouts.first) as Map<String, dynamic>;
        workoutId(w['id'] as String);
        workoutTitle(w['title'] as String? ?? workoutTitle.value);
        workoutLevel(w['level'] as String? ?? workoutLevel.value);

        final daysData = await api.getWorkoutDays(workoutId.value);
        final days = daysData?['days'] as List<dynamic>? ?? [];
        exerciseCount(days.fold<int>(
          0,
          (sum, d) =>
              sum + (((d as Map)['_count']?['exercises'] as num?)?.toInt() ?? 0),
        ));
      }
    } catch (_) {
      hasError(true);
    } finally {
      isLoading(false);
    }
  }

  String _goalToDisplay(String goal) {
    const map = {
      'Loss weight':   'WEIGHT LOSS',
      'Lift & tone':   'LIFT & TONE',
      'Lose belly fat':'BELLY FAT LOSS',
      'Build muscles': 'BUILD MUSCLES',
    };
    return map[goal] ?? goal.toUpperCase();
  }
}
