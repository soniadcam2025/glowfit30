import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../services/api_service.dart';

class MealSlot {
  final String type;
  final String label;
  final String time;
  final String desc;
  final int kcal;
  final String image;
  final String emoji;

  const MealSlot({
    required this.type,
    required this.label,
    required this.time,
    required this.desc,
    required this.kcal,
    required this.image,
    required this.emoji,
  });

  factory MealSlot.fromJson(Map<String, dynamic> j) => MealSlot(
        type: j['type'] as String? ?? '',
        label: j['label'] as String? ?? '',
        time: j['time'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        kcal: (j['kcal'] as num?)?.toInt() ?? 0,
        image: j['image'] as String? ?? _imageForType(j['type'] as String? ?? ''),
        emoji: _emojiForType(j['type'] as String? ?? ''),
      );

  static String _imageForType(String type) {
    const map = {
      'breakfast':   'assets/images/diet_breakfast.png',
      'mid_morning': 'assets/images/diet_mid_morning.png',
      'lunch':       'assets/images/diet_lunch.png',
      'snack':       'assets/images/diet_snack.png',
      'dinner':      'assets/images/diet_dinner.png',
    };
    return map[type] ?? 'assets/images/diet_breakfast.png';
  }

  static String _emojiForType(String type) {
    const map = {
      'breakfast':   '☀️',
      'mid_morning': '☕',
      'lunch':       '🍛',
      'snack':       '🥗',
      'dinner':      '🍽️',
    };
    return map[type] ?? '🍴';
  }
}

class DietController extends GetxController {
  final dietStyle   = 'Vegetarian'.obs;
  final goal        = 'Weight Loss'.obs;
  final currentDay  = 1.obs;
  final totalDays   = 30.obs;
  final caloriesTarget = 1350.obs;
  final waterCurrent   = 0.0.obs;
  final waterTarget    = 3.0.obs;
  final focusTags   = <String>[].obs;
  final meals       = <MealSlot>[].obs;
  final isLoading   = true.obs;
  final hasError    = false.obs;

  @override
  void onInit() {
    super.onInit();
    _syncFromHome();
    loadData();
  }

  void _syncFromHome() {
    try {
      final home = Get.find<HomeController>();
      currentDay.value = home.currentDay.value;
      totalDays.value  = home.totalDays.value;
      goal.value       = home.goalText.value.isNotEmpty ? home.goalText.value : 'Weight Loss';
    } catch (_) {}
  }

  Future<void> loadData() async {
    isLoading(true);
    hasError(false);
    try {
      final api = Get.find<ApiService>();

      final profile = await api.getProfile();
      if (profile != null) {
        final ds = profile['dietStyle'] as String?;
        if (ds != null && ds.isNotEmpty) dietStyle.value = ds;
        final g = profile['goal'] as String?;
        if (g != null && g.isNotEmpty) goal.value = _goalDisplay(g);
      }

      final plans = await api.getDietPlans();
      Map<String, dynamic>? match;
      if (plans.isNotEmpty) {
        match = plans.cast<Map<String, dynamic>>().firstWhereOrNull(
          (p) => _typeMatches(p['type'] as String?, dietStyle.value),
        );
        match ??= plans.first as Map<String, dynamic>;
      }

      if (match != null) {
        caloriesTarget.value = (match['calories'] as num?)?.toInt() ?? 1350;
        final mealsJson = match['meals'];
        if (mealsJson is Map && mealsJson['items'] is List) {
          meals.value = (mealsJson['items'] as List)
              .map((m) => MealSlot.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList();
          focusTags.value = List<String>.from(
              (mealsJson['tags'] as List?)?.cast<String>() ?? []);
          final wt = mealsJson['waterTarget'];
          if (wt != null) waterTarget.value = (wt as num).toDouble();
        } else {
          meals.value = _defaultMeals();
        }
      } else {
        meals.value = _defaultMeals();
      }

      if (focusTags.isEmpty) _setDefaultTags();
    } catch (_) {
      hasError(true);
      meals.value = _defaultMeals();
      _setDefaultTags();
    } finally {
      isLoading(false);
    }
  }

  void _setDefaultTags() {
    focusTags.value = [
      '${caloriesTarget.value} kcal Target',
      'High Protein Focus',
      '${goal.value} Friendly',
    ];
  }

  bool _typeMatches(String? planType, String userStyle) {
    if (planType == null) return false;
    final p = planType.toLowerCase();
    final u = userStyle.toLowerCase();
    if (u.contains('vegan'))           return p.contains('vegan');
    if (u.contains('non'))             return p.contains('non');
    if (u.contains('vegetarian'))      return p.contains('veg') && !p.contains('non');
    return true;
  }

  String _goalDisplay(String g) {
    const map = {
      'Loss weight':    'Weight Loss',
      'Lift & tone':    'Lift & Tone',
      'Lose belly fat': 'Belly Fat Loss',
      'Build muscles':  'Build Muscles',
    };
    return map[g] ?? g;
  }

  String get dietEmoji {
    final s = dietStyle.value.toLowerCase();
    if (s.contains('vegan'))  return '🌱';
    if (s.contains('non'))    return '🍗';
    if (s.contains('vegeta')) return '🥗';
    return '🥦';
  }

  int get totalMealKcal => meals.fold(0, (sum, m) => sum + m.kcal);

  List<MealSlot> _defaultMeals() => const [
    MealSlot(
      type: 'breakfast', label: 'Breakfast', time: '7:30 AM',
      desc: 'Oats with chia seeds, banana, berries & almonds',
      kcal: 320, image: 'assets/images/diet_breakfast.png', emoji: '☀️',
    ),
    MealSlot(
      type: 'mid_morning', label: 'Mid Morning', time: '10:30 AM',
      desc: 'Green tea\n5 almonds',
      kcal: 60, image: 'assets/images/diet_mid_morning.png', emoji: '☕',
    ),
    MealSlot(
      type: 'lunch', label: 'Lunch', time: '1:30 PM',
      desc: 'Brown rice, paneer stir fry, mixed salad & dal',
      kcal: 450, image: 'assets/images/diet_lunch.png', emoji: '🍛',
    ),
    MealSlot(
      type: 'snack', label: 'Evening Snack', time: '4:30 PM',
      desc: 'Sprouts chaat, fruit bowl & cucumber',
      kcal: 150, image: 'assets/images/diet_snack.png', emoji: '🥗',
    ),
    MealSlot(
      type: 'dinner', label: 'Dinner', time: '7:30 PM',
      desc: 'Vegetable soup & grilled paneer',
      kcal: 370, image: 'assets/images/diet_dinner.png', emoji: '🍽️',
    ),
  ];
}
