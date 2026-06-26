class WorkoutModel {
  final String id;
  final String title;
  final String level;
  final int duration;
  final String? imageUrl;
  final String? description;
  final String? goal;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    this.imageUrl,
    this.description,
    this.goal,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> m) => WorkoutModel(
        id:          m['id'] as String,
        title:       m['title'] as String,
        level:       m['level'] as String,
        duration:    (m['duration'] as num).toInt(),
        imageUrl:    m['imageUrl'] as String?,
        description: m['description'] as String?,
        goal:        m['goal'] as String?,
      );
}

class WorkoutDayModel {
  final String id;
  final String workoutId;
  final int dayNumber;
  final String title;
  final String? focus;
  final String? imageUrl;
  final int? durationMinutes;
  final int? kcal;
  final int exerciseCount;

  WorkoutDayModel({
    required this.id,
    required this.workoutId,
    required this.dayNumber,
    required this.title,
    this.focus,
    this.imageUrl,
    this.durationMinutes,
    this.kcal,
    this.exerciseCount = 0,
  });

  factory WorkoutDayModel.fromMap(Map<String, dynamic> m) => WorkoutDayModel(
        id:              m['id'] as String,
        workoutId:       m['workoutId'] as String,
        dayNumber:       (m['dayNumber'] as num).toInt(),
        title:           m['title'] as String,
        focus:           m['focus'] as String?,
        imageUrl:        m['imageUrl'] as String?,
        durationMinutes: (m['durationMinutes'] as num?)?.toInt(),
        kcal:            (m['kcal'] as num?)?.toInt(),
        exerciseCount:   (m['_count']?['exercises'] as num?)?.toInt() ?? 0,
      );
}

class ExerciseModel {
  final String id;
  final String name;
  final int? sets;
  final int? reps;
  final int? duration;
  final int? rest;
  final String? imageUrl;
  final String? gifUrl;
  final String? videoUrl;
  final int order;

  ExerciseModel({
    required this.id,
    required this.name,
    this.sets,
    this.reps,
    this.duration,
    this.rest,
    this.imageUrl,
    this.gifUrl,
    this.videoUrl,
    this.order = 0,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> m) => ExerciseModel(
        id:       m['id'] as String,
        name:     m['name'] as String,
        sets:     (m['sets'] as num?)?.toInt(),
        reps:     (m['reps'] as num?)?.toInt(),
        duration: (m['duration'] as num?)?.toInt(),
        rest:     (m['rest'] as num?)?.toInt(),
        imageUrl: m['imageUrl'] as String?,
        gifUrl:   m['gifUrl'] as String?,
        videoUrl: m['videoUrl'] as String?,
        order:    (m['order'] as num?)?.toInt() ?? 0,
      );

  int get durationSeconds => duration ?? (reps != null ? reps! * 3 : 30);
}
