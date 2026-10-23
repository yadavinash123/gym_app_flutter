import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/coach/presentation/coach_history_screen.dart';
import '../features/coach/presentation/coach_screen.dart';
import '../features/coach/presentation/coach_settings_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/exercises/exercise_screens.dart';
import '../features/health/screens/health_permissions_screen.dart';
import '../features/health/screens/health_screen.dart';
import '../features/health/screens/manual_health_entry_screen.dart';
import '../features/nutrition/data/nutrition_repository.dart';
import '../features/nutrition/screens/custom_food_screen.dart';
import '../features/nutrition/screens/food_search_screen.dart';
import '../features/nutrition/screens/nutrition_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_repository.dart';
import '../features/planning/plan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/workouts/history/workout_history_screen.dart';
import '../features/workouts/custom/custom_workout_screen.dart';
import '../shared/widgets/page_body.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const StartupScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/profile',
        builder: (_, state) => ProfileScreen(
          initialStep:
              int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/exercises',
        builder: (_, _) => const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (_, state) =>
            ExerciseDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/workouts/history',
        builder: (_, _) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: '/workouts/custom',
        builder: (_, _) => const CustomWorkoutScreen(),
      ),
      GoRoute(
        path: '/nutrition/search',
        builder: (_, _) => FoodSearchScreen(date: todayIsoDate()),
      ),
      GoRoute(
        path: '/nutrition/custom',
        builder: (_, _) => const CustomFoodScreen(),
      ),
      GoRoute(
        path: '/health',
        builder: (_, state) =>
            HealthScreen(initialDate: state.uri.queryParameters['date']),
      ),
      GoRoute(
        path: '/health/permissions',
        builder: (_, _) => const HealthPermissionsScreen(),
      ),
      GoRoute(
        path: '/health/log',
        builder: (_, state) => ManualHealthEntryScreen(
          date: state.uri.queryParameters['date'] ?? todayIsoDate(),
        ),
      ),
      GoRoute(
        path: '/coach/settings',
        builder: (_, _) => const CoachSettingsScreen(),
      ),
      GoRoute(
        path: '/coach/history',
        builder: (_, _) => const CoachHistoryScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/workouts', builder: (_, _) => const PlanScreen()),
          GoRoute(
            path: '/nutrition',
            builder: (_, _) => const NutritionScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, _) => const PlannedFeature(
              title: 'Progress',
              icon: Icons.insights_outlined,
            ),
          ),
          GoRoute(
            path: '/coach',
            builder: (_, state) => const CoachScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class FitForgeApp extends ConsumerWidget {
  const FitForgeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'FitForge AI',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(profile.value == null ? '/onboarding' : '/home');
        }
      });
    }
    return Scaffold(
      body: profile.hasError
          ? PageBody(
              children: [
                const InfoCard(
                  title: 'Unable to open your profile',
                  message: 'Existing data has been preserved. Please retry.',
                  icon: Icons.error_outline,
                ),
                FilledButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('Retry'),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.initialStep = 0});
  final int initialStep;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(profileProvider)
      .when(
        data: (profile) => OnboardingScreen(
          initial: profile,
          initialStep: profile == null ? 0 : initialStep,
        ),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Center(
            child: TextButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry loading profile'),
            ),
          ),
        ),
      );
}

const destinations = [
  (path: '/home', label: 'Home', icon: Icons.home_outlined),
  (path: '/workouts', label: 'Workouts', icon: Icons.fitness_center_rounded),
  (path: '/nutrition', label: 'Nutrition', icon: Icons.restaurant_outlined),
  (path: '/progress', label: 'Progress', icon: Icons.insights_outlined),
  (path: '/coach', label: 'AI', icon: Icons.auto_awesome),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hideAppBar = path.startsWith('/coach');
    final selectedIndex = destinations.indexWhere((d) => d.path == path);

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text(
                'FITFORGE',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
              ),
              actions: [
                IconButton(
                  tooltip: 'Profile settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
      body: SafeArea(top: !hideAppBar, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 2,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        destinations: destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class PlannedFeature extends StatelessWidget {
  const PlannedFeature({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 24),
      InfoCard(
        title: 'Coming in a later phase',
        message:
            '$title is not implemented in this foundation build. Your profile and local storage are ready.',
        icon: icon,
      ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: () => context.go('/home'),
        child: const Text('Back to home'),
      ),
    ],
  );
}
