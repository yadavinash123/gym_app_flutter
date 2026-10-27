import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exercises/exercise.dart';
import '../profile/profile.dart';
import '../profile/profile_repository.dart';
import '../workouts/data/workout_generator.dart';
import '../workouts/session/workout_session_screen.dart';
import '../../shared/widgets/page_body.dart';
import 'initial_plan.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(profileProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: const Text('Retry loading plan'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return PageBody(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/exercises'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Browse exercises'),
                ),
                const SizedBox(height: 20),
                const InfoCard(
                  title: 'Start with your preferences',
                  message: 'Create a profile to build your weekly training outline offline.',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.push('/onboarding'),
                  child: const Text('Create my profile'),
                ),
              ],
            );
          }
          final schedule = InitialPlan.scheduleFor(profile);
          final todayIndex = DateTime.now().weekday - 1;
          final todayKind = schedule[todayIndex];

          return PageBody(
            children: [
              Text(
                'Your weekly outline',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '${profile.goal} • ${profile.days} days • ${profile.minutes} min/session',
              ),
              const SizedBox(height: 12),
              Text(
                '${profile.environment} • ${profile.trainingTime}\nEquipment: ${profile.equipment.isEmpty ? 'Bodyweight only' : profile.equipment.join(', ')}',
              ),
              const SizedBox(height: 20),

              // Action Bar
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB6FF3B),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _startRoutineForDay(
                      context,
                      ref,
                      profile,
                      todayKind,
                      todayIndex,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      todayKind == 'Recovery'
                          ? 'Start Active Recovery'
                          : 'Start Today ($todayKind)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/workouts/history'),
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('Workout History'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/workouts/custom'),
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Custom Routines'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/exercises'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Browse exercises'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (profile.hasLimitations)
                const InfoCard(
                  title: 'Review movement first',
                  message: 'You reported limitations. Active slots are time to review suitable movement with a qualified professional, not clearance to exercise.',
                  icon: Icons.health_and_safety_outlined,
                ),

              ...List.generate(7, (i) {
                final isToday = i == todayIndex;
                final kind = schedule[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: isToday
                        ? const Color(0xFF1B2A1E)
                        : const Color(0xFF151B23),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isToday
                            ? const Color(0xFFB6FF3B)
                            : const Color(0xFF1C2430),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        kind == 'Recovery'
                            ? Icons.spa_outlined
                            : Icons.fitness_center,
                        color: isToday
                            ? const Color(0xFFB6FF3B)
                            : Colors.white70,
                      ),
                      title: Text(
                        Profile.weekdays[i],
                        style: TextStyle(
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(kind),
                      trailing: isToday
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB6FF3B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _previewOrStartRoutine(
                        context,
                        ref,
                        profile,
                        kind,
                        i,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/profile?step=9'),
                child: const Text('Edit weekly outline'),
              ),
              const SizedBox(height: 16),
              const InfoCard(
                title: 'A starting structure',
                message: 'This outline is a planning aid. Explore the exercise library for movement guides. Automatic exercise selection, session timers and workout logging are planned for the next phase.',
                icon: Icons.info_outline,
              ),
            ],
          );
        },
      );

  void _previewOrStartRoutine(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String sessionKind,
    int dayIndex,
  ) {
    final catalogAsync = ref.read(exerciseCatalogProvider);
    final catalog = catalogAsync.value ?? [];
    if (catalog.isEmpty) return;

    final routine = WorkoutGenerator.generateRoutineForDay(
      profile: profile,
      sessionKind: sessionKind,
      catalog: catalog,
      dayIndex: dayIndex,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Profile.weekdays[dayIndex].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFB6FF3B),
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routine.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${routine.exercises.length} Exercises • ~${routine.targetDurationMinutes} min',
                  style: const TextStyle(color: Color(0xFFA7B0BF)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PLANNED EXERCISES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA7B0BF),
                  ),
                ),
                const SizedBox(height: 8),
                ...routine.exercises.map((pEx) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2430),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pEx.exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pEx.sets.length} sets × ${pEx.sets.first.targetReps} reps • ${pEx.primaryMuscles.join(', ')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA7B0BF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 18),
                          onPressed: () {
                            context.push('/exercises/${pEx.exerciseId}');
                          },
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB6FF3B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutSessionScreen(routine: routine),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'START WORKOUT SESSION',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startRoutineForDay(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String sessionKind,
    int dayIndex,
  ) {
    final catalogAsync = ref.read(exerciseCatalogProvider);
    final catalog = catalogAsync.value ?? [];
    if (catalog.isEmpty) return;

    final routine = WorkoutGenerator.generateRoutineForDay(
      profile: profile,
      sessionKind: sessionKind,
      catalog: catalog,
      dayIndex: dayIndex,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutSessionScreen(routine: routine)),
    );
  }
}
