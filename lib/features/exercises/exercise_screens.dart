import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/page_body.dart';
import 'exercise.dart';
import 'exercise_animation_player.dart';
import 'favorites.dart';
import 'muscle_map.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final search = TextEditingController();
  String? muscle, equipment, level;
  bool onlyFavorites = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    search.clear();
    muscle = null;
    equipment = null;
    level = null;
    onlyFavorites = false;
  });
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider);
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise library'),
        leading: BackButton(onPressed: () => _back(context)),
      ),
      body: SafeArea(
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(exerciseCatalogProvider),
              child: const Text('Retry exercise library'),
            ),
          ),
          data: (all) {
            final visible = all
                .where(
                  (e) => e.matches(
                    query: search.text,
                    muscle: muscle,
                    equipmentFilter: equipment,
                    levelFilter: level,
                    favorites: onlyFavorites ? favorites.value ?? {} : null,
                  ),
                )
                .toList();
            final equipmentOptions =
                all.expand((e) => e.equipment).toSet().toList()..sort();
            return PageBody(
              children: [
                Text(
                  'Find your movement',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text('${all.length} offline guides • 1 installed 3D exercise'),
                const SizedBox(height: 20),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search exercises',
                    hintText: 'Name, muscle or equipment',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    muscle == null ? 'Explore by muscle' : 'Muscle: $muscle',
                  ),
                  children: [
                    MuscleMap(
                      primary: muscle == null ? [] : [muscle!],
                      onSelect: (value) => setState(
                        () => muscle = muscle == value ? null : value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('equipment-$equipment'),
                  initialValue: equipment ?? 'All equipment',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Equipment'),
                  items: ['All equipment', ...equipmentOptions]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(
                    () => equipment = v == 'All equipment' ? null : v,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('level-$level'),
                  initialValue: level ?? 'All levels',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Experience'),
                  items: ['All levels', 'Beginner', 'Intermediate']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => level = v == 'All levels' ? null : v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Favorites'),
                      avatar: const Icon(Icons.favorite_border),
                      selected: onlyFavorites,
                      onSelected: favorites.hasValue
                          ? (v) => setState(() => onlyFavorites = v)
                          : null,
                    ),
                    TextButton(
                      onPressed: reset,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
                if (favorites.hasError)
                  _FavoritesError(
                    onRetry: () => ref.invalidate(favoritesProvider),
                  ),
                const SizedBox(height: 12),
                Text(
                  '${visible.length} exercises',
                  semanticsLabel: '${visible.length} matching exercises',
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const InfoCard(
                    title: 'No matching exercises',
                    message: 'Try clearing a filter or save exercises using the heart button.',
                    icon: Icons.search_off,
                  ),
                for (final exercise in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${exercise.group} • ${exercise.level}\n${exercise.equipment.join(', ')}${exercise.animation == null ? '' : '\n3D trainer · Offline'}',
                        ),
                        isThreeLine: true,
                        trailing: FavoriteButton(
                          id: exercise.id,
                          name: exercise.name,
                        ),
                        onTap: () => context.push('/exercises/${exercise.id}'),
                      ),
                    ),
                  ),
                const Text(
                  'Guides adapt published references. They are educational and have not had an independent professional review. This starter catalog does not yet cover the full planned library.',
                  style: TextStyle(color: Color(0xFFA7B0BF)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Exercise guide'),
      leading: BackButton(onPressed: () => _back(context)),
    ),
    body: SafeArea(
      child: ref
          .watch(exerciseCatalogProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(exerciseCatalogProvider),
                child: const Text('Retry exercise guide'),
              ),
            ),
            data: (catalog) {
              final matches = catalog.where((e) => e.id == id);
              if (matches.isEmpty) {
                return PageBody(
                  children: [
                    const InfoCard(
                      title: 'Exercise not found',
                      message: 'This exercise is not in the installed catalog.',
                      icon: Icons.search_off,
                    ),
                    TextButton(
                      onPressed: () => context.go('/exercises'),
                      child: const Text('Open exercise library'),
                    ),
                  ],
                );
              }
              final exercise = matches.single;
              final favorites = ref.watch(favoritesProvider);
              return PageBody(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      FavoriteButton(id: id, name: exercise.name),
                    ],
                  ),
                  Text(
                    '${exercise.level} • ${exercise.movement}\n${exercise.equipment.join(', ')}',
                  ),
                  if (favorites.hasError)
                    _FavoritesError(
                      onRetry: () => ref.invalidate(favoritesProvider),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        exercise.animation == null ? 16 : 0,
                      ),
                      child: ExerciseAnimationPlayer(
                        animationId: exercise.animation,
                        primary: exercise.primary,
                        secondary: exercise.secondary,
                      ),
                    ),
                  ),
                  if (exercise.animation != null)
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('3D model credits & limitations'),
                      onPressed: () async {
                        final text = await rootBundle.loadString(
                          'assets/trainer/ATTRIBUTION.txt',
                        );
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('About this 3D trainer'),
                            content: SingleChildScrollView(
                              child: SelectableText(text),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Muscles involved',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Primary: ${exercise.primary.join(', ')}'),
                  if (exercise.secondary.isNotEmpty)
                    Text('Secondary: ${exercise.secondary.join(', ')}'),
                  if (exercise.animation != null)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('View muscle illustration'),
                      children: [
                        MuscleMap(
                          primary: exercise.primary,
                          secondary: exercise.secondary,
                        ),
                        const Text('Lime: primary • Cyan: secondary'),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Step by step',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (var i = 0; i < exercise.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '${i + 1}. ${exercise.steps[i]}',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  const SizedBox(height: 20),
                  InfoCard(
                    title: 'Posture cue',
                    message: exercise.cue,
                    icon: Icons.accessibility_new,
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    title: 'Common mistake',
                    message: exercise.mistake,
                    icon: Icons.visibility_outlined,
                  ),
                  const SizedBox(height: 12),
                  const InfoCard(
                    title: 'Breathing & comfort',
                    message: 'Keep breathing. During strength repetitions, breathe out with effort and in as you ease back. Use a comfortable range and stop if movement causes pain.',
                    icon: Icons.air,
                  ),
                  const SizedBox(height: 20),
                  if (exercise.alternatives.isNotEmpty) ...[
                    Text(
                      'Related guides',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'These are options to explore, not automatic substitutions for an injury or limitation.',
                    ),
                    for (final alternative in exercise.alternatives)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          catalog.firstWhere((e) => e.id == alternative).name,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/exercises/$alternative'),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Reference',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Adapted from ${exercise.source}. Original media is not bundled. Copy the link to read the source in your browser.',
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    exercise.url,
                    style: const TextStyle(color: Color(0xFF00D4FF)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: exercise.url),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reference link copied'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy reference link'),
                  ),
                  const Text(
                    'General breathing guidance: Mayo Clinic, “Strength training: Get stronger, leaner, healthier.”',
                  ),
                  const SelectableText(
                    'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/strength-training/art-20046031',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sets, repetitions, rest intervals and personalized substitutions are not prescribed in this phase. Choose movement suited to your abilities; seek qualified guidance for an injury or medical restriction.',
                    style: TextStyle(color: Color(0xFFA7B0BF)),
                  ),
                ],
              );
            },
          ),
    ),
  );
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/workouts');
  }
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'Unable to read favorites. Your saved file has been preserved.',
      ),
      TextButton(onPressed: onRetry, child: const Text('Retry favorites')),
    ],
  );
}

class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({super.key, required this.id, required this.name});
  final String id, name;
  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool saving = false;
  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final selected = favorites.value?.contains(widget.id) ?? false;
    return IconButton(
      tooltip:
          '${selected ? 'Remove' : 'Save'} ${widget.name} ${selected ? 'from' : 'to'} favorites',
      isSelected: selected,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: const Icon(Icons.favorite, color: Color(0xFFB6FF3B)),
      onPressed: saving || !favorites.hasValue
          ? null
          : () async {
              setState(() => saving = true);
              try {
                await ref.read(favoritesProvider.notifier).toggle(widget.id);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save favorite. Your previous favorites are unchanged. Try again.',
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => saving = false);
              }
            },
    );
  }
}
