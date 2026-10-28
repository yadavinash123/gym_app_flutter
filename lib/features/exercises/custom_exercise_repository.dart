import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/json_store.dart';
import '../profile/profile_repository.dart';
import 'exercise.dart';

class CustomExerciseRepository {
  CustomExerciseRepository(this.store);
  final JsonStore store;
  Future<void> _tail = Future.value();

  Directory get mediaDirectory =>
      Directory('${store.directory.path}/custom_media');

  Future<List<Exercise>> load() async {
    await _tail;
    return _read();
  }

  Future<List<Exercise>> _read() async {
    final data = await store.read('custom_exercises');
    if (data == null) return [];
    final exercises = data['exercises'];
    if (data['version'] != 1 || exercises is! List) {
      throw const FormatException('Invalid custom exercises data');
    }
    final items = <Exercise>[];
    for (final entry in exercises) {
      if (entry is Map<String, dynamic>) {
        items.add(Exercise.fromJson(entry));
      }
    }
    return items;
  }

  /// Persists a media file to the app's persistent storage if it is not already there.
  Future<String?> persistMediaFile(String sourcePath, String exerciseId) async {
    final src = File(sourcePath);
    if (!await src.exists()) return null;

    await mediaDirectory.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'dat';
    final targetPath = '${mediaDirectory.path}/${exerciseId}_media.$ext';

    if (sourcePath == targetPath) {
      return targetPath;
    }

    final targetFile = await src.copy(targetPath);
    return targetFile.path;
  }

  Future<Exercise> save(Exercise exercise) {
    final result = _tail.then((_) async {
      final existing = await _read();
      final id = exercise.id.isEmpty
          ? 'c_${DateTime.now().millisecondsSinceEpoch}'
          : exercise.id;

      String? finalMediaPath = exercise.mediaPath;
      if (finalMediaPath != null && finalMediaPath.isNotEmpty) {
        final savedPath = await persistMediaFile(finalMediaPath, id);
        if (savedPath != null) {
          finalMediaPath = savedPath;
        }
      }

      final updatedExercise = exercise.copyWith(
        id: id,
        isCustom: true,
        mediaPath: finalMediaPath,
      );

      final index = existing.indexWhere((e) => e.id == id);
      final List<Exercise> nextList;
      if (index >= 0) {
        nextList = List<Exercise>.from(existing)..[index] = updatedExercise;
      } else {
        nextList = [updatedExercise, ...existing];
      }

      await store.write('custom_exercises', {
        'version': 1,
        'exercises': nextList.map((e) => e.toJson()).toList(),
      });

      return updatedExercise;
    });

    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> delete(String id) {
    final result = _tail.then((_) async {
      final existing = await _read();
      final target = existing.where((e) => e.id == id).firstOrNull;

      // Clean up local media if it resides in our mediaDirectory
      if (target?.mediaPath != null) {
        try {
          final f = File(target!.mediaPath!);
          if (await f.exists() && f.path.contains(mediaDirectory.path)) {
            await f.delete();
          }
        } catch (_) {}
      }

      final nextList = existing.where((e) => e.id != id).toList();
      await store.write('custom_exercises', {
        'version': 1,
        'exercises': nextList.map((e) => e.toJson()).toList(),
      });
    });

    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

final customExerciseRepositoryProvider = Provider<CustomExerciseRepository>(
  (ref) => CustomExerciseRepository(ref.watch(storeProvider)),
);

final customExercisesProvider =
    AsyncNotifierProvider<CustomExercisesController, List<Exercise>>(
      CustomExercisesController.new,
    );

class CustomExercisesController extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() {
    return ref.watch(customExerciseRepositoryProvider).load();
  }

  Future<Exercise> saveExercise(Exercise exercise) async {
    final saved = await ref
        .read(customExerciseRepositoryProvider)
        .save(exercise);
    final updatedList = await ref.read(customExerciseRepositoryProvider).load();
    state = AsyncValue.data(updatedList);
    return saved;
  }

  Future<void> deleteExercise(String id) async {
    await ref.read(customExerciseRepositoryProvider).delete(id);
    final updatedList = await ref.read(customExerciseRepositoryProvider).load();
    state = AsyncValue.data(updatedList);
  }
}
