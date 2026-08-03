import 'package:get/get.dart';

import '../services/api_service.dart';

/// One logged drink.
class WaterEntry {
  final String id;
  final int amountMl;
  final DateTime at;

  const WaterEntry({required this.id, required this.amountMl, required this.at});

  /// Server shape — kept here so wiring the API later is a one-line swap.
  factory WaterEntry.fromJson(Map<String, dynamic> j) => WaterEntry(
        id: (j['id'] as String?) ?? '',
        amountMl: (j['amountMl'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(j['loggedAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

/// Reminder cadence options shown on the settings screen.
enum ReminderInterval { m30, m45, h1, m90, h2 }

extension ReminderIntervalX on ReminderInterval {
  String get label => switch (this) {
        ReminderInterval.m30 => '30 min',
        ReminderInterval.m45 => '45 min',
        ReminderInterval.h1 => '1 hour',
        ReminderInterval.m90 => '90 min',
        ReminderInterval.h2 => '2 hour',
      };

  int get minutes => switch (this) {
        ReminderInterval.m30 => 30,
        ReminderInterval.m45 => 45,
        ReminderInterval.h1 => 60,
        ReminderInterval.m90 => 90,
        ReminderInterval.h2 => 120,
      };
}

/// State for the Water Tracker and Hydration Settings screens, backed by
/// `/water/*`.
///
/// Writes are optimistic — the ring should move the instant a glass is tapped,
/// not after a round trip — and each one reconciles against the server
/// afterwards so a failed request cannot leave a phantom entry on screen.
class WaterController extends GetxController {
  ApiService get _api => Get.find<ApiService>();

  final loading = false.obs;
  final streak = 0.obs;
  // ── Goal & intake ──────────────────────────────────────────────────────────
  final goalMl = 2000.obs;
  final entries = <WaterEntry>[].obs;

  // ── Reminder settings ──────────────────────────────────────────────────────
  final smartReminder = true.obs;
  final interval = ReminderInterval.h1.obs;
  final quietHoursEnabled = true.obs;
  final quietFromHour = 22.obs; // 10:00 PM
  final quietToHour = 7.obs; //  7:00 AM
  final soundEnabled = true.obs;
  final vibrationEnabled = true.obs;
  final smartMode = true.obs;

  /// Set once the goal is hit, so the celebration state persists for the day
  /// even if the user logs more water afterwards.
  final remindersPausedToday = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Pulls today's entries, goal, streak and reminder settings.
  ///
  /// `/water/today` already returns the goal, so settings are only fetched for
  /// the reminder fields the tracker screen does not need.
  Future<void> load() async {
    loading.value = true;
    final today = await _api.getWaterToday();
    if (today != null) {
      _applyToday(today);
    }
    final s = await _api.getWaterSettings();
    if (s != null) _applySettings(s);
    loading.value = false;
  }

  void _applyToday(Map<String, dynamic> d) {
    final raw = (d['entries'] as List?) ?? [];
    entries.assignAll(
      raw.map((e) => WaterEntry.fromJson(e as Map<String, dynamic>)),
    );
    final g = (d['goalMl'] as num?)?.toInt();
    if (g != null && g > 0) goalMl.value = g;
    streak.value = (d['streak'] as num?)?.toInt() ?? 0;
  }

  void _applySettings(Map<String, dynamic> s) {
    final g = (s['waterGoalLiters'] as num?)?.toDouble();
    if (g != null && g > 0) goalMl.value = (g * 1000).round();

    smartReminder.value = (s['waterReminderEnabled'] as bool?) ?? true;
    final mins = (s['waterReminderMinutes'] as num?)?.toInt() ?? 60;
    interval.value = ReminderInterval.values.firstWhere(
      (i) => i.minutes == mins,
      orElse: () => ReminderInterval.h1,
    );
    quietFromHour.value = (s['waterQuietFromHour'] as num?)?.toInt() ?? 22;
    quietToHour.value = (s['waterQuietToHour'] as num?)?.toInt() ?? 7;
    soundEnabled.value = (s['waterSoundEnabled'] as bool?) ?? true;
    vibrationEnabled.value = (s['waterVibrationEnabled'] as bool?) ?? true;
    smartMode.value = (s['waterSmartMode'] as bool?) ?? true;
  }

  /// Persists the hydration settings screen. Returns false so the UI can say so
  /// rather than claiming a save that did not happen.
  Future<bool> saveSettings() async {
    final res = await _api.updateWaterSettings({
      'waterGoalLiters': goalMl.value / 1000,
      'waterReminderEnabled': smartReminder.value,
      'waterReminderMinutes': interval.value.minutes,
      'waterQuietFromHour': quietFromHour.value,
      'waterQuietToHour': quietToHour.value,
      'waterSoundEnabled': soundEnabled.value,
      'waterVibrationEnabled': vibrationEnabled.value,
      'waterSmartMode': smartMode.value,
    });
    if (res != null) _applySettings(res);
    return res != null;
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  int get consumedMl => entries.fold(0, (sum, e) => sum + e.amountMl);
  int get remainingMl => (goalMl.value - consumedMl).clamp(0, goalMl.value);

  /// 0..1, clamped so overshooting the goal does not overdraw the ring.
  double get progress =>
      goalMl.value == 0 ? 0 : (consumedMl / goalMl.value).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();
  bool get goalReached => consumedMl >= goalMl.value;

  String get consumedLabel => _litres(consumedMl);
  String get goalLabel => _litres(goalMl.value);

  static String _litres(int ml) => '${(ml / 1000).toStringAsFixed(1)} L';

  /// Copy under the ring changes with how far along the day is.
  String get statusHeadline =>
      goalReached ? 'Goal Completed! 🎉' : '$remainingMl ml remaining';

  String get statusSubline => goalReached
      ? 'Amazing! You reached today\'s hydration goal.'
      : 'Almost there! Drink one more glass. 💧';

  String get quietHoursLabel =>
      '${_hour(quietFromHour.value)} - ${_hour(quietToHour.value)}';

  static String _hour(int h) {
    final suffix = h >= 12 ? 'PM' : 'AM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $suffix';
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Optimistic: the entry appears immediately, then the server row replaces the
  /// placeholder. A failed call rolls it back rather than leaving a row the
  /// server never accepted.
  Future<void> addWater(int amountMl) async {
    if (amountMl <= 0) return;
    final wasReached = goalReached;

    final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    entries.insert(
      0,
      WaterEntry(id: tempId, amountMl: amountMl, at: DateTime.now()),
    );
    // Pausing reminders is a consequence of *crossing* the goal, not of being
    // above it, so it only fires on the transition.
    if (!wasReached && goalReached) remindersPausedToday.value = true;

    final saved = await _api.addWater(amountMl);
    final i = entries.indexWhere((e) => e.id == tempId);
    if (i == -1) return; // removed while in flight

    if (saved == null) {
      entries.removeAt(i);
      Get.snackbar('Not saved', 'Could not log that drink. Check your connection.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    entries[i] = WaterEntry.fromJson(saved);
  }

  Future<void> removeEntry(String id) async {
    final index = entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final removed = entries[index];
    entries.removeAt(index);

    final ok = await _api.deleteWater(id);
    if (!ok) {
      entries.insert(index, removed); // put it back
      Get.snackbar('Not deleted', 'Could not remove that entry.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void setGoalMl(int ml) => goalMl.value = ml.clamp(500, 6000);

  void nudgeGoal(int deltaMl) => setGoalMl(goalMl.value + deltaMl);
}
