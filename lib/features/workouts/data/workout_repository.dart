import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import '../models/planned_workout.dart';
import '../models/progressive_overload.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  WorkoutRepository(this.store);
  final JsonStore store;
  Future<void> _tail = Future.value();

  Future<List<WorkoutSession>> loadSessions() async {
    await _tail;
    return _readSessions();
  }

  Future<List<WorkoutSession>> _readSessions() async {
    final data = await store.read('workout_sessions');
    if (data == null) return [];
    if (data['version'] != 1 || data['sessions'] is! List) {
      throw const FormatException('Invalid workout sessions storage');
    }
    final list = (data['sessions'] as List)
        .map((s) => WorkoutSession.fromJson(s as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  Future<List<WorkoutSession>> saveSession(WorkoutSession session) {
    final result = _tail.then((_) async {
      final sessions = await _readSessions();
      sessions.removeWhere((s) => s.id == session.id);
      sessions.insert(0, session);
      await store.write('workout_sessions', {
        'version': 1,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      });
      return sessions;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<WorkoutSession>> deleteSession(String id) {
    final result = _tail.then((_) async {
      final sessions = await _readSessions();
      sessions.removeWhere((s) => s.id == id);
      await store.write('workout_sessions', {
        'version': 1,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      });
      return sessions;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<PlannedRoutine>> loadTemplates() async {
    await _tail;
    return _readTemplates();
  }

  Future<List<PlannedRoutine>> _readTemplates() async {
    final data = await store.read('workout_templates');
    if (data == null) return _defaultTemplates();
    if (data['version'] != 1 || data['templates'] is! List) {
      return _defaultTemplates();
    }
    return (data['templates'] as List)
        .map((t) => PlannedRoutine.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlannedRoutine>> saveTemplate(PlannedRoutine template) {
    final result = _tail.then((_) async {
      final templates = await _readTemplates();
      final index = templates.indexWhere((t) => t.id == template.id);
      if (index >= 0) {
        templates[index] = template;
      } else {
        templates.add(template);
      }
      await store.write('workout_templates', {
        'version': 1,
        'templates': templates.map((t) => t.toJson()).toList(),
      });
      return templates;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<PlannedRoutine>> deleteTemplate(String id) {
    final result = _tail.then((_) async {
      final templates = await _readTemplates();
      templates.removeWhere((t) => t.id == id);
      await store.write('workout_templates', {
        'version': 1,
        'templates': templates.map((t) => t.toJson()).toList(),
      });
      return templates;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static List<PlannedRoutine> _defaultTemplates() => [
    const PlannedRoutine(
      id: 'tmpl-push',
      name: 'Push Power',
      category: 'Push',
      targetDurationMinutes: 35,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'push-up',
          exerciseName: 'Push-up',
          primaryMuscles: ['Chest', 'Triceps'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'dip',
          exerciseName: 'Bench dip',
          primaryMuscles: ['Triceps', 'Chest'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'plank',
          exerciseName: 'Plank',
          primaryMuscles: ['Abdominals'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 30, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 30, targetRestSeconds: 45),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-pull',
      name: 'Pull Strength',
      category: 'Pull',
      targetDurationMinutes: 35,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'bird-dog',
          exerciseName: 'Bird dog',
          primaryMuscles: ['Back', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 45),
          ],
        ),
        PlannedExercise(
          exerciseId: 'dead-bug',
          exerciseName: 'Dead bug',
          primaryMuscles: ['Abdominals'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 45),
          ],
        ),
        PlannedExercise(
          exerciseId: 'chest-stretch',
          exerciseName: 'Chest stretch',
          primaryMuscles: ['Chest', 'Shoulders'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 5, targetRestSeconds: 30),
            PlannedSet(setNumber: 2, targetReps: 5, targetRestSeconds: 30),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-legs',
      name: 'Legs & Lower Body',
      category: 'Legs',
      targetDurationMinutes: 40,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'squat',
          exerciseName: 'Bodyweight squat',
          primaryMuscles: ['Quadriceps', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'lunge',
          exerciseName: 'Lunge',
          primaryMuscles: ['Quadriceps', 'Hamstrings'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'bridge',
          exerciseName: 'Bridge',
          primaryMuscles: ['Glutes', 'Hamstrings'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 15, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 15, targetRestSeconds: 45),
            PlannedSet(setNumber: 3, targetReps: 15, targetRestSeconds: 45),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-upper',
      name: 'Upper Body Power',
      category: 'Upper',
      targetDurationMinutes: 30,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'push-up',
          exerciseName: 'Push-up',
          primaryMuscles: ['Chest', 'Triceps'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'dip',
          exerciseName: 'Bench dip',
          primaryMuscles: ['Triceps', 'Chest'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'chest-stretch',
          exerciseName: 'Chest stretch',
          primaryMuscles: ['Chest', 'Shoulders'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 5, targetRestSeconds: 30),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-lower',
      name: 'Lower Body Strength',
      category: 'Lower',
      targetDurationMinutes: 30,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'squat',
          exerciseName: 'Bodyweight squat',
          primaryMuscles: ['Quadriceps', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'bridge',
          exerciseName: 'Bridge',
          primaryMuscles: ['Glutes', 'Hamstrings'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 45),
          ],
        ),
        PlannedExercise(
          exerciseId: 'plank',
          exerciseName: 'Plank',
          primaryMuscles: ['Abdominals'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 30, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 30, targetRestSeconds: 45),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-full-body',
      name: 'Classic Full Body',
      category: 'Full-body strength',
      targetDurationMinutes: 30,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'squat',
          exerciseName: 'Bodyweight squat',
          primaryMuscles: ['Quadriceps', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'push-up',
          exerciseName: 'Push-up',
          primaryMuscles: ['Chest', 'Triceps'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
            PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'bridge',
          exerciseName: 'Bridge',
          primaryMuscles: ['Glutes', 'Hamstrings'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 45),
            PlannedSet(setNumber: 3, targetReps: 12, targetRestSeconds: 45),
          ],
        ),
        PlannedExercise(
          exerciseId: 'plank',
          exerciseName: 'Plank',
          primaryMuscles: ['Abdominals'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 30, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 30, targetRestSeconds: 45),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-beginner-strength',
      name: 'Beginner Strength Foundation',
      category: 'Beginner strength',
      targetDurationMinutes: 25,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'squat',
          exerciseName: 'Bodyweight squat',
          primaryMuscles: ['Quadriceps', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 8, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 8, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'push-up',
          exerciseName: 'Push-up',
          primaryMuscles: ['Chest', 'Triceps'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 8, targetRestSeconds: 60),
            PlannedSet(setNumber: 2, targetReps: 8, targetRestSeconds: 60),
          ],
        ),
        PlannedExercise(
          exerciseId: 'bridge',
          exerciseName: 'Bridge',
          primaryMuscles: ['Glutes', 'Hamstrings'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 45),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 45),
          ],
        ),
      ],
    ),
    const PlannedRoutine(
      id: 'tmpl-core-mobility',
      name: 'Core & Mobility Reset',
      category: 'Mobility',
      targetDurationMinutes: 20,
      isCustom: false,
      exercises: [
        PlannedExercise(
          exerciseId: 'bird-dog',
          exerciseName: 'Bird dog',
          primaryMuscles: ['Back', 'Glutes'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 30),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 30),
          ],
        ),
        PlannedExercise(
          exerciseId: 'dead-bug',
          exerciseName: 'Dead bug',
          primaryMuscles: ['Abdominals'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 30),
            PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 30),
          ],
        ),
        PlannedExercise(
          exerciseId: 'chest-stretch',
          exerciseName: 'Chest stretch',
          primaryMuscles: ['Chest', 'Shoulders'],
          sets: [
            PlannedSet(setNumber: 1, targetReps: 5, targetRestSeconds: 30),
            PlannedSet(setNumber: 2, targetReps: 5, targetRestSeconds: 30),
          ],
        ),
      ],
    ),
  ];
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(storeProvider)),
);

final workoutSessionsProvider =
    AsyncNotifierProvider<WorkoutSessionsController, List<WorkoutSession>>(
      WorkoutSessionsController.new,
    );

class WorkoutSessionsController extends AsyncNotifier<List<WorkoutSession>> {
  @override
  Future<List<WorkoutSession>> build() =>
      ref.watch(workoutRepositoryProvider).loadSessions();

  Future<void> addSession(WorkoutSession session) async {
    final updated = await ref
        .read(workoutRepositoryProvider)
        .saveSession(session);
    if (ref.mounted) state = AsyncData(updated);
  }

  Future<void> removeSession(String id) async {
    final updated = await ref.read(workoutRepositoryProvider).deleteSession(id);
    if (ref.mounted) state = AsyncData(updated);
  }
}

final workoutTemplatesProvider =
    AsyncNotifierProvider<WorkoutTemplatesController, List<PlannedRoutine>>(
      WorkoutTemplatesController.new,
    );

class WorkoutTemplatesController extends AsyncNotifier<List<PlannedRoutine>> {
  @override
  Future<List<PlannedRoutine>> build() =>
      ref.watch(workoutRepositoryProvider).loadTemplates();

  Future<void> saveTemplate(PlannedRoutine template) async {
    final updated = await ref
        .read(workoutRepositoryProvider)
        .saveTemplate(template);
    if (ref.mounted) state = AsyncData(updated);
  }

  Future<void> removeTemplate(String id) async {
    final updated = await ref
        .read(workoutRepositoryProvider)
        .deleteTemplate(id);
    if (ref.mounted) state = AsyncData(updated);
  }
}

final personalRecordsProvider = Provider<Map<String, PersonalRecord>>((ref) {
  final sessionsAsync = ref.watch(workoutSessionsProvider);
  final sessions = sessionsAsync.value ?? [];
  final map = <String, PersonalRecord>{};
  final exerciseIds = <String>{};
  for (final s in sessions) {
    for (final ex in s.exercises) {
      exerciseIds.add(ex.exerciseId);
    }
  }
  for (final id in exerciseIds) {
    final pr = ProgressiveOverloadCalculator.calculatePR(
      exerciseId: id,
      sessions: sessions,
    );
    if (pr != null) {
      map[id] = pr;
    }
  }
  return map;
});
