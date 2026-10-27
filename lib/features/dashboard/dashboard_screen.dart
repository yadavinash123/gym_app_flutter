import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exercises/exercise.dart';
import '../profile/profile_repository.dart';
import '../health/data/health_repository.dart';
import '../planning/initial_plan.dart';
import '../workouts/data/workout_generator.dart';
import '../workouts/data/workout_repository.dart';
import '../workouts/session/workout_session_screen.dart';
import '../../shared/widgets/page_body.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutSessionsProvider).value ?? [];
    final health = ref.watch(todayHealthSummaryProvider);

    return ref
        .watch(profileProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => PageBody(
            children: [
              const InfoCard(
                title: 'Your profile could not be read',
                message: 'Your files have been preserved. Retry loading before making changes.',
                icon: Icons.folder_off_outlined,
              ),
              TextButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (profile) => PageBody(
            children: [
              Text(
                'BUILD YOUR NEXT CHAPTER',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile == null
                    ? 'Your journey\nstarts here.'
                    : 'Welcome back,\n${profile.name}.',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text('Small steps. Consistent effort. Lasting progress.'),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D4020), Color(0xFF142C30)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 48,
                      color: Color(0xFFB6FF3B),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profile?.goal ?? 'Designed around you',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile == null
                          ? 'Set your experience, training schedule, and first goal.'
                          : '${profile.level} • ${profile.environment}\n${profile.days} training days per week',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.push(
                        profile == null ? '/onboarding' : '/settings',
                      ),
                      child: Text(
                        profile == null
                            ? 'Create my profile'
                            : 'Edit my profile',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (profile != null) ...[
                InfoCard(
                  title: 'Today’s plan',
                  message:
                      '${InitialPlan.scheduleFor(profile)[DateTime.now().weekday - 1]} • ${profile.minutes} minutes available\n${profile.hasLimitations ? 'Review suitable movement with a qualified professional before starting.' : 'This is your plan, not a completed workout.'}',
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB6FF3B),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    final schedule = InitialPlan.scheduleFor(profile);
                    final todayIndex = DateTime.now().weekday - 1;
                    final kind = schedule[todayIndex];
                    final catalog =
                        ref.read(exerciseCatalogProvider).value ?? [];
                    if (catalog.isNotEmpty) {
                      final routine = WorkoutGenerator.generateRoutineForDay(
                        profile: profile,
                        sessionKind: kind,
                        catalog: catalog,
                        dayIndex: todayIndex,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutSessionScreen(routine: routine),
                        ),
                      );
                    } else {
                      context.go('/workouts');
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.go('/workouts'),
                  child: const Text('View weekly outline'),
                ),
                const SizedBox(height: 20),
                InfoCard(
                  title: 'Daily nutrition targets',
                  message: _nutritionSummary(
                    profile.calorieTarget,
                    profile.proteinTarget,
                    NutritionEstimate.forProfile(profile),
                  ),
                  icon: Icons.restaurant_outlined,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.go('/nutrition'),
                  icon: const Icon(Icons.restaurant_outlined),
                  label: const Text('Open Daily Nutrition Log'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1C2430)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB6FF3B)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_walk_rounded,
                                    color: Color(0xFFB6FF3B),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'DAILY ACTIVITY & HEALTH',
                                    style: TextStyle(
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Color(0xFFB6FF3B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/health'),
                            child: const Text('Details →'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${health.steps}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  'steps (${health.stepSource.shortBadge})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA7B0BF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    health.restingHeartRateBpm != null
                                        ? '${health.restingHeartRateBpm}'
                                        : '--',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'bpm resting HR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA7B0BF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    health.sleepDurationMinutes != null
                                        ? '${(health.sleepDurationMinutes! / 60).toStringAsFixed(1)}h'
                                        : '--',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'sleep',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA7B0BF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (sessions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1C2430)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT WORKOUT',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFFB6FF3B),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/workouts/history'),
                            child: const Text('History →'),
                          ),
                        ],
                      ),
                      Text(
                        sessions.first.routineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${sessions.first.durationSeconds ~/ 60}m duration • ${sessions.first.totalVolumeKg.toStringAsFixed(0)} kg volume • ~${sessions.first.estimatedCalories} kcal',
                        style: const TextStyle(
                          color: Color(0xFFA7B0BF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const InfoCard(
                  title: 'A fresh start',
                  message: 'No activity recorded yet. Workout and nutrition logging will arrive in the next development phases.',
                  icon: Icons.insights_outlined,
                ),
                const SizedBox(height: 16),
              ],
              // AI Coach Advisor Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF151B23), Color(0xFF182433)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF00D4FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI COACH & ADVISOR',
                          style: TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF00D4FF),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/coach'),
                          child: const Text('Open Coach →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Evidence-Based Fitness Guidance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask about optimal set volume, daily macro distribution, or check your recovery status with evidence-based offline rules or BYOK AI.',
                      style: TextStyle(
                        color: Color(0xFFA7B0BF),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const InfoCard(
                title: 'On your phone. Under your control.',
                message: 'Your profile is saved as a private JSON file. No account or database server is required.',
                icon: Icons.phone_android_outlined,
              ),
            ],
          ),
        );
  }
}

String _nutritionSummary(
  double? calories,
  double? protein,
  NutritionEstimate estimate,
) {
  final energy = calories ?? estimate.maintenanceKcal;
  final calorieText = energy == null
      ? 'Calories: not set'
      : '${energy.round()} kcal/day (${calories == null ? 'estimated maintenance' : 'personal target'})';
  final proteinText = protein != null
      ? '${protein.round()} g protein/day (personal target)'
      : estimate.proteinLow == null
      ? 'Protein: not set'
      : '${estimate.proteinLow!.round()}–${estimate.proteinHigh!.round()} g protein/day (general adult range)';
  return '$calorieText\n$proteinText\nThese are planning targets, not logged intake.';
}
