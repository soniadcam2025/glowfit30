class Routes {
  Routes._();

  // Splash & Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Onboarding
  static const String onboarding = '/onboarding';
  static const String languageSelection = '/language-selection';
  static const String categorySelection = '/category-selection';
  static const String preferencesSetup = '/preferences-setup';

  // Main Navigation
  static const String home = '/home';
  static const String workout = '/workout';
  static const String search = '/search';
  static const String shorts = '/shorts';
  static const String profile = '/profile';

  // Details & Sub-screens
  static const String contentDetail = '/content/:id';
  static const String workoutDetail = '/workout/:id';
  static const String activeWorkout = '/workout/active/:id';
  static const String challengeDetail = '/challenge/:id';
  static const String solutions = '/solutions';
  static const String premium = '/premium';
  static const String settings = '/settings';

  // Screens with parameters
  static String contentDetailPage(String id) => '/content/$id';
  static String workoutDetailPage(String id) => '/workout/$id';
  static String activeWorkoutPage(String id) => '/workout/active/$id';
  static String challengeDetailPage(String id) => '/challenge/$id';
}
