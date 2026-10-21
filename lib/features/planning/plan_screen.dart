import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../profile/profile.dart';
import '../profile/profile_repository.dart';
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
              FilledButton.icon(
                onPressed: () => context.push('/exercises'),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Browse exercises'),
              ),
              const SizedBox(height: 20),
              if (profile.hasLimitations)
                const InfoCard(
                  title: 'Review movement first',
                  message: 'You reported limitations. Active slots are time to review suitable movement with a qualified professional, not clearance to exercise.',
                  icon: Icons.health_and_safety_outlined,
                ),
              ...List.generate(
                7,
                (i) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        schedule[i] == 'Recovery'
                            ? Icons.spa_outlined
                            : Icons.fitness_center,
                      ),
                      title: Text(Profile.weekdays[i]),
                      subtitle: Text(schedule[i]),
                      trailing: i == DateTime.now().weekday - 1
                          ? const Chip(label: Text('Today'))
                          : null,
                    ),
                  ),
                ),
              ),
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
}
