import 'package:get/get.dart';
import '../features/home/home_screen.dart';
import '../features/diet/diet_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/motivation_screen.dart';
import '../features/onboarding/main_goal_screen.dart';
import '../features/onboarding/focus_area_screen.dart';
import '../features/onboarding/name_screen.dart';
import '../features/onboarding/age_screen.dart';
import '../features/onboarding/height_screen.dart';
import '../features/onboarding/weight_current_screen.dart';
import '../features/onboarding/weight_target_screen.dart';
import '../features/onboarding/health_issues_screen.dart';
import '../features/onboarding/activity_level_screen.dart';
import '../features/onboarding/fitness_level_screen.dart';
import '../features/onboarding/diet_style_screen.dart';
import '../features/onboarding/beauty_goals_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../bindings/onboarding_binding.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final pages = [
    GetPage(name: Routes.splash,        page: () => const SplashScreen(),        transition: Transition.fadeIn),
    GetPage(name: Routes.home,          page: () => const HomeScreen(),           transition: Transition.fadeIn),
    GetPage(name: Routes.diet,          page: () => const DietScreen(),           transition: Transition.rightToLeft),
    GetPage(name: Routes.welcome,       page: () => const WelcomeScreen(),        binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.language,      page: () => const LanguageScreen(),       binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.motivation,    page: () => const MotivationScreen(),     binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.mainGoal,      page: () => const MainGoalScreen(),       binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.focusArea,     page: () => const FocusAreaScreen(),      binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.name,          page: () => const NameScreen(),           binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.age,           page: () => const AgeScreen(),            binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.height,        page: () => const HeightScreen(),         binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.weightCurrent, page: () => const WeightCurrentScreen(),  binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.weightTarget,  page: () => const WeightTargetScreen(),   binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.healthIssues,  page: () => const HealthIssuesScreen(),   binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.activityLevel, page: () => const ActivityLevelScreen(),  binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.fitnessLevel,  page: () => const FitnessLevelScreen(),   binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.dietStyle,     page: () => const DietStyleScreen(),      binding: OnboardingBinding(), transition: Transition.rightToLeft),
    GetPage(name: Routes.beautyGoals,   page: () => const BeautyGoalsScreen(),    binding: OnboardingBinding(), transition: Transition.rightToLeft),
  ];
}

abstract class Routes {
  static const splash        = '/splash';
  static const home          = '/home';
  static const diet          = '/diet';
  static const welcome       = '/welcome';
  static const language      = '/language';
  static const motivation    = '/motivation';
  static const mainGoal      = '/mainGoal';
  static const focusArea     = '/focusArea';
  static const name          = '/name';
  static const age           = '/age';
  static const height        = '/height';
  static const weightCurrent = '/weightCurrent';
  static const weightTarget  = '/weightTarget';
  static const healthIssues  = '/healthIssues';
  static const activityLevel = '/activityLevel';
  static const fitnessLevel  = '/fitnessLevel';
  static const dietStyle     = '/dietStyle';
  static const beautyGoals   = '/beautyGoals';
}
