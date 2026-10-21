import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'muscle_map.dart';
import 'trainer/exercise_3d_viewer.dart';
import 'trainer/exercise_asset_repository.dart';

/// Selects only an installed, exercise-specific GLB. No substitution of clips.
class ExerciseAnimationPlayer extends ConsumerWidget {
  const ExerciseAnimationPlayer({
    super.key,
    required this.animationId,
    required this.primary,
    required this.secondary,
  });
  final String? animationId;
  final List<String> primary, secondary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (animationId == null) return fallback();
    return ref
        .watch(exercise3DAssetsProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Column(
            children: [
              fallback(),
              TextButton(
                onPressed: () => ref.invalidate(exercise3DAssetsProvider),
                child: const Text('Retry 3D catalog'),
              ),
            ],
          ),
          data: (assets) => assets[animationId] == null
              ? fallback()
              : Exercise3DViewer(asset: assets[animationId]!),
        );
  }

  Widget fallback() => Column(
    children: [
      const Text(
        '3D animation not installed',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      MuscleMap(primary: primary, secondary: secondary),
      const SizedBox(height: 8),
      const Text(
        'Muscle illustration only\nLime: primary • Cyan: secondary\nFollow the written guide below.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
