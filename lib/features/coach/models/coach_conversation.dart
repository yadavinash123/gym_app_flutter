import 'package:flutter/material.dart';
import 'coach_message.dart';

class WorkoutPlanExercise {
  const WorkoutPlanExercise({
    required this.name,
    required this.setsReps,
    required this.targetMuscle,
    this.icon = Icons.fitness_center,
  });

  final String name;
  final String setsReps;
  final String targetMuscle;
  final IconData icon;

  Map<String, dynamic> toJson() => {
        'name': name,
        'setsReps': setsReps,
        'targetMuscle': targetMuscle,
      };

  factory WorkoutPlanExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutPlanExercise(
        name: (json['name'] as String?) ?? 'Exercise',
        setsReps: (json['setsReps'] as String?) ?? '3 sets x 10 reps',
        targetMuscle: (json['targetMuscle'] as String?) ?? 'Chest',
      );
}

class WorkoutPlanCardData {
  const WorkoutPlanCardData({
    required this.title,
    required this.duration,
    required this.targetMuscles,
    required this.exercises,
  });

  final String title;
  final String duration;
  final String targetMuscles;
  final List<WorkoutPlanExercise> exercises;

  Map<String, dynamic> toJson() => {
        'title': title,
        'duration': duration,
        'targetMuscles': targetMuscles,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutPlanCardData.fromJson(Map<String, dynamic> json) =>
      WorkoutPlanCardData(
        title: (json['title'] as String?) ?? 'Workout Routine',
        duration: (json['duration'] as String?) ?? '~60 min',
        targetMuscles: (json['targetMuscles'] as String?) ?? 'Full Body',
        exercises: (json['exercises'] as List?)
                ?.map((e) =>
                    WorkoutPlanExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

enum ConversationCategory {
  workout,
  recovery,
  nutrition,
  advice,
  cardio,
  sleep,
  supplements;

  IconData get icon {
    switch (this) {
      case ConversationCategory.workout:
        return Icons.fitness_center;
      case ConversationCategory.recovery:
        return Icons.eco_outlined;
      case ConversationCategory.nutrition:
        return Icons.restaurant_outlined;
      case ConversationCategory.advice:
        return Icons.chat_bubble_outline;
      case ConversationCategory.cardio:
        return Icons.directions_run;
      case ConversationCategory.sleep:
        return Icons.nightlight_round;
      case ConversationCategory.supplements:
        return Icons.medication_liquid_outlined;
    }
  }

  Color get iconColor {
    switch (this) {
      case ConversationCategory.workout:
        return const Color(0xFFB6FF3B); // Neon green
      case ConversationCategory.recovery:
        return const Color(0xFF4ADE80); // Leaf green
      case ConversationCategory.nutrition:
        return const Color(0xFFF87171); // Apple coral red
      case ConversationCategory.advice:
        return const Color(0xFFA78BFA); // Soft purple
      case ConversationCategory.cardio:
        return const Color(0xFF38BDF8); // Cyan
      case ConversationCategory.sleep:
        return const Color(0xFF818CF8); // Indigo / moon blue
      case ConversationCategory.supplements:
        return const Color(0xFFFBBF24); // Amber
    }
  }

  Color get backgroundColor {
    return iconColor.withValues(alpha: 0.15);
  }

  static ConversationCategory fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'recovery':
        return ConversationCategory.recovery;
      case 'nutrition':
        return ConversationCategory.nutrition;
      case 'advice':
        return ConversationCategory.advice;
      case 'cardio':
        return ConversationCategory.cardio;
      case 'sleep':
        return ConversationCategory.sleep;
      case 'supplements':
        return ConversationCategory.supplements;
      case 'workout':
      default:
        return ConversationCategory.workout;
    }
  }
}

class CoachConversation {
  const CoachConversation({
    required this.id,
    required this.title,
    required this.lastMessageSnippet,
    required this.updatedAt,
    required this.createdAt,
    this.category = ConversationCategory.workout,
    this.messages = const [],
  });

  final String id;
  final String title;
  final String lastMessageSnippet;
  final DateTime updatedAt;
  final DateTime createdAt;
  final ConversationCategory category;
  final List<CoachMessage> messages;

  bool get isToday {
    final now = DateTime.now();
    return updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return updatedAt.year == yesterday.year &&
        updatedAt.month == yesterday.month &&
        updatedAt.day == yesterday.day;
  }

  bool get isPrevious7Days {
    final now = DateTime.now();
    final diff = now.difference(updatedAt).inDays;
    return diff >= 2 && diff <= 7;
  }

  bool get isOlder {
    final now = DateTime.now();
    return now.difference(updatedAt).inDays > 7;
  }

  String get timeFormatted {
    if (isToday) {
      final hour = updatedAt.hour;
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$h12:$minute $period';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[updatedAt.month - 1]} ${updatedAt.day}';
    }
  }

  CoachConversation copyWith({
    String? id,
    String? title,
    String? lastMessageSnippet,
    DateTime? updatedAt,
    DateTime? createdAt,
    ConversationCategory? category,
    List<CoachMessage>? messages,
  }) {
    return CoachConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessageSnippet: lastMessageSnippet ?? this.lastMessageSnippet,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lastMessageSnippet': lastMessageSnippet,
        'updatedAt': updatedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'category': category.name,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    return CoachConversation(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'New Conversation',
      lastMessageSnippet: (json['lastMessageSnippet'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      category: ConversationCategory.fromString(json['category'] as String?),
      messages: (json['messages'] as List?)
              ?.map((e) => CoachMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Initial sample conversations matching Screen 3 in design!
  static List<CoachConversation> seedConversations() {
    final now = DateTime.now();

    final sampleWorkoutPlan = const WorkoutPlanCardData(
      title: 'Day 1 - Upper Body (Push)',
      duration: '~60 min',
      targetMuscles: 'Chest • Shoulders • Triceps',
      exercises: [
        WorkoutPlanExercise(
          name: 'Bench Press',
          setsReps: '4 sets × 8-10 reps',
          targetMuscle: 'Chest',
        ),
        WorkoutPlanExercise(
          name: 'Incline Dumbbell Press',
          setsReps: '3 sets × 8-12 reps',
          targetMuscle: 'Upper Chest',
        ),
        WorkoutPlanExercise(
          name: 'Shoulder Press',
          setsReps: '3 sets × 8-12 reps',
          targetMuscle: 'Shoulders',
        ),
        WorkoutPlanExercise(
          name: 'Triceps Pushdown',
          setsReps: '3 sets × 10-15 reps',
          targetMuscle: 'Triceps',
        ),
      ],
    );

    return [
      CoachConversation(
        id: 'conv_muscle_plan',
        title: 'My 5-Day Muscle Building Plan',
        lastMessageSnippet: 'Create a complete 5-day workout plan...',
        updatedAt: DateTime(now.year, now.month, now.day, 9, 41),
        createdAt: DateTime(now.year, now.month, now.day, 9, 40),
        category: ConversationCategory.workout,
        messages: [
          CoachMessage(
            id: 'm1',
            role: MessageRole.user,
            content:
                'Can you create a 4-day upper lower workout plan for muscle gain?',
            timestamp: DateTime(now.year, now.month, now.day, 9, 41),
          ),
          CoachMessage(
            id: 'm2',
            role: MessageRole.assistant,
            content:
                'Absolutely! Here\'s a 4-day upper/lower workout plan designed for muscle gain. It focuses on compound movements, progressive overload, and balanced volume.',
            timestamp: DateTime(now.year, now.month, now.day, 9, 41),
            workoutPlan: sampleWorkoutPlan,
            suggestedActions: const [
              'Show Day 2',
              'Add rest times',
              'Make it home gym',
            ],
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_recovery',
        title: 'Post-Workout Recovery',
        lastMessageSnippet: 'Best recovery strategies after intense...',
        updatedAt: DateTime(now.year, now.month, now.day, 7, 20),
        createdAt: DateTime(now.year, now.month, now.day, 7, 15),
        category: ConversationCategory.recovery,
        messages: [
          CoachMessage(
            id: 'rec_1',
            role: MessageRole.user,
            content: 'What are the best recovery strategies after intense leg day?',
            timestamp: DateTime(now.year, now.month, now.day, 7, 15),
          ),
          CoachMessage(
            id: 'rec_2',
            role: MessageRole.assistant,
            content:
                'For optimal lower-body recovery: prioritize 8+ hours of sleep for growth hormone release, consume 25-35g protein within 2 hours, and perform 10 minutes of low-intensity walking to clear metabolic waste.',
            timestamp: DateTime(now.year, now.month, now.day, 7, 20),
            suggestedActions: const [
              'Hydration tips',
              'Foam rolling routine',
              'Next day mobility',
            ],
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_protein',
        title: 'Daily Protein Requirements',
        lastMessageSnippet: 'How much protein do I need for muscle...',
        updatedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        category: ConversationCategory.nutrition,
        messages: [
          CoachMessage(
            id: 'nut_1',
            role: MessageRole.user,
            content: 'How much protein do I need for muscle building?',
            timestamp: now.subtract(const Duration(days: 1, hours: 1)),
          ),
          CoachMessage(
            id: 'nut_2',
            role: MessageRole.assistant,
            content:
                'Based on ISSN guidelines, aim for 1.6 to 2.2 grams of protein per kilogram of bodyweight per day, distributed across 3 to 4 meals.',
            timestamp: now.subtract(const Duration(days: 1)),
            suggestedActions: const [
              'High protein snacks',
              'Vegetarian protein sources',
            ],
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_chest',
        title: 'Best Chest Exercises',
        lastMessageSnippet: 'What are the most effective chest...',
        updatedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
        category: ConversationCategory.advice,
        messages: [
          CoachMessage(
            id: 'ch_1',
            role: MessageRole.user,
            content: 'What are the most effective chest exercises for hypertrophy?',
            timestamp: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_fatloss',
        title: 'Beginner Fat Loss Program',
        lastMessageSnippet: 'Create a beginner-friendly fat loss plan...',
        updatedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5, hours: 1)),
        category: ConversationCategory.cardio,
        messages: [
          CoachMessage(
            id: 'fl_1',
            role: MessageRole.user,
            content: 'Create a beginner-friendly fat loss plan with 3 gym days.',
            timestamp: now.subtract(const Duration(days: 5)),
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_sleep',
        title: 'Better Sleep for Recovery',
        lastMessageSnippet: 'Tips for improving sleep quality...',
        updatedAt: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10, hours: 1)),
        category: ConversationCategory.sleep,
        messages: [
          CoachMessage(
            id: 'sl_1',
            role: MessageRole.user,
            content: 'Tips for improving sleep quality and deep sleep percentage.',
            timestamp: now.subtract(const Duration(days: 10)),
          ),
        ],
      ),
      CoachConversation(
        id: 'conv_supplements',
        title: 'Supplements Guide',
        lastMessageSnippet: 'Tell me about essential supplements...',
        updatedAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 14, hours: 1)),
        category: ConversationCategory.supplements,
        messages: [
          CoachMessage(
            id: 'sup_1',
            role: MessageRole.user,
            content: 'Tell me about essential supplements with proven evidence.',
            timestamp: now.subtract(const Duration(days: 14)),
          ),
        ],
      ),
    ];
  }
}
