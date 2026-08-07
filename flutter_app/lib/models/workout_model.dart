import 'media.dart';

/// Workout content.
///
/// Each model keeps its raw `imageUrl` string *and* the API's media object.
/// The string is what most of these screens still read and what older API
/// responses carry; [image] is present only once an endpoint has been through
/// the media pipeline. Keeping both means a screen can be moved over one at a
/// time instead of all at once.
class WorkoutModel {
  final String id;
  final String title;
  final String level;
  final int duration;
  final String? imageUrl;
  final MediaImage? image;
  final String? description;
  final String? goal;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    this.imageUrl,
    this.image,
    this.description,
    this.goal,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> m) => WorkoutModel(
        id:          m['id'] as String,
        title:       m['title'] as String,
        level:       m['level'] as String,
        duration:    (m['duration'] as num).toInt(),
        imageUrl:    m['imageUrl'] as String?,
        image:       MediaImage.read(m),
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
  final MediaImage? image;
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
    this.image,
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
        image:           MediaImage.read(m),
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
  final MediaImage? image;

  /// Poster frame and dimensions for [videoUrl]. The poster is what lets the
  /// player show something the instant the exercise appears, instead of a black
  /// rectangle while the clip opens.
  final MediaVideo? video;

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
    this.image,
    this.video,
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
        image:    MediaImage.read(m),
        video:    MediaVideo.read(m),
        order:    (m['order'] as num?)?.toInt() ?? 0,
      );

  /// What the player counts down for this exercise.
  ///
  /// `duration` is required by the API, so anything authored since the move to
  /// a time-driven player has one. Exercises created before that do not, and
  /// the column stays nullable rather than being backfilled with a guessed
  /// number — so estimate here instead: three seconds a rep, or 30 seconds when
  /// there is nothing at all to go on. An admin opening the exercise replaces
  /// the estimate with a real value.
  int get durationSeconds => duration ?? (reps != null ? reps! * 3 : 30);

  /// How long to rest after this exercise before the next one.
  ///
  /// Zero is a real answer — it means "go straight on" — so this only falls
  /// back when the value is genuinely absent, which again means a row authored
  /// before rest was required.
  int get restSeconds => rest ?? 20;
}
