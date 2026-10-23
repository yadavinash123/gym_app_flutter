import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_repository.dart';
import '../models/notification_schedule.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  List<ReminderPreference>? _reminders;
  bool _hasChanges = false;
  String? _statusBanner;

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Alerts'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFFB6FF3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: remindersAsync.when(
        data: (loaded) {
          _reminders ??= List.from(loaded);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151B23),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF00D4FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Habit Reminders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Reminders are scheduled offline on your device to keep you disciplined with training, hydration, and recovery.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA7B0BF),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_statusBanner != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6FF3B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB6FF3B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFFB6FF3B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusBanner!,
                          style: const TextStyle(
                            color: Color(0xFFB6FF3B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'SCHEDULED REMINDERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFA7B0BF),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_reminders!.length, (index) {
                final reminder = _reminders![index];
                return _buildReminderCard(index, reminder);
              }),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.notifications_none_rounded, size: 18),
                label: const Text('Test Notification Alert'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF151B23),
                      content: Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded,
                              color: Color(0xFFB6FF3B), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FitForge Reminder',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _reminders!.firstWhere((r) => r.isEnabled,
                                          orElse: () => _reminders!.first)
                                      .title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA7B0BF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Failed to load reminder settings: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(int index, ReminderPreference reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.isEnabled
              ? const Color(0xFFB6FF3B).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForCategory(reminder.category),
                    size: 20,
                    color: reminder.isEnabled
                        ? const Color(0xFFB6FF3B)
                        : const Color(0xFFA7B0BF),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Switch(
                value: reminder.isEnabled,
                activeColor: const Color(0xFFB6FF3B),
                onChanged: (val) {
                  setState(() {
                    _reminders![index] = reminder.copyWith(isEnabled: val);
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reminder.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA7B0BF),
            ),
          ),
          const SizedBox(height: 14),
          // Time Picker button
          InkWell(
            onTap: reminder.isEnabled ? () => _pickTime(index, reminder) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2430),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: Color(0xFF00D4FF)),
                  const SizedBox(width: 8),
                  Text(
                    reminder.timeFormatted,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: reminder.isEnabled ? Colors.white : const Color(0xFFA7B0BF),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: Color(0xFFA7B0BF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(int index, ReminderPreference reminder) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminder.timeOfDay,
    );
    if (picked != null) {
      setState(() {
        _reminders![index] = reminder.copyWith(
          hour: picked.hour,
          minute: picked.minute,
        );
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_reminders == null) return;
    final repo = ref.read(progressRepositoryProvider);
    await repo.saveReminderPreferences(_reminders!);
    ref.invalidate(reminderPreferencesProvider);
    setState(() {
      _hasChanges = false;
      _statusBanner = 'Reminder preferences saved successfully';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _statusBanner = null);
    });
  }

  IconData _iconForCategory(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.workout:
        return Icons.fitness_center_rounded;
      case ReminderCategory.hydration:
        return Icons.water_drop_rounded;
      case ReminderCategory.meals:
        return Icons.restaurant_rounded;
      case ReminderCategory.recovery:
        return Icons.bedtime_rounded;
    }
  }
}
