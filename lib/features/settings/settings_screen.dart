import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../profile/profile_repository.dart';
import '../../shared/widgets/page_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Profile & preferences'),
      leading: IconButton(
        tooltip: 'Back to home',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/home'),
      ),
    ),
    body: ref
        .watch(profileProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry loading profile'),
            ),
          ),
          data: (p) => PageBody(
            children: [
              Text(
                p?.name ?? 'Make it yours',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Changes stay in the editor until you review and save the plan. Cancel keeps your saved profile.',
              ),
              const SizedBox(height: 24),
              if (p == null)
                FilledButton(
                  onPressed: () => context.push('/onboarding'),
                  child: const Text('Create my profile'),
                )
              else ...[
                _item(
                  context,
                  'Name & identity',
                  p.gender,
                  0,
                  Icons.person_outline,
                ),
                _item(
                  context,
                  'Training experience',
                  p.level,
                  2,
                  Icons.fitness_center,
                ),
                _item(
                  context,
                  'Measurements & units',
                  '${p.units} • ${p.age == null ? 'Age not set' : '${p.age} years'}',
                  3,
                  Icons.straighten,
                ),
                _item(
                  context,
                  'Goals',
                  [
                    p.goal,
                    if (p.secondaryGoal != null) p.secondaryGoal!,
                  ].join(' • '),
                  4,
                  Icons.flag_outlined,
                ),
                _item(
                  context,
                  'Environment & equipment',
                  '${p.environment} • ${p.equipment.isEmpty ? 'Bodyweight only' : p.equipment.join(', ')}',
                  5,
                  Icons.home_outlined,
                ),
                _item(
                  context,
                  'Training availability',
                  '${p.days} days/week • ${p.minutes} min • ${p.trainingTime}',
                  6,
                  Icons.calendar_month_outlined,
                ),
                _item(
                  context,
                  'Nutrition preferences',
                  '${p.diet} • ${p.meals} meals/day • ${p.cuisine}',
                  7,
                  Icons.restaurant_outlined,
                ),
                _item(
                  context,
                  'Limitations & personal guidance',
                  p.hasLimitations
                      ? 'Movement review requested'
                      : 'No movement restrictions recorded',
                  8,
                  Icons.health_and_safety_outlined,
                ),
                _item(
                  context,
                  'Plan & personal targets',
                  'Review weekly outline and nutrition estimates',
                  9,
                  Icons.edit_calendar_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.sync_rounded),
                      title: const Text('Health & activity sync'),
                      subtitle: const Text('Permissions, source attribution, and device sensor data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/health'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const InfoCard(
                title: 'Stored on your phone',
                message: 'Your profile and plan stay in private app files. Clearing app data or uninstalling can remove them. Portable backup export is not yet available.',
                icon: Icons.phone_android_outlined,
              ),
            ],
          ),
        ),
  );

  Widget _item(
    BuildContext context,
    String title,
    String subtitle,
    int step,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/profile?step=$step'),
      ),
    ),
  );
}
