import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/page_body.dart';
import '../settings/data/settings_repository.dart';
import '../workouts/data/workout_repository.dart';
import '../workouts/models/planned_workout.dart';
import '../workouts/models/workout_session.dart';
import '../workouts/session/workout_session_controller.dart';
import '../workouts/session/workout_session_screen.dart';
import 'exercise.dart';
import 'exercise_animation_player.dart';
import 'favorites.dart';
import 'muscle_map.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key, this.initialMuscle});
  final String? initialMuscle;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  String? muscle;
  String? equipment;
  String? category;
  String? level;
  bool onlyFavorites = false;
  String sortBy = 'name_asc'; // 'name_asc', 'name_desc', 'muscle'

  @override
  void initState() {
    super.initState();
    muscle = widget.initialMuscle;
    _searchController.addListener(() {
      setState(() => query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      query = '';
      muscle = null;
      equipment = null;
      category = null;
      level = null;
      onlyFavorites = false;
    });
  }

  void _openMuscleMapDialog(BuildContext context, List<Exercise> catalog) {
    // Compute exercise counts per muscle group
    final counts = <String, int>{};
    for (final m in muscleGroups) {
      counts[m] = catalog.where((e) => e.matches(muscle: m)).length;
    }
    final preferredFigure = ref.read(bodyDiagramFigureProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF283241),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Interactive Muscle Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFA7B0BF)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MuscleMap(
                initialGender: preferredFigure,
                sideBySideDefault: true,
                primary: muscle == null ? [] : [muscle!],
                exerciseCounts: counts,
                onSelect: (selected) {
                  setState(() {
                    muscle = muscle == selected ? null : selected;
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            tooltip: 'Interactive Muscle Map',
            icon: const Icon(
              Icons.accessibility_new_rounded,
              color: Color(0xFFB6FF3B),
            ),
            onPressed: () {
              if (catalogAsync.hasValue) {
                _openMuscleMapDialog(context, catalogAsync.value!);
              }
            },
          ),
          IconButton(
            tooltip: onlyFavorites ? 'Show all' : 'Favorites only',
            icon: Icon(
              onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: onlyFavorites ? const Color(0xFFB6FF3B) : null,
            ),
            onPressed: () => setState(() => onlyFavorites = !onlyFavorites),
          ),
        ],
      ),
      body: SafeArea(
        child: catalogAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFB6FF3B)),
          ),
          error: (err, _) => PageBody(
            children: [
              InfoCard(
                title: 'Unable to load exercises',
                message: '$err',
                icon: Icons.error_outline,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(exerciseCatalogProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (catalog) {
            // Extract unique equipment dynamically
            final dynamicEquipment = <String>{};
            for (final ex in catalog) {
              for (final eq in ex.equipment) {
                if (eq.isNotEmpty) dynamicEquipment.add(eq);
              }
            }
            final sortedEquipment = dynamicEquipment.toList()..sort();

            final favSet = favorites.value ?? {};

            // Filter exercises
            var visible = catalog.where((e) {
              return e.matches(
                query: query,
                muscle: muscle,
                equipmentFilter: equipment,
                levelFilter: level,
                categoryFilter: category,
                favorites: onlyFavorites ? favSet : null,
              );
            }).toList();

            // Sort visible
            if (sortBy == 'name_desc') {
              visible.sort((a, b) => b.name.compareTo(a.name));
            } else if (sortBy == 'muscle') {
              visible.sort((a, b) => a.group.compareTo(b.group));
            } else {
              visible.sort((a, b) => a.name.compareTo(b.name));
            }

            final hasActiveFilters =
                query.isNotEmpty ||
                muscle != null ||
                equipment != null ||
                category != null ||
                level != null ||
                onlyFavorites;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search exercises',
                            hintText: 'Name, muscle, or equipment...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFFA7B0BF),
                            ),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Muscle group filter chips with Wrap
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              avatar: const Icon(
                                Icons.accessibility_new,
                                size: 16,
                                color: Color(0xFFB6FF3B),
                              ),
                              label: const Text('Muscle Map'),
                              backgroundColor: const Color(0xFF1C2430),
                              side: const BorderSide(color: Color(0xFF283241)),
                              onPressed: () =>
                                  _openMuscleMapDialog(context, catalog),
                            ),
                            for (final m in muscleGroups)
                              FilterChip(
                                label: Text(m),
                                selected: muscle == m,
                                selectedColor: const Color(0xFFB6FF3B),
                                checkmarkColor: Colors.black,
                                labelStyle: TextStyle(
                                  color: muscle == m
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: muscle == m
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFF151B23),
                                side: BorderSide(
                                  color: muscle == m
                                      ? const Color(0xFFB6FF3B)
                                      : const Color(0xFF283241),
                                ),
                                onSelected: (selected) {
                                  setState(() => muscle = selected ? m : null);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Equipment filter
                        DropdownButtonFormField<String>(
                          key: ValueKey('equipment-$equipment'),
                          initialValue: equipment ?? 'All equipment',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Equipment',
                          ),
                          items: ['All equipment', ...sortedEquipment]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => equipment = v == 'All equipment' ? null : v,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Experience filter
                        DropdownButtonFormField<String>(
                          key: ValueKey('level-$level'),
                          initialValue: level ?? 'All levels',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Experience',
                          ),
                          items:
                              [
                                    'All levels',
                                    'Beginner',
                                    'Intermediate',
                                    'Advanced',
                                  ]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(
                            () => level = v == 'All levels' ? null : v,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Active filter chips & clear
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${visible.length} exercises',
                                style: const TextStyle(
                                  color: Color(0xFFA7B0BF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (hasActiveFilters)
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Clear filters'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00D4FF),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Exercise List
                if (visible.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: InfoCard(
                        title: 'No matching exercises',
                        message: 'Try clearing some filters or searching with different terms.',
                        icon: Icons.search_off,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final ex = visible[index];
                        return _buildExerciseCard(context, ex);
                      }, childCount: visible.length),
                    ),
                  ),

                // Bottom disclaimer
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Text(
                      'Always consult a qualified professional before starting a new workout program.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA7B0BF),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    final figure = ref.watch(characterFigureProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF283241)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              exercise.stillForFigure(figure),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.network(
                exercise.stillUrlForFigure(figure),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF00D4FF),
                  size: 22,
                ),
              ),
            ),
          ),
          title: Text(
            exercise.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '${exercise.group} • ${exercise.level}\n${exercise.equipment.join(', ')} • HD Video',
            style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 12),
          ),
          isThreeLine: true,
          trailing: FavoriteButton(id: exercise.id, name: exercise.name),
          onTap: () => context.push('/exercises/${exercise.id}'),
        ),
      ),
    );
  }

  Widget _buildBadge(
    String label,
    Color bg, {
    Color textColor = const Color(0xFFA7B0BF),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.id, required this.name});
  final String id, name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final saved = favorites.value?.contains(id) ?? false;

    return IconButton(
      tooltip: saved
          ? 'Remove $name from favorites'
          : 'Save $name to favorites',
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        color: saved ? const Color(0xFFB6FF3B) : const Color(0xFFA7B0BF),
      ),
      onPressed: () async {
        try {
          await ref.read(favoritesProvider.notifier).toggle(id);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not save favorite. Please retry.'),
              ),
            );
          }
        }
      },
    );
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});
  final String id;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/exercises');
    }
  }

  void _startExerciseSession(BuildContext context, Exercise exercise) {
    final routine = PlannedRoutine(
      id: 'single-${exercise.id}-${DateTime.now().millisecondsSinceEpoch}',
      name: exercise.name,
      category: exercise.movement,
      targetDurationMinutes: 15,
      isCustom: true,
      exercises: [
        PlannedExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          primaryMuscles: exercise.primary,
          sets: [
            const PlannedSet(
              setNumber: 1,
              targetReps: 10,
              targetRestSeconds: 60,
            ),
            const PlannedSet(
              setNumber: 2,
              targetReps: 10,
              targetRestSeconds: 60,
            ),
            const PlannedSet(
              setNumber: 3,
              targetReps: 10,
              targetRestSeconds: 60,
            ),
          ],
          notes: exercise.cue,
        ),
      ],
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutSessionScreen(routine: routine)),
    );
  }

  void _addToActiveWorkout(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) {
    final sessionState = ref.read(activeWorkoutSessionProvider);
    if (sessionState == null) {
      _startExerciseSession(context, exercise);
      return;
    }

    final newPlanned = PlannedExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      primaryMuscles: exercise.primary,
      sets: [
        const PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
        const PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
        const PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
      ],
      notes: exercise.cue,
    );

    final updatedExercises = List<PlannedExercise>.from(
      sessionState.routine.exercises,
    )..add(newPlanned);
    final updatedRoutine = sessionState.routine.copyWith(
      exercises: updatedExercises,
    );
    final updatedLogs =
        List<CompletedExercise>.from(sessionState.loggedExercises)..add(
          CompletedExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            primaryMuscles: exercise.primary,
            sets: [],
          ),
        );

    ref
        .read(activeWorkoutSessionProvider.notifier)
        .startSession(updatedRoutine);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${exercise.name} to active session!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise guide'),
        leading: BackButton(onPressed: () => _back(context)),
      ),
      body: SafeArea(
        child: ref
            .watch(exerciseCatalogProvider)
            .when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFB6FF3B)),
              ),
              error: (err, _) => PageBody(
                children: [
                  InfoCard(
                    title: 'Exercise not found',
                    message: '$err',
                    icon: Icons.error_outline,
                  ),
                  OutlinedButton(
                    onPressed: () => _back(context),
                    child: const Text('Open exercise library'),
                  ),
                ],
              ),
              data: (catalog) {
                final exercise = findExerciseById(catalog, id);
                if (exercise == null) {
                  return PageBody(
                    children: [
                      const InfoCard(
                        title: 'Exercise not found',
                        message: 'The requested exercise is not available in the library.',
                        icon: Icons.search_off,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/exercises'),
                        child: const Text('Open exercise library'),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${exercise.group} • ${exercise.level} • ${exercise.equipment.join(', ')}',
                                  style: const TextStyle(
                                    color: Color(0xFFA7B0BF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FavoriteButton(id: exercise.id, name: exercise.name),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // HD Video Player
                      ExerciseAnimationPlayer(
                        exercise: exercise,
                        animationId: exercise.animation,
                        primary: exercise.primary,
                        secondary: exercise.secondary,
                        exerciseName: exercise.name,
                        preferredFigure: ref.watch(characterFigureProvider),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB6FF3B),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () =>
                                _startExerciseSession(context, exercise),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Exercise',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _addToActiveWorkout(context, ref, exercise),
                            icon: const Icon(Icons.add),
                            label: const Text('Add to Workout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      if (exercise.description.isNotEmpty) ...[
                        Text(
                          'Overview',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.description,
                          style: const TextStyle(
                            color: Color(0xFFA7B0BF),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Step-by-step instructions
                      Text(
                        'Step by step',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (exercise.instructions.isNotEmpty)
                        for (int i = 0; i < exercise.instructions.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2430),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF283241),
                                    ),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFB6FF3B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    exercise.instructions[i],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                      else
                        const Text(
                          'Follow standard form for this movement.',
                          style: TextStyle(color: Color(0xFFA7B0BF)),
                        ),
                      const SizedBox(height: 16),

                      // Cues & Common Mistakes
                      if (exercise.cue.isNotEmpty) ...[
                        Card(
                          color: const Color(0xFF151B23),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFF283241)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Color(0xFFB6FF3B),
                                      size: 18,
                                    ),
                                    Text(
                                      'Form Cues & Breathing',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exercise.cue,
                                  style: const TextStyle(
                                    color: Color(0xFFA7B0BF),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (exercise.mistake.isNotEmpty) ...[
                        Card(
                          color: const Color(0xFF151B23),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFF283241)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFFFB547),
                                      size: 18,
                                    ),
                                    Text(
                                      'Common Mistakes & Safety',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exercise.mistake,
                                  style: const TextStyle(
                                    color: Color(0xFFA7B0BF),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Muscle Targeting Breakdown
                      Text(
                        'Muscle Targeting',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Primary: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB6FF3B),
                            ),
                          ),
                          Text(
                            exercise.primary.join(', '),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      if (exercise.secondary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Secondary: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00D4FF),
                              ),
                            ),
                            Text(
                              exercise.secondary.join(', '),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Interactive 2D Muscle Map with openGym vector geometry
                      MuscleMap(
                        initialGender: ref.watch(bodyDiagramFigureProvider),
                        sideBySideDefault: true,
                        primary: exercise.primary,
                        secondary: exercise.secondary,
                        allowGenderSwitch: true,
                      ),
                      const SizedBox(height: 20),

                      // Alternative movements
                      if (exercise.alternatives.isNotEmpty) ...[
                        Text(
                          'Alternative Movements',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (final altId in exercise.alternatives)
                          if (catalog.any((e) => e.id == altId))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                catalog.firstWhere((e) => e.id == altId).name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFA7B0BF),
                              ),
                              onTap: () => context.push('/exercises/$altId'),
                            ),
                        const SizedBox(height: 16),
                      ],

                      // Reference link section (for test & transparency)
                      Text(
                        'Reference',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Copy reference link'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: exercise.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
