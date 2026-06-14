import 'package:get/get.dart';
import '../models/workout_model.dart';
import '../services/api_service.dart';

enum DayStatus { completed, inProgress, locked }

class WorkoutDayState {
  final WorkoutDayModel day;
  final DayStatus status;
  final double progress;

  const WorkoutDayState({
    required this.day,
    required this.status,
    this.progress = 0,
  });
}

class WorkoutController extends GetxController {
  final activeWorkout   = Rxn<WorkoutModel>();
  final dayStates       = <WorkoutDayState>[].obs;
  final completedCount  = 0.obs;
  final totalDays       = 0.obs;
  final isLoading       = true.obs;
  final hasError        = false.obs;

  // Exercises for currently opened day
  final dayExercises = <ExerciseModel>[].obs;
  final loadingExercises = false.obs;

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
        api.getWorkouts(),
        api.getProgress(),
      ]);

      final workouts = results[0] as List<dynamic>;
      final progress = results[1] as Map<String, dynamic>?;

      if (workouts.isEmpty) return;

      // Pick first workout (or match by user goal — controller keeps it simple)
      final w = WorkoutModel.fromMap(workouts.first as Map<String, dynamic>);
      activeWorkout.value = w;

      // Build set of completed day IDs
      final completions = progress?['completions'] as List<dynamic>? ?? [];
      final completedIds = completions
          .map((c) => (c as Map<String, dynamic>)['workoutDayId'] as String)
          .toSet();

      completedCount(completedIds.length);

      // Fetch days for this workout
      final daysData = await api.getWorkoutDays(w.id);
      final rawDays  = daysData?['days'] as List<dynamic>? ?? [];

      totalDays(rawDays.length);

      final states = <WorkoutDayState>[];
      bool foundInProgress = false;

      for (final raw in rawDays) {
        final day = WorkoutDayModel.fromMap(raw as Map<String, dynamic>);

        DayStatus status;
        if (completedIds.contains(day.id)) {
          status = DayStatus.completed;
        } else if (!foundInProgress) {
          status = DayStatus.inProgress;
          foundInProgress = true;
        } else {
          status = DayStatus.locked;
        }

        states.add(WorkoutDayState(day: day, status: status));
      }

      dayStates.value = states;
    } catch (_) {
      hasError(true);
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadExercises(String dayId) async {
    loadingExercises(true);
    dayExercises.clear();
    try {
      final api  = Get.find<ApiService>();
      final data = await api.getDayExercises(dayId);
      final raw  = data?['exercises'] as List<dynamic>? ?? [];
      dayExercises.value =
          raw.map((e) => ExerciseModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // keep empty list; screen shows fallback
    } finally {
      loadingExercises(false);
    }
  }
}
