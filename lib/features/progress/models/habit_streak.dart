import 'package:flutter/foundation.dart';

enum HabitType { workouts, nutrition, hydration, overall }

@immutable
class HabitStreak {
  const HabitStreak({
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
    this.activeDates = const {},
    this.weeklyAdherenceRate = 0.0, // 0.0 to 100.0%
  });

  final HabitType type;
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate; // YYYY-MM-DD
  final Set<String> activeDates; // YYYY-MM-DD
  final double weeklyAdherenceRate;

  String get typeDisplayName {
    switch (type) {
      case HabitType.workouts:
        return 'Workouts';
      case HabitType.nutrition:
        return 'Nutrition';
      case HabitType.hydration:
        return 'Hydration';
      case HabitType.overall:
        return 'Overall Consistency';
    }
  }

  bool isDateActive(String date) => activeDates.contains(date);

  HabitStreak copyWith({
    HabitType? type,
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
    Set<String>? activeDates,
    double? weeklyAdherenceRate,
  }) => HabitStreak(
    type: type ?? this.type,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    activeDates: activeDates ?? this.activeDates,
    weeklyAdherenceRate: weeklyAdherenceRate ?? this.weeklyAdherenceRate,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    if (lastActiveDate != null) 'lastActiveDate': lastActiveDate,
    'activeDates': activeDates.toList(),
    'weeklyAdherenceRate': weeklyAdherenceRate,
  };

  factory HabitStreak.fromJson(Map<String, dynamic> json) => HabitStreak(
    type: HabitType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => HabitType.workouts,
    ),
    currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
    lastActiveDate: json['lastActiveDate'] as String?,
    activeDates:
        (json['activeDates'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const {},
    weeklyAdherenceRate:
        (json['weeklyAdherenceRate'] as num?)?.toDouble() ?? 0.0,
  );
}
