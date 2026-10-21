import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../profile/profile_repository.dart';
import '../planning/initial_plan.dart';
import '../../shared/widgets/page_body.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
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
                      profile == null ? 'Create my profile' : 'Edit my profile',
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
              OutlinedButton(
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
              const SizedBox(height: 20),
            ],
            const InfoCard(
              title: 'A fresh start',
              message: 'No activity recorded yet. Workout and nutrition logging will arrive in the next development phases.',
              icon: Icons.insights_outlined,
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
