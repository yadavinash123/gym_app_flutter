import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/json_store.dart';
import '../profile/profile_repository.dart';

class FavoritesRepository {
  FavoritesRepository(this.store);
  final JsonStore store;
  Future<void> _tail = Future.value();

  Future<Set<String>> load() async {
    await _tail;
    return _read();
  }

  Future<Set<String>> _read() async {
    final data = await store.read('exercise_preferences');
    if (data == null) return {};
    final ids = data['favorites'];
    if (data['version'] != 1 ||
        ids is! List ||
        ids.any(
          (id) => id is! String || !RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id),
        )) {
      throw const FormatException('Invalid exercise preferences');
    }
    return Set<String>.from(ids);
  }

  // Serialize the entire read/modify/write, not only the final file write.
  Future<Set<String>> toggle(String id) {
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id)) {
      return Future.error(ArgumentError('Invalid exercise ID'));
    }
    final result = _tail.then((_) async {
      final ids = await _read();
      if (!ids.remove(id)) ids.add(id);
      await store.write('exercise_preferences', {
        'version': 1,
        'favorites': ids.toList()..sort(),
      });
      return ids;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

final favoritesRepositoryProvider = Provider(
  (ref) => FavoritesRepository(ref.watch(storeProvider)),
);
final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
      FavoritesController.new,
    );

class FavoritesController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(favoritesRepositoryProvider).load();

  Future<void> toggle(String id) async {
    // Retain the last saved value on failure; the caller displays the error.
    final ids = await ref.read(favoritesRepositoryProvider).toggle(id);
    if (ref.mounted) state = AsyncData(Set.unmodifiable(ids));
  }
}
