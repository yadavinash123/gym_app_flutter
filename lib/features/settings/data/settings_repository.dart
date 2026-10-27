import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import '../models/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(storeProvider)),
);

final appSettingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Convenience provider for default character figure in animations ('male' or 'female')
final characterFigureProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).exerciseFigure;
});

/// Convenience provider for default body diagram in 2D Muscle Map ('male' or 'female')
final bodyDiagramFigureProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).bodyDiagram;
});

class SettingsRepository {
  SettingsRepository(this.store);
  final JsonStore store;

  Future<AppSettings> load() async {
    final data = await store.read('app_settings');
    if (data == null) return const AppSettings();
    return AppSettings.fromJson(data);
  }

  Future<void> save(AppSettings settings) async {
    await store.write('app_settings', settings.toJson());
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() {
    // Kick off async load
    Future.microtask(() => _load());
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final saved = await _repository.load();
      final profile = ref.read(profileProvider).value;
      final initialGender = profile?.gender;
      if (initialGender != null &&
          initialGender.toLowerCase() == 'female' &&
          saved.bodyDiagram == 'male' &&
          saved.exerciseFigure == 'male') {
        state = saved.copyWith(bodyDiagram: 'female', exerciseFigure: 'female');
      } else {
        state = saved;
      }
    } catch (_) {
      // Use defaults
    }
  }

  Future<void> setBodyDiagram(String gender) async {
    final normalized = gender.toLowerCase() == 'female' ? 'female' : 'male';
    state = state.copyWith(bodyDiagram: normalized);
    await _repository.save(state);
  }

  Future<void> setExerciseFigure(String figure) async {
    final normalized = figure.toLowerCase() == 'female' ? 'female' : 'male';
    state = state.copyWith(exerciseFigure: normalized);
    await _repository.save(state);
  }

  Future<void> setThemeMode(String theme) async {
    state = state.copyWith(themeMode: theme);
    await _repository.save(state);
  }

  Future<void> setAccentColor(String color) async {
    state = state.copyWith(accentColor: color);
    await _repository.save(state);
  }

  Future<void> setUnits(String units) async {
    state = state.copyWith(units: units);
    await _repository.save(state);
  }

  Future<void> setWeighIn(bool val) async {
    state = state.copyWith(weighInBeforeWorkout: val);
    await _repository.save(state);
  }

  Future<void> setKeepScreenAwake(bool val) async {
    state = state.copyWith(keepScreenAwake: val);
    await _repository.save(state);
  }

  Future<void> setExerciseAnimations(String anim) async {
    state = state.copyWith(exerciseAnimations: anim);
    await _repository.save(state);
  }

  Future<void> setFirstDayOfWeek(String day) async {
    state = state.copyWith(firstDayOfWeek: day);
    await _repository.save(state);
  }
}
