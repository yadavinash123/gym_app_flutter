import 'package:flutter/material.dart';

enum CoachPersona {
  scientific,
  supportive,
  hypertrophy,
  wellness;

  String get displayName {
    switch (this) {
      case CoachPersona.scientific:
        return 'Evidence-Based';
      case CoachPersona.supportive:
        return 'Encouraging & Habit';
      case CoachPersona.hypertrophy:
        return 'Strength & Muscle';
      case CoachPersona.wellness:
        return 'Recovery & Health';
    }
  }

  String get shortDescription {
    switch (this) {
      case CoachPersona.scientific:
        return 'Biomechanics, ISSN nutrition, Tanaka formula, objective data';
      case CoachPersona.supportive:
        return 'Positive reinforcement, consistency, sustainable lifestyle habits';
      case CoachPersona.hypertrophy:
        return 'Progressive overload, RPE/RIR tracking, hypertrophy volume';
      case CoachPersona.wellness:
        return 'Sleep hygiene, resting HR, active recovery, injury prevention';
    }
  }

  IconData get icon {
    switch (this) {
      case CoachPersona.scientific:
        return Icons.science_outlined;
      case CoachPersona.supportive:
        return Icons.sentiment_satisfied_alt_outlined;
      case CoachPersona.hypertrophy:
        return Icons.fitness_center;
      case CoachPersona.wellness:
        return Icons.spa_outlined;
    }
  }

  String get systemDirective {
    switch (this) {
      case CoachPersona.scientific:
        return 'You are an elite, evidence-based fitness and sports science coach. '
            'Prioritize peer-reviewed exercise physiology (e.g. Schoenfeld on hypertrophy, ISSN on protein intake, Tanaka on HRmax). '
            'Be concise, analytical, clear, and direct. Quantify recommendations with metrics, sets, reps, and macro targets whenever possible.';
      case CoachPersona.supportive:
        return 'You are an empathetic, encouraging fitness mentor. '
            'Focus on habit sustainability, non-judgmental accountability, overcoming gym anxiety, and celebrating daily wins. '
            'Keep advice approachable, uplifting, and realistic for busy lives.';
      case CoachPersona.hypertrophy:
        return 'You are a dedicated strength and bodybuilding coach. '
            'Focus strictly on progressive overload, mechanical tension, set volume per muscle group (10-20 weekly sets), '
            'reps in reserve (RIR 1-3), rest periods (2-3 min for compounds), and high-protein nutrition for muscle protein synthesis.';
      case CoachPersona.wellness:
        return 'You are a holistic recovery and wellness advisor. '
            'Analyze sleep architecture, resting heart rate trends, active recovery sessions, stress modulation, and mobility. '
            'Remind the athlete that progress happens during recovery, not just training.';
    }
  }

  static CoachPersona fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'supportive':
        return CoachPersona.supportive;
      case 'hypertrophy':
        return CoachPersona.hypertrophy;
      case 'wellness':
        return CoachPersona.wellness;
      case 'scientific':
      default:
        return CoachPersona.scientific;
    }
  }
}
