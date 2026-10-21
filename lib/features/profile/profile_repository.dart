import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/json_store.dart';
import 'profile.dart';

final storeProvider = Provider<JsonStore>((ref) => throw UnimplementedError());
final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(storeProvider)),
);
final profileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);

class ProfileRepository {
  ProfileRepository(this.store);
  final JsonStore store;
  Future<Profile?> load() async {
    final data = await store.read('profile');
    return data == null ? null : Profile.fromJson(data);
  }

  Future<void> save(Profile profile) {
    final validated = Profile.fromJson(profile.toJson());
    return store.write('profile', validated.toJson());
  }
}
