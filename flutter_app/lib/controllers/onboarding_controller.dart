import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_profile.dart';
import '../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final _box = GetStorage();

  static const _keyStep     = 'onboarding_step';
  static const _keyComplete = 'onboarding_complete';
  static const _keyProfile  = 'onboarding_profile';

  final profile     = UserProfile().obs;
  final currentStep = 1.obs;
  final totalSteps  = 14.obs;

  UserProfile get userProfile => profile.value;
  bool get isComplete => _box.read<bool>(_keyComplete) ?? false;

  @override
  void onInit() {
    super.onInit();
    _restoreProgress();
  }

  void _restoreProgress() {
    final saved = _box.read<Map>(_keyProfile);
    if (saved != null) {
      profile.value = UserProfile.fromMap(Map<String, dynamic>.from(saved));
    }
    currentStep.value = _box.read<int>(_keyStep) ?? 1;
  }

  void _saveProgress() {
    _box.write(_keyStep, currentStep.value);
    _box.write(_keyProfile, profile.value.toMap());
  }

  void clearProgress() {
    _box.remove(_keyStep);
    _box.remove(_keyComplete);
    _box.remove(_keyProfile);
    profile.value = UserProfile();
    currentStep.value = 1;
  }

  // ── Saved step → route name ───────────────────────────────────────────────
  static const _steps = [
    Routes.language,
    Routes.motivation,
    Routes.mainGoal,
    Routes.focusArea,
    Routes.name,
    Routes.age,
    Routes.height,
    Routes.weightCurrent,
    Routes.weightTarget,
    Routes.healthIssues,
    Routes.activityLevel,
    Routes.fitnessLevel,
    Routes.dietStyle,
    Routes.beautyGoals,
    Routes.welcome,
    Routes.home,
  ];

  String get resumeRoute {
    final step = (_box.read<int>(_keyStep) ?? 1) - 1;
    if (step < 0 || step >= _steps.length) return Routes.language;
    return _steps[step];
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void selectLanguage(String lang) {
    profile.value.language = lang;
    profile.refresh();
    update();
    _saveProgress();
  }

  void toggleMotivation(String motivation) {
    final list = List<String>.from(profile.value.motivations);
    if (list.contains(motivation)) {
      list.remove(motivation);
    } else if (list.length < 2) {
      list.add(motivation);
    }
    profile.value.motivations = list;
    profile.refresh();
    update();
    _saveProgress();
  }

  void toggleFocusArea(String area) {
    final list = List<String>.from(profile.value.focusAreas);
    if (list.contains(area)) {
      list.remove(area);
    } else if (list.length < 3) {
      list.add(area);
    }
    profile.value.focusAreas = list;
    profile.refresh();
    update();
    _saveProgress();
  }

  void setMainGoalSelection(String goal) {
    profile.value.mainGoal = goal;
    profile.refresh();
    update();
    _saveProgress();
  }

  void setLanguage(String lang) {
    profile.value.language = lang;
    profile.refresh();
    _goNext();
  }

  void setMotivations(List<String> motivations) {
    profile.value.motivations = motivations;
    profile.refresh();
    _goNext();
  }

  void setMainGoal(String goal) {
    profile.value.mainGoal = goal;
    profile.refresh();
    _goNext();
  }

  void setFocusAreas(List<String> areas) {
    profile.value.focusAreas = areas;
    profile.refresh();
    _goNext();
  }

  void setName(String name) {
    profile.value.name = name;
    profile.refresh();
    _goNext();
  }

  void setAge(int age) {
    profile.value.age = age;
    profile.refresh();
    _goNext();
  }

  void setHeight(int? cm, int? ft, int? inches) {
    profile.value.heightCm = cm;
    profile.value.heightFt = ft;
    profile.value.heightIn = inches;
    profile.refresh();
    _goNext();
  }

  void setCurrentWeight(double weight) {
    profile.value.currentWeight = weight;
    profile.refresh();
    _goNext();
  }

  void setTargetWeight(double weight) {
    profile.value.targetWeight = weight;
    profile.refresh();
    _goNext();
  }

  void setHealthIssues(List<String> issues) {
    profile.value.healthIssues = issues;
    profile.refresh();
    _goNext();
  }

  void setActivityLevel(String level) {
    profile.value.activityLevel = level;
    profile.refresh();
    _goNext();
  }

  void setFitnessLevel(String level) {
    profile.value.fitnessLevel = level;
    profile.refresh();
    _goNext();
  }

  void setDietStyle(String style) {
    profile.value.dietStyle = style;
    profile.refresh();
    _goNext();
  }

  void setBeautyGoals(List<String> goals) {
    profile.value.beautyGoals = goals;
    profile.refresh();
    _goNext();
  }

  void nextStep() {
    if (userProfile.language != null) {
      setLanguage(userProfile.language!);
    }
  }

  void _goNext() {
    if (currentStep.value < _steps.length) {
      currentStep.value++;
      _saveProgress();

      final next = _steps[currentStep.value - 1];
      if (next == Routes.home) {
        _box.write(_keyComplete, true);
        Get.offAllNamed(Routes.home);
      } else if (next == Routes.welcome) {
        Get.toNamed(next);
      } else {
        Get.toNamed(next);
      }
    }
  }

  void completeOnboarding() {
    _box.write(_keyComplete, true);
    Get.offAllNamed(Routes.home);
  }

  void goBack() {
    if (currentStep.value > 1) {
      currentStep.value--;
      _saveProgress();
      Get.back();
    }
  }
}
