import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exercises/exercise.dart';
import '../exercises/muscle_map.dart';
import '../planning/initial_plan.dart';
import '../profile/profile.dart';
import '../profile/profile_repository.dart';
import '../settings/data/settings_repository.dart';
import 'custom/custom_workout_screen.dart';
import 'data/workout_generator.dart';
import 'data/workout_repository.dart';
import 'models/planned_workout.dart';
import 'models/progressive_overload.dart';
import 'models/workout_session.dart';
import 'session/workout_session_screen.dart';

class WorkoutHomeScreen extends ConsumerStatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  ConsumerState<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends ConsumerState<WorkoutHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMuscleMapDialog(BuildContext context, List<Exercise> catalog) {
    final counts = <String, int>{};
    for (final m in muscleGroups) {
      counts[m] = catalog.where((e) => e.matches(muscle: m)).length;
    }

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
                initialGender: ref.read(bodyDiagramFigureProvider),
                sideBySideDefault: true,
                exerciseCounts: counts,
                onSelect: (selected) {
                  Navigator.of(ctx).pop();
                  context.push('/exercises');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startRoutine(BuildContext context, PlannedRoutine routine) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutSessionScreen(routine: routine)),
    );
  }

  void _duplicateRoutine(BuildContext context, PlannedRoutine routine) async {
    final copy = routine.copyWith(
      id: 'routine-${DateTime.now().millisecondsSinceEpoch}',
      name: '${routine.name} (Copy)',
      isCustom: true,
    );
    await ref.read(workoutTemplatesProvider.notifier).saveTemplate(copy);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${routine.name}" to My Plans'),
          backgroundColor: const Color(0xFF1C2430),
        ),
      );
    }
  }

  void _startQuickWorkout(BuildContext context, List<Exercise> catalog) {
    // Generate a spontaneous full-body session
    final defaultExercises = catalog.take(4).map((ex) {
      return PlannedExercise(
        exerciseId: ex.id,
        exerciseName: ex.name,
        primaryMuscles: ex.primary,
        sets: [
          const PlannedSet(setNumber: 1, targetReps: 10, targetRestSeconds: 60),
          const PlannedSet(setNumber: 2, targetReps: 10, targetRestSeconds: 60),
          const PlannedSet(setNumber: 3, targetReps: 10, targetRestSeconds: 60),
        ],
      );
    }).toList();

    final routine = PlannedRoutine(
      id: 'quick-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Quick Workout Session',
      category: 'Full-body strength',
      targetDurationMinutes: 25,
      isCustom: true,
      exercises: defaultExercises,
    );

    _startRoutine(context, routine);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final prs = ref.watch(personalRecordsProvider);

    final catalog = catalogAsync.value ?? [];
    final templates = templatesAsync.value ?? [];
    final sessions = sessionsAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: const Color(0xFF0B0F14),
            title: Text(
              'WORKOUTS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Workout History',
                icon: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFFA7B0BF),
                ),
                onPressed: () => context.push('/workouts/history'),
              ),
              IconButton(
                tooltip: 'Create Routine',
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFFB6FF3B),
                ),
                onPressed: () => context.push('/workouts/custom'),
              ),
            ],
          ),

          // Main Body Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. TODAY'S WORKOUT HERO CARD
                profileAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Color(0xFFB6FF3B),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (profile) {
                    return _buildTodayWorkoutCard(context, profile, catalog);
                  },
                ),
                const SizedBox(height: 24),

                // 2. WEEKLY WORKOUT SCHEDULE
                if (profileAsync.hasValue && profileAsync.value != null) ...[
                  _buildWeeklySchedule(context, profileAsync.value!),
                  const SizedBox(height: 24),
                ],

                // 3. EXPLORE EXERCISES HUB
                _buildExploreExercisesSection(context, catalog),
                const SizedBox(height: 24),

                // 4. QUICK WORKOUT ACTIONS
                _buildQuickWorkoutSection(context, catalog),
                const SizedBox(height: 24),

                // 5. MY PLANS & STARTER ROUTINES
                _buildRoutinesSection(context, templates),
                const SizedBox(height: 24),

                // 6. WORKOUT PROGRESS & PR TICKER
                _buildProgressAnalyticsSection(context, sessions, prs),
                const SizedBox(height: 36),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Section 1: Today's Workout Hero Card
  // ===========================================================================
  Widget _buildTodayWorkoutCard(
    BuildContext context,
    Profile? profile,
    List<Exercise> catalog,
  ) {
    final todayIndex = DateTime.now().weekday - 1;
    final schedule = profile != null
        ? InitialPlan.scheduleFor(profile)
        : List.filled(7, 'Full-body strength');
    final todayKind = schedule[todayIndex];

    PlannedRoutine todayRoutine;
    if (profile != null && catalog.isNotEmpty) {
      todayRoutine = WorkoutGenerator.generateRoutineForDay(
        profile: profile,
        sessionKind: todayKind,
        catalog: catalog,
        dayIndex: todayIndex,
      );
    } else {
      todayRoutine = const PlannedRoutine(
        id: 'default-today',
        name: 'Full Body Foundation',
        category: 'Full-body strength',
        targetDurationMinutes: 30,
        exercises: [],
      );
    }

    final isRecovery = todayKind == 'Recovery';
    final exerciseCount = todayRoutine.exercises.length;
    final durationMin = profile?.minutes ?? todayRoutine.targetDurationMinutes;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRecovery
              ? [const Color(0xFF142C30), const Color(0xFF0F1B24)]
              : [const Color(0xFF1B2E1E), const Color(0xFF151B23)],
        ),
        border: Border.all(
          color: isRecovery
              ? const Color(0xFF00D4FF).withValues(alpha: 0.3)
              : const Color(0xFFB6FF3B).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isRecovery
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                        : const Color(0xFFB6FF3B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isRecovery ? 'ACTIVE RECOVERY' : "TODAY'S WORKOUT",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isRecovery
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFFB6FF3B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$durationMin min',
                style: const TextStyle(
                  color: Color(0xFFA7B0BF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            todayRoutine.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRecovery
                ? 'Gentle mobility and tissue restoration day.'
                : '$exerciseCount targeted movements • ${todayRoutine.allTargetMuscles.join(', ')}',
            style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _startRoutine(context, todayRoutine),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isRecovery ? 'Start Mobility' : 'Start Workout',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF283241)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomWorkoutScreen(initialRoutine: todayRoutine),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Customize',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Section 2: Weekly Schedule Strip
  // ===========================================================================
  Widget _buildWeeklySchedule(BuildContext context, Profile profile) {
    final schedule = InitialPlan.scheduleFor(profile);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WEEKLY SCHEDULE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFFA7B0BF),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(7, (i) {
              final isToday = i == todayIndex;
              final isSelected = i == _selectedDayIndex;
              final kind = schedule[i];
              final isRecovery = kind == 'Recovery';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF1B2E1E)
                          : isSelected
                          ? const Color(0xFF1C2430)
                          : const Color(0xFF151B23),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFFB6FF3B)
                            : isSelected
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFF283241),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNames[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isToday
                                ? const Color(0xFFB6FF3B)
                                : const Color(0xFFA7B0BF),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          isRecovery
                              ? Icons.spa_outlined
                              : Icons.fitness_center_rounded,
                          size: 18,
                          color: isRecovery
                              ? const Color(0xFF00D4FF)
                              : isToday
                              ? const Color(0xFFB6FF3B)
                              : Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isRecovery ? 'Rest' : 'Train',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isRecovery
                                ? const Color(0xFF00D4FF)
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Section 3: Explore Exercises Hub
  // ===========================================================================
  Widget _buildExploreExercisesSection(
    BuildContext context,
    List<Exercise> catalog,
  ) {
    const popularMuscles = [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Quadriceps',
      'Hamstrings',
      'Abdominals',
    ];
    const popularEquipment = [
      'Bodyweight',
      'Dumbbells',
      'Barbell',
      'Cable',
      'Machine',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'EXPLORE EXERCISES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFFA7B0BF),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/exercises'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00D4FF),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'All 6,554+ >',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Interactive Muscle Map Banner
        InkWell(
          onTap: () => _openMuscleMapDialog(context, catalog),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF283241)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6FF3B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.accessibility_new_rounded,
                    color: Color(0xFFB6FF3B),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Muscle Map',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap any muscle group on 2D body model',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA7B0BF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFA7B0BF),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Popular Muscle Group Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: popularMuscles.map((muscle) {
            final count = catalog
                .where((e) => e.matches(muscle: muscle))
                .length;
            return ActionChip(
              backgroundColor: const Color(0xFF151B23),
              side: const BorderSide(color: Color(0xFF283241)),
              label: Text('$muscle ($count)'),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
              onPressed: () => context.push('/exercises'),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Popular Equipment Filter Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: popularEquipment.map((eq) {
            return ActionChip(
              backgroundColor: const Color(0xFF1C2430),
              side: const BorderSide(color: Color(0xFF283241)),
              avatar: const Icon(
                Icons.fitness_center_rounded,
                size: 14,
                color: Color(0xFF00D4FF),
              ),
              label: Text(eq),
              labelStyle: const TextStyle(
                color: Color(0xFFA7B0BF),
                fontSize: 11,
              ),
              onPressed: () => context.push('/exercises'),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // Section 4: Quick Workout Section
  // ===========================================================================
  Widget _buildQuickWorkoutSection(
    BuildContext context,
    List<Exercise> catalog,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF283241)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB547).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFFFFB547),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK WORKOUT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Unscheduled session or instant routine',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA7B0BF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2430),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF283241)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _startQuickWorkout(context, catalog),
                    icon: Icon(
                      Icons.play_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Instant Session',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF283241)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.push('/workouts/custom'),
                    icon: const Icon(Icons.add, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Build Custom',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Section 5: My Plans & Starter Routines
  // ===========================================================================
  Widget _buildRoutinesSection(
    BuildContext context,
    List<PlannedRoutine> routines,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'WORKOUT PLANS & ROUTINES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFFA7B0BF),
                ),
              ),
            ),
            IconButton(
              tooltip: 'New Routine',
              icon: const Icon(Icons.add, color: Color(0xFFB6FF3B)),
              onPressed: () => context.push('/workouts/custom'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (routines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Loading starter templates...',
              style: TextStyle(color: Color(0xFFA7B0BF)),
            ),
          )
        else
          ...routines.map((routine) => _buildRoutineCard(context, routine)),
      ],
    );
  }

  Widget _buildRoutineCard(BuildContext context, PlannedRoutine routine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF283241)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2430),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    routine.category,
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${routine.exercises.length} Exercises • ~${routine.targetDurationMinutes} min • ${routine.totalSets} Sets',
              style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _startRoutine(context, routine),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Start',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF283241)),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomWorkoutScreen(initialRoutine: routine),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Customize',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Duplicate routine',
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Color(0xFFA7B0BF),
                  ),
                  onPressed: () => _duplicateRoutine(context, routine),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Section 6: Workout Progress & PR Ticker
  // ===========================================================================
  Widget _buildProgressAnalyticsSection(
    BuildContext context,
    List<WorkoutSession> sessions,
    Map<String, PersonalRecord> prs,
  ) {
    final totalVolume = sessions.fold<double>(
      0.0,
      (sum, s) => sum + s.totalVolumeKg,
    );
    final totalDurationMin =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF283241)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'WORKOUT PROGRESS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFFA7B0BF),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/workouts/history'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00D4FF),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'History >',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat(
                'SESSIONS',
                '${sessions.length}',
                const Color(0xFFB6FF3B),
              ),
              _buildProgressStat(
                'VOLUME',
                '${totalVolume.toStringAsFixed(0)} kg',
                const Color(0xFF00D4FF),
              ),
              _buildProgressStat(
                'TIME',
                '${totalDurationMin}m',
                const Color(0xFF35D399),
              ),
              _buildProgressStat(
                'PRs',
                '${prs.length}',
                const Color(0xFFFFB547),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA7B0BF),
          ),
        ),
      ],
    );
  }
}
