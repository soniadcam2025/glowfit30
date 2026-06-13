class UserProfile {
  String? language;
  List<String> motivations = [];
  String? mainGoal;
  List<String> focusAreas = [];
  String? name;
  int? age;
  int? heightCm;
  int? heightFt;
  int? heightIn;
  double? currentWeight;
  double? targetWeight;
  List<String> healthIssues = [];
  String? activityLevel;
  String? fitnessLevel;
  String? dietStyle;
  List<String> beautyGoals = [];

  static UserProfile fromMap(Map<String, dynamic> map) {
    final p = UserProfile();
    p.language      = map['language'] as String?;
    p.motivations   = List<String>.from(map['motivations'] ?? []);
    p.mainGoal      = map['mainGoal'] as String?;
    p.focusAreas    = List<String>.from(map['focusAreas'] ?? []);
    p.name          = map['name'] as String?;
    p.age           = map['age'] as int?;
    p.heightCm      = map['heightCm'] as int?;
    p.heightFt      = map['heightFt'] as int?;
    p.heightIn      = map['heightIn'] as int?;
    p.currentWeight = map['currentWeight'] as double?;
    p.targetWeight  = map['targetWeight'] as double?;
    p.healthIssues  = List<String>.from(map['healthIssues'] ?? []);
    p.activityLevel = map['activityLevel'] as String?;
    p.fitnessLevel  = map['fitnessLevel'] as String?;
    p.dietStyle     = map['dietStyle'] as String?;
    p.beautyGoals   = List<String>.from(map['beautyGoals'] ?? []);
    return p;
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'motivations': motivations,
      'mainGoal': mainGoal,
      'focusAreas': focusAreas,
      'name': name,
      'age': age,
      'heightCm': heightCm,
      'heightFt': heightFt,
      'heightIn': heightIn,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'healthIssues': healthIssues,
      'activityLevel': activityLevel,
      'fitnessLevel': fitnessLevel,
      'dietStyle': dietStyle,
      'beautyGoals': beautyGoals,
    };
  }
}
