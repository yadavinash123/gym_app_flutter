import 'package:flutter/material.dart';

enum MilestoneCategory {
  strength,
  consistency,
  volume,
  nutrition,
  wellness,
}

@immutable
class MilestoneBadge {
  const MilestoneBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.iconData,
    this.unit = '',
    this.isUnlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final MilestoneCategory category;
  final double targetValue;
  final double currentValue;
  final IconData iconData;
  final String unit;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  double get progressPercentage =>
      targetValue <= 0 ? 0.0 : (currentValue / targetValue).clamp(0.0, 1.0);

  MilestoneBadge copyWith({
    String? id,
    String? title,
    String? description,
    MilestoneCategory? category,
    double? targetValue,
    double? currentValue,
    IconData? iconData,
    String? unit,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) =>
      MilestoneBadge(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        iconData: iconData ?? this.iconData,
        unit: unit ?? this.unit,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'codePoint': iconData.codePoint,
        'fontFamily': iconData.fontFamily,
        'unit': unit,
        'isUnlocked': isUnlocked,
        if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
      };

  factory MilestoneBadge.fromJson(Map<String, dynamic> json) => MilestoneBadge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: MilestoneCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => MilestoneCategory.consistency,
        ),
        targetValue: (json['targetValue'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        iconData: iconForId(json['id'] as String? ?? ''),
        unit: json['unit'] as String? ?? '',
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.tryParse(json['unlockedAt'] as String)
            : null,
      );

  static IconData iconForId(String id) {
    switch (id) {
      case 'first_workout':
        return Icons.fitness_center_rounded;
      case 'workout_5':
        return Icons.repeat_rounded;
      case 'century_club':
        return Icons.tag_faces_rounded;
      case 'streak_7':
        return Icons.local_fire_department_rounded;
      case 'streak_30':
        return Icons.workspace_premium_rounded;
      case 'volume_5k':
        return Icons.bolt_rounded;
      case 'volume_25k':
        return Icons.shield_rounded;
      case 'volume_100k':
        return Icons.military_tech_rounded;
      case 'pr_breaker_3':
        return Icons.trending_up_rounded;
      case 'nutrition_novice':
        return Icons.restaurant_rounded;
      case 'hydration_hero':
        return Icons.water_drop_rounded;
      case 'sleep_champion':
        return Icons.bedtime_rounded;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  static List<MilestoneBadge> defaultCatalog() => [
        const MilestoneBadge(
          id: 'first_workout',
          title: 'First Ignition',
          description: 'Complete your first workout session in FitForge.',
          category: MilestoneCategory.consistency,
          targetValue: 1,
          currentValue: 0,
          unit: 'session',
          iconData: Icons.fitness_center_rounded,
        ),
        const MilestoneBadge(
          id: 'workout_5',
          title: 'The Regular',
          description: 'Log 5 completed workout sessions.',
          category: MilestoneCategory.consistency,
          targetValue: 5,
          currentValue: 0,
          unit: 'sessions',
          iconData: Icons.repeat_rounded,
        ),
        const MilestoneBadge(
          id: 'century_club',
          title: 'Century Club',
          description: 'Complete 100 sets across all exercises.',
          category: MilestoneCategory.volume,
          targetValue: 100,
          currentValue: 0,
          unit: 'sets',
          iconData: Icons.tag_faces_rounded,
        ),
        const MilestoneBadge(
          id: 'streak_7',
          title: 'Iron Will',
          description: 'Achieve a 7-day workout consistency streak.',
          category: MilestoneCategory.consistency,
          targetValue: 7,
          currentValue: 0,
          unit: 'days',
          iconData: Icons.local_fire_department_rounded,
        ),
        const MilestoneBadge(
          id: 'streak_30',
          title: 'Unstoppable Habit',
          description: 'Maintain a 30-day streak of active fitness & health logging.',
          category: MilestoneCategory.consistency,
          targetValue: 30,
          currentValue: 0,
          unit: 'days',
          iconData: Icons.workspace_premium_rounded,
        ),
        const MilestoneBadge(
          id: 'volume_5k',
          title: 'Tonnage Initiate',
          description: 'Lift 5,000 kg in cumulative workout volume.',
          category: MilestoneCategory.volume,
          targetValue: 5000,
          currentValue: 0,
          unit: 'kg',
          iconData: Icons.bolt_rounded,
        ),
        const MilestoneBadge(
          id: 'volume_25k',
          title: 'Volume Titan',
          description: 'Surpass 25,000 kg in total training volume.',
          category: MilestoneCategory.volume,
          targetValue: 25000,
          currentValue: 0,
          unit: 'kg',
          iconData: Icons.shield_rounded,
        ),
        const MilestoneBadge(
          id: 'volume_100k',
          title: 'Megaton Legend',
          description: 'Break the 100,000 kg cumulative tonnage barrier.',
          category: MilestoneCategory.volume,
          targetValue: 100000,
          currentValue: 0,
          unit: 'kg',
          iconData: Icons.military_tech_rounded,
        ),
        const MilestoneBadge(
          id: 'pr_breaker_3',
          title: 'PR Breaker',
          description: 'Establish or break 3 personal strength records.',
          category: MilestoneCategory.strength,
          targetValue: 3,
          currentValue: 0,
          unit: 'PRs',
          iconData: Icons.trending_up_rounded,
        ),
        const MilestoneBadge(
          id: 'nutrition_novice',
          title: 'Macro Explorer',
          description: 'Log daily nutrition for 7 days.',
          category: MilestoneCategory.nutrition,
          targetValue: 7,
          currentValue: 0,
          unit: 'days',
          iconData: Icons.restaurant_rounded,
        ),
        const MilestoneBadge(
          id: 'hydration_hero',
          title: 'Hydration Hero',
          description: 'Reach your daily water intake goal on 5 separate days.',
          category: MilestoneCategory.nutrition,
          targetValue: 5,
          currentValue: 0,
          unit: 'days',
          iconData: Icons.water_drop_rounded,
        ),
        const MilestoneBadge(
          id: 'sleep_champion',
          title: 'Rest & Recover',
          description: 'Log 7+ hours of quality sleep on 5 recorded days.',
          category: MilestoneCategory.wellness,
          targetValue: 5,
          currentValue: 0,
          unit: 'days',
          iconData: Icons.bedtime_rounded,
        ),
      ];
}
