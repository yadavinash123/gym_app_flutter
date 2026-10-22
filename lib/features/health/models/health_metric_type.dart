import 'package:flutter/material.dart';

/// Supported types of health metrics that can be read, written, or displayed.
enum HealthMetricType {
  steps,
  distance,
  activeEnergy,
  restingHeartRate,
  sleep,
  workouts;

  String get label {
    switch (this) {
      case HealthMetricType.steps:
        return 'Daily Steps';
      case HealthMetricType.distance:
        return 'Walking Distance';
      case HealthMetricType.activeEnergy:
        return 'Active Energy (Kcal)';
      case HealthMetricType.restingHeartRate:
        return 'Resting Heart Rate';
      case HealthMetricType.sleep:
        return 'Sleep Duration & Stages';
      case HealthMetricType.workouts:
        return 'External Workouts';
    }
  }

  String get unitLabel {
    switch (this) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.activeEnergy:
        return 'kcal';
      case HealthMetricType.restingHeartRate:
        return 'bpm';
      case HealthMetricType.sleep:
        return 'hrs';
      case HealthMetricType.workouts:
        return 'sessions';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthMetricType.steps:
        return Icons.directions_walk_rounded;
      case HealthMetricType.distance:
        return Icons.straighten;
      case HealthMetricType.activeEnergy:
        return Icons.local_fire_department_rounded;
      case HealthMetricType.restingHeartRate:
        return Icons.favorite_rounded;
      case HealthMetricType.sleep:
        return Icons.bedtime_rounded;
      case HealthMetricType.workouts:
        return Icons.fitness_center_rounded;
    }
  }

  Color get color {
    switch (this) {
      case HealthMetricType.steps:
        return const Color(0xFFB6FF3B);
      case HealthMetricType.distance:
        return const Color(0xFF00D4FF);
      case HealthMetricType.activeEnergy:
        return const Color(0xFFFF9500);
      case HealthMetricType.restingHeartRate:
        return const Color(0xFFFF2D55);
      case HealthMetricType.sleep:
        return const Color(0xFFA78BFA);
      case HealthMetricType.workouts:
        return const Color(0xFF34D399);
    }
  }

  String get justification {
    switch (this) {
      case HealthMetricType.steps:
        return 'Used to calculate daily physical activity context against WHO health recommendations (7,500–10,000 steps/day).';
      case HealthMetricType.distance:
        return 'Provides accurate daily ambulatory movement estimates alongside step frequency.';
      case HealthMetricType.activeEnergy:
        return 'Contextualizes daily energy expenditure against Mifflin–St Jeor TDEE targets without double-counting workout sessions.';
      case HealthMetricType.restingHeartRate:
        return 'Monitors baseline cardiovascular readiness, autonomic recovery trends, and Tanaka HR training zones.';
      case HealthMetricType.sleep:
        return 'Assesses nocturnal recovery quality and muscular restoration to advise rest vs heavy training days.';
      case HealthMetricType.workouts:
        return 'Imports walking, cycling, or running recorded outside FitForge to avoid conflicting training volume.';
    }
  }
}
