import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/page_body.dart';
import '../profile/profile_repository.dart';
import 'data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Character & Appearance (openGym Reference)
            _buildSectionHeader(
              context,
              title: 'Character & Appearance',
              subtitle: 'Anatomical model, animation drawings, and theme accents',
              icon: Icons.accessibility_new_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Body Diagram Setting (Male / Female)
                    _buildSettingRow(
                      context,
                      title: 'Body diagram',
                      subtitle:
                          'How the 2D muscle map is drawn. Controls front and back anatomical geometry.',
                      icon: Icons.person_outline,
                      iconTint: const Color(0xFF00D4FF),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'male',
                            label: Text('Male'),
                            icon: Icon(Icons.male_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: 'female',
                            label: Text('Female'),
                            icon: Icon(Icons.female_rounded, size: 16),
                          ),
                        ],
                        selected: {settings.bodyDiagram},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setBodyDiagram(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFF283241)),

                    // Exercise Drawings Setting (Male / Female)
                    _buildSettingRow(
                      context,
                      title: 'Exercise drawings',
                      subtitle:
                          'Where an exercise is drawn on both figures. Your workouts and logs stay exactly as they are.',
                      icon: Icons.fitness_center_rounded,
                      iconTint: const Color(0xFFFF5288),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'male',
                            label: Text('Male'),
                            icon: Icon(Icons.male_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: 'female',
                            label: Text('Female'),
                            icon: Icon(Icons.female_rounded, size: 16),
                          ),
                        ],
                        selected: {settings.exerciseFigure},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setExerciseFigure(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFF283241)),

                    // Theme selector
                    _buildSettingRow(
                      context,
                      title: 'App theme',
                      subtitle: 'Dark mode is optimized for low-light gym workouts.',
                      icon: Icons.dark_mode_outlined,
                      iconTint: const Color(0xFFA855F7),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'dark', label: Text('Dark')),
                          ButtonSegment(value: 'light', label: Text('Light')),
                          ButtonSegment(value: 'system', label: Text('System')),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setThemeMode(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFF283241)),

                    // Accent Color Swatches
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.palette_outlined,
                          color: Color(0xFFFFB547),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Accent color',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Highlights active muscles, buttons, and progress tags',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA7B0BF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildAccentSwatch(
                                    name: 'lime',
                                    color: const Color(0xFFB6FF3B),
                                    isSelected: settings.accentColor == 'lime',
                                    onTap: () => settingsNotifier.setAccentColor('lime'),
                                  ),
                                  _buildAccentSwatch(
                                    name: 'cyan',
                                    color: const Color(0xFF00D4FF),
                                    isSelected: settings.accentColor == 'cyan',
                                    onTap: () => settingsNotifier.setAccentColor('cyan'),
                                  ),
                                  _buildAccentSwatch(
                                    name: 'amber',
                                    color: const Color(0xFFFFB547),
                                    isSelected: settings.accentColor == 'amber',
                                    onTap: () => settingsNotifier.setAccentColor('amber'),
                                  ),
                                  _buildAccentSwatch(
                                    name: 'purple',
                                    color: const Color(0xFFA855F7),
                                    isSelected: settings.accentColor == 'purple',
                                    onTap: () => settingsNotifier.setAccentColor('purple'),
                                  ),
                                  _buildAccentSwatch(
                                    name: 'emerald',
                                    color: const Color(0xFF10B981),
                                    isSelected: settings.accentColor == 'emerald',
                                    onTap: () => settingsNotifier.setAccentColor('emerald'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Workout & Timing
            _buildSectionHeader(
              context,
              title: 'Before & During Workouts',
              subtitle: 'Timers, screen awake state, and video playback',
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.scale_outlined, color: Color(0xFF10B981)),
                    title: const Text('Weigh in before workouts', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Asks for body weight before launching a session. Off starts immediately.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                    ),
                    value: settings.weighInBeforeWorkout,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      settingsNotifier.setWeighIn(val);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFF283241)),
                  SwitchListTile(
                    secondary: const Icon(Icons.phone_android_rounded, color: Color(0xFFFFB547)),
                    title: const Text('Keep screen awake', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Prevents the phone from locking between sets during an active workout.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                    ),
                    value: settings.keepScreenAwake,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      settingsNotifier.setKeepScreenAwake(val);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFF283241)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingRow(
                      context,
                      title: 'Exercise animations',
                      subtitle: 'Default size of video clips during workout execution.',
                      icon: Icons.play_circle_outline,
                      iconTint: const Color(0xFF00D4FF),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'full', label: Text('Full')),
                          ButtonSegment(value: 'mini', label: Text('Small')),
                          ButtonSegment(value: 'off', label: Text('Hidden')),
                        ],
                        selected: {settings.exerciseAnimations},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setExerciseAnimations(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Units & Measurement
            _buildSectionHeader(
              context,
              title: 'Units & Measurement',
              subtitle: 'Metric/Imperial conversion and calendar week start',
              icon: Icons.straighten_outlined,
              iconColor: const Color(0xFFFFB547),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingRow(
                      context,
                      title: 'Measurement units',
                      subtitle: 'kg/cm for Metric, lb/in for Imperial system.',
                      icon: Icons.balance_outlined,
                      iconTint: const Color(0xFF10B981),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Metric', label: Text('Metric (kg)')),
                          ButtonSegment(value: 'Imperial', label: Text('Imperial (lb)')),
                        ],
                        selected: {settings.units},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setUnits(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFF283241)),
                    _buildSettingRow(
                      context,
                      title: 'First day of week',
                      subtitle: 'Weekly workout schedule and volume tallying reset.',
                      icon: Icons.calendar_today_outlined,
                      iconTint: const Color(0xFF00D4FF),
                      control: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Monday', label: Text('Monday')),
                          ButtonSegment(value: 'Sunday', label: Text('Sunday')),
                        ],
                        selected: {settings.firstDayOfWeek},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          settingsNotifier.setFirstDayOfWeek(values.single);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Profile & Sync
            _buildSectionHeader(
              context,
              title: 'Profile & Device Sync',
              subtitle: 'Goals, fitness background, and health sensors',
              icon: Icons.sync_rounded,
              iconColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite_outline, color: Color(0xFFFF5288)),
                title: const Text('Health & activity sync', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Permissions, source attribution, and device sensor data',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/health'),
              ),
            ),
            const SizedBox(height: 8),

            profileAsync.when(
              data: (p) => Column(
                children: [
                  _profileItem(
                    context,
                    title: 'Name & identity',
                    subtitle: p?.gender ?? 'Not specified',
                    step: 0,
                    icon: Icons.person_outline,
                  ),
                  _profileItem(
                    context,
                    title: 'Training experience',
                    subtitle: p?.level ?? 'Intermediate',
                    step: 2,
                    icon: Icons.fitness_center,
                  ),
                  _profileItem(
                    context,
                    title: 'Measurements & units',
                    subtitle: p != null
                        ? '${p.units} • ${p.age == null ? 'Age not set' : '${p.age} years'}'
                        : 'Body metrics and unit preferences',
                    step: 3,
                    icon: Icons.straighten,
                  ),
                  _profileItem(
                    context,
                    title: 'Goals',
                    subtitle: p?.goal ?? 'Build muscle',
                    step: 4,
                    icon: Icons.flag_outlined,
                  ),
                  _profileItem(
                    context,
                    title: 'Environment & equipment',
                    subtitle: p?.environment ?? 'Gym',
                    step: 5,
                    icon: Icons.home_outlined,
                  ),
                  _profileItem(
                    context,
                    title: 'Training availability',
                    subtitle: p != null
                        ? '${p.days} days/week • ${p.minutes} min'
                        : 'Workout schedule',
                    step: 6,
                    icon: Icons.calendar_month_outlined,
                  ),
                  _profileItem(
                    context,
                    title: 'Nutrition preferences',
                    subtitle: p?.diet ?? 'Standard balanced',
                    step: 7,
                    icon: Icons.restaurant_outlined,
                  ),
                  _profileItem(
                    context,
                    title: 'Limitations & personal guidance',
                    subtitle: p?.hasLimitations == true
                        ? 'Movement review requested'
                        : 'No restrictions',
                    step: 8,
                    icon: Icons.health_and_safety_outlined,
                  ),
                  _profileItem(
                    context,
                    title: 'Plan & personal targets',
                    subtitle: 'Review weekly outline and nutrition estimates',
                    step: 9,
                    icon: Icons.edit_calendar_outlined,
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Info Card: Storage
            const InfoCard(
              title: 'Private & Local Storage',
              message:
                  'All training logs, customized routines, and preferences are stored directly on your phone in private files.',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconTint,
    required Widget control,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconTint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: control,
        ),
      ],
    );
  }

  Widget _buildAccentSwatch({
    required String name,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: const Color(0xFF151B23), width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 20, color: Colors.black)
            : null,
      ),
    );
  }

  Widget _profileItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int step,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFA7B0BF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.push('/profile?step=$step'),
      ),
    ),
  );
}
