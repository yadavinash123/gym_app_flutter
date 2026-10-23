import 'package:flutter/material.dart';

enum ReminderCategory {
  workout,
  hydration,
  meals,
  recovery,
}

@immutable
class ReminderPreference {
  const ReminderPreference({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7], // 1=Mon, 7=Sun
  });

  final String id;
  final ReminderCategory category;
  final String title;
  final String description;
  final int hour; // 0 - 23
  final int minute; // 0 - 59
  final bool isEnabled;
  final List<int> daysOfWeek;

  String get timeFormatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  ReminderPreference copyWith({
    String? id,
    ReminderCategory? category,
    String? title,
    String? description,
    int? hour,
    int? minute,
    bool? isEnabled,
    List<int>? daysOfWeek,
  }) =>
      ReminderPreference(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        isEnabled: isEnabled ?? this.isEnabled,
        daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'description': description,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
        'daysOfWeek': daysOfWeek,
      };

  factory ReminderPreference.fromJson(Map<String, dynamic> json) =>
      ReminderPreference(
        id: json['id'] as String,
        category: ReminderCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ReminderCategory.workout,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        hour: (json['hour'] as num?)?.toInt() ?? 8,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        isEnabled: json['isEnabled'] as bool? ?? true,
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
      );

  static List<ReminderPreference> defaultSchedules() => [
        const ReminderPreference(
          id: 'rem_workout',
          category: ReminderCategory.workout,
          title: 'Daily Training Session',
          description: 'Time to forge your strength! Review today’s planned routine.',
          hour: 7,
          minute: 30,
          isEnabled: true,
        ),
        const ReminderPreference(
          id: 'rem_hydration',
          category: ReminderCategory.hydration,
          title: 'Hydration Check-in',
          description: 'Stay fueled and hydrated. Take a water break.',
          hour: 14,
          minute: 0,
          isEnabled: true,
        ),
        const ReminderPreference(
          id: 'rem_meals',
          category: ReminderCategory.meals,
          title: 'Daily Nutrition Review',
          description: 'Log your meals to stay on track with your energy & protein targets.',
          hour: 20,
          minute: 0,
          isEnabled: true,
        ),
        const ReminderPreference(
          id: 'rem_recovery',
          category: ReminderCategory.recovery,
          title: 'Recovery Wind-Down',
          description: 'Aim for 7–9 hours of sleep tonight for optimal muscle protein synthesis.',
          hour: 22,
          minute: 15,
          isEnabled: false,
        ),
      ];
}
