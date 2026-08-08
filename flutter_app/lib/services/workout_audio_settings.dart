import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Whether exercise clips make a sound, and how loud.
///
/// Device-local rather than synced through `/profile`: this is a property of
/// *where* someone is working out — a quiet room, a shared gym, headphones —
/// not of their account, and it has to keep working with no connection.
///
/// Exposed as listenables so a clip already on screen follows the slider while
/// the settings sheet is open, rather than waiting for the next exercise to
/// pick the value up.
class WorkoutAudioSettings {
  WorkoutAudioSettings._();
  static final WorkoutAudioSettings instance = WorkoutAudioSettings._();

  static const String _enabledKey = 'workoutClipSoundEnabled';
  static const String _volumeKey = 'workoutClipVolume';

  /// Sound on at full volume by default: the clips carry coaching audio, and a
  /// user who has never opened settings should hear what was recorded for them.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final ValueNotifier<double> volume = ValueNotifier<double>(1);

  GetStorage? _box;

  /// Reads the stored values. `GetStorage.init()` already runs in `main`, so
  /// this only binds to the box and loads.
  void load() {
    final box = GetStorage();
    _box = box;
    enabled.value = box.read<bool>(_enabledKey) ?? true;
    volume.value = _clamp(box.read<num>(_volumeKey)?.toDouble() ?? 1);
  }

  /// What a player should hand to `setVolume`. Muting is expressed as zero
  /// volume rather than a separate flag so callers have one number to apply.
  double get effectiveVolume => enabled.value ? volume.value : 0;

  void setEnabled(bool value) {
    enabled.value = value;
    _box?.write(_enabledKey, value);
  }

  void setVolume(double value) {
    final next = _clamp(value);
    volume.value = next;
    _box?.write(_volumeKey, next);
  }

  static double _clamp(double value) => value.clamp(0, 1);
}
