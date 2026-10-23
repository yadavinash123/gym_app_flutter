import '../../health/models/daily_health_summary.dart';
import '../../health/models/heart_rate_zone.dart';
import '../../nutrition/models/meal_log.dart';
import '../../profile/profile.dart';
import '../../workouts/models/workout_session.dart';
import '../models/coach_conversation.dart';
import '../models/coach_message.dart';
import '../models/coach_persona.dart';

class OfflineCoachEngine {
  const OfflineCoachEngine();

  CoachMessage generateResponse({
    required String userQuery,
    required CoachPersona persona,
    Profile? profile,
    DailyNutritionLog? todayNutrition,
    DailyHealthSummary? todayHealth,
    List<WorkoutSession> recentWorkouts = const [],
  }) {
    final lower = userQuery.toLowerCase().trim();

    String content;
    List<String> suggestions;
    WorkoutPlanCardData? workoutPlan;

    if (_matches(lower, ['upper lower', '4-day', 'split', 'muscle gain', 'workout plan', 'build my workout', 'program'])) {
      content = 'Absolutely! Here\'s a 4-day upper/lower workout plan designed for muscle gain. It focuses on compound movements, progressive overload, and balanced volume.';
      workoutPlan = const WorkoutPlanCardData(
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
      suggestions = const ['Show Day 2', 'Add rest times', 'Make it home gym'];
    } else if (_matches(lower, ['heart', 'zone', 'tanaka', 'cardio', 'bpm', 'hr', 'step', 'walk'])) {
      content = _analyzeCardioAndHealth(persona, profile, todayHealth);
      suggestions = const ['Check today\'s macro balance', 'Recovery & readiness assessment', 'Today\'s workout recommendation'];
    } else if (_matches(lower, ['overload', 'progress', 'progression', 'weight', 'pr', 'heavy', 'rep', 'rir', 'rpe'])) {
      content = _explainProgressiveOverload(persona, profile);
      suggestions = const ['Check today\'s macro balance', 'Today\'s workout recommendation', 'Recovery & readiness assessment'];
    } else if (_matches(lower, ['recover', 'sleep', 'rest', 'sore', 'fatigue', 'ready', 'readiness'])) {
      content = _analyzeRecovery(persona, profile, todayHealth);
      suggestions = const ['Check today\'s macro balance', 'Today\'s workout recommendation', 'How to overload safely?'];
    } else if (_matches(lower, ['nutrition', 'protein', 'calorie', 'macro', 'water', 'hydrat', 'diet', 'eat', 'food'])) {
      content = _analyzeNutrition(persona, profile, todayNutrition);
      suggestions = const ['Recovery & readiness assessment', 'Today\'s workout recommendation', 'Explain Tanaka HR zones'];
    } else if (_matches(lower, ['workout', 'routine', 'schedule', 'exercise plan', 'training plan', 'train today', 'lift today'])) {
      content = _analyzeWorkout(persona, profile, recentWorkouts);
      suggestions = const ['How to overload safely?', 'Check today\'s macro balance', 'Recovery & readiness assessment'];
    } else {
      content = _generateComprehensiveSummary(persona, profile, todayNutrition, todayHealth, recentWorkouts);
      suggestions = const [
        'Check today\'s macro balance',
        'Recovery & readiness assessment',
        'Today\'s workout recommendation',
      ];
    }

    return CoachMessage(
      id: 'offline_${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      offlineGenerated: true,
      workoutPlan: workoutPlan,
      suggestedActions: suggestions,
    );
  }

  static bool _matches(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (kw.length <= 3) {
        final reg = RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false);
        if (reg.hasMatch(text)) return true;
      } else {
        if (text.contains(kw)) return true;
      }
    }
    return false;
  }

  String _analyzeRecovery(
    CoachPersona persona,
    Profile? profile,
    DailyHealthSummary? health,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('### 🛌 Recovery & Readiness Assessment\n');

    final sleepMinutes = health?.sleepDurationMinutes;
    final sleepHours = sleepMinutes != null ? sleepMinutes / 60.0 : null;
    final restingHr = health?.restingHeartRateBpm;

    if (sleepHours != null && sleepHours > 0) {
      buffer.writeln('**Sleep Tracked:** ${sleepHours.toStringAsFixed(1)} hours (${health?.sleepFormatted})');
      if (sleepHours < 7.0) {
        buffer.writeln(
          '⚠️ **Sub-optimal Sleep Volume:** Under 7 hours limits REM and slow-wave sleep. '
          'Growth hormone secretion and glycogen resynthesis are compromised. '
          'Consider capping working sets at RPE 7-8 today.',
        );
      } else if (sleepHours >= 8.0) {
        buffer.writeln(
          '✅ **Optimal Sleep Duration:** 8+ hours provides complete hormonal recovery and neuromuscular replenishment. '
          'You are well-primed for high-intensity training.',
        );
      } else {
        buffer.writeln('ℹ️ **Adequate Rest:** 7–8 hours maintains baseline training readiness.');
      }
    } else {
      buffer.writeln('ℹ️ *No sleep duration recorded for today.* Baseline recommendation: 7.5–9 hours of dark, cool rest.');
    }

    if (restingHr != null) {
      final classification = HeartRateZone.restingHrClassification(restingHr);
      buffer.writeln('\n**Resting Heart Rate:** $restingHr bpm ($classification)');
      if (restingHr >= 80) {
        buffer.writeln(
          '⚠️ *Elevated Resting Pulse:* An elevation above 80 bpm suggests incomplete parasympathetic recovery, acute stress, or dehydration.',
        );
      } else {
        buffer.writeln('✅ Resting cardiovascular biomarkers reflect stable autonomic balance.');
      }
    }

    buffer.writeln('\n#### Recommended Action:');
    switch (persona) {
      case CoachPersona.scientific:
        buffer.writeln(
          '- Target 300–400mg magnesium glycinate pre-bed to improve sleep spindle density.\n'
          '- Maintain 10-15 min active cool-down or foam rolling after heavy sessions to expedite venous return.',
        );
        break;
      case CoachPersona.supportive:
        buffer.writeln(
          '- Listen to your body! If you feel sluggish, an extra 10-minute walk or a relaxed mobility session counts as a huge win.\n'
          '- Stay hydrated and give yourself credit for consistent recovery habits.',
        );
        break;
      case CoachPersona.hypertrophy:
        buffer.writeln(
          '- Muscle protein synthesis occurs during deep sleep. Without adequate sleep, cortisol degrades anabolism.\n'
          '- If sleep was short (<6.5h), drop back-off sets by 20% and focus strictly on preserving strength on your primary compound lift.',
        );
        break;
      case CoachPersona.wellness:
        buffer.writeln(
          '- Unwind with 10 minutes of nasal diaphragmatic breathing before sleep.\n'
          '- Discontinue blue-light screens 60 minutes prior to bedtime to preserve natural melatonin secretion.',
        );
        break;
    }

    return buffer.toString();
  }

  String _analyzeNutrition(
    CoachPersona persona,
    Profile? profile,
    DailyNutritionLog? nutrition,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('### 🥗 Nutritional Balance & Fueling Analysis\n');

    final weightKg = profile?.weightKg ?? 70.0;
    final targetKcal = (profile?.calorieTarget ?? 2200).round();
    final targetProtein = (profile?.proteinTarget ?? (weightKg * 1.8)).round();

    final consumedKcal = nutrition?.totalCalories.round() ?? 0;
    final consumedProtein = nutrition?.totalProtein.round() ?? 0;
    final waterMl = nutrition?.waterMl ?? 0;

    buffer.writeln('**Current Fuel Status Today:**');
    buffer.writeln('- Energy: **$consumedKcal / $targetKcal kcal** (${(consumedKcal / targetKcal * 100).toStringAsFixed(0)}%)');
    buffer.writeln('- Protein: **$consumedProtein / $targetProtein g** (${(consumedProtein / targetProtein * 100).toStringAsFixed(0)}%)');
    buffer.writeln('- Hydration: **${(waterMl / 1000).toStringAsFixed(1)} L** (Target: 2.5–3.5 L)');

    final proteinPerKg = consumedProtein / (weightKg > 0 ? weightKg : 70.0);
    buffer.writeln('\n**ISSN Protein Evaluation:** ${proteinPerKg.toStringAsFixed(2)} g/kg bodyweight');

    if (proteinPerKg < 1.4) {
      buffer.writeln(
        '⚠️ **Protein Deficit:** Under 1.4 g/kg is below the ISSN athletic recommendation (1.6–2.2 g/kg). '
        'Increase intake with lean poultry, fish, eggs, tofu, or whey protein to sustain muscle protein synthesis.',
      );
    } else if (proteinPerKg >= 1.6 && proteinPerKg <= 2.4) {
      buffer.writeln(
        '✅ **Optimal Protein Range:** You are in the optimal anabolic zone (1.6–2.2 g/kg) for muscular repair and lean tissue retention.',
      );
    } else {
      buffer.writeln('ℹ️ Protein intake is very high. Ensure ample water intake to support renal nitrogen clearance.');
    }

    buffer.writeln('\n#### Coach Advice:');
    switch (persona) {
      case CoachPersona.scientific:
        buffer.writeln(
          '- Distribute protein across 3-4 discrete meals of ≥0.40 g/kg to maximize repeated leucine-triggered MPS spikes.\n'
          '- Prioritize complex carbohydrate replenishment (3-5 g/kg) post-workout for glycogen replenishment.',
        );
        break;
      case CoachPersona.supportive:
        buffer.writeln(
          '- Fantastic effort tracking your fuel! Don\'t stress over perfect numbers—consistency over 7 days matters far more than an individual meal.\n'
          '- Keep a water bottle within arm\'s reach to easily hit your hydration goal.',
        );
        break;
      case CoachPersona.hypertrophy:
        buffer.writeln(
          '- Remember: you cannot out-train an energy deficit if your goal is maximal muscle hypertrophy.\n'
          '- Aim for a slight caloric surplus (+200-300 kcal) with at least 2.0g protein/kg to support high-volume lifting.',
        );
        break;
      case CoachPersona.wellness:
        buffer.writeln(
          '- Emphasize whole, unrefined foods with high micronutrient and fiber density (25-35g fiber/day).\n'
          '- Drink 500 mL of water upon waking with a pinch of mineral salt to restore cellular hydration.',
        );
        break;
    }

    return buffer.toString();
  }

  String _analyzeWorkout(
    CoachPersona persona,
    Profile? profile,
    List<WorkoutSession> recentWorkouts,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('### 🏋️ Workout & Training Programming\n');

    final weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final currentDayName = dayNames[weekday - 1];

    final schedule = profile?.schedule ?? const [];
    final dayPlan = schedule.isNotEmpty && weekday <= schedule.length ? schedule[weekday - 1] : null;

    buffer.writeln('**Today is $currentDayName.**');
    if (dayPlan != null) {
      buffer.writeln('Scheduled Focus: **$dayPlan**');
    }

    if (recentWorkouts.isNotEmpty) {
      final last = recentWorkouts.first;
      buffer.writeln('\n**Last Completed Session:**');
      buffer.writeln('- Name: ${last.routineName}');
      buffer.writeln('- Completed Sets: ${last.totalCompletedSets}');
      buffer.writeln('- Total Tonnage: ${last.totalVolumeKg.toStringAsFixed(0)} kg');
    } else {
      buffer.writeln('\n*No logged workout sessions yet. Tap Workouts to start your initial routine!*');
    }

    buffer.writeln('\n#### Programming Guidelines:');
    switch (persona) {
      case CoachPersona.scientific:
        buffer.writeln(
          '- 10–20 weekly hard sets per muscle group yields optimal hypertrophy (Schoenfeld et al.).\n'
          '- Keep rest intervals at 2–3 minutes for compound movements (squat/bench/deadlift) and 60–90 seconds for isolation.',
        );
        break;
      case CoachPersona.supportive:
        buffer.writeln(
          '- Showing up is 90% of the battle. Even a 20-minute focused workout builds momentum!\n'
          '- Celebrate every clean rep and focus on moving with confidence.',
        );
        break;
      case CoachPersona.hypertrophy:
        buffer.writeln(
          '- Train within 1–3 Reps in Reserve (RIR). Sets taken to RIR 5+ do not deliver sufficient mechanical tension.\n'
          '- Apply the double-progression rule: when you hit the top rep target on all sets, increase load by 2.5% next week.',
        );
        break;
      case CoachPersona.wellness:
        buffer.writeln(
          '- Always dedicate 5-8 minutes to dynamic joint mobility (hip openers, thoracic rotations) before loading heavy.\n'
          '- Never sacrifice joint kinematics or posture for the sake of moving more weight on the bar.',
        );
        break;
    }

    return buffer.toString();
  }

  String _explainProgressiveOverload(CoachPersona persona, Profile? profile) {
    final buffer = StringBuffer();
    buffer.writeln('### 📈 Evidence-Based Progressive Overload\n');
    buffer.writeln('Progressive overload is the fundamental physiological principle required to stimulate myofibrillar hypertrophy and neural adaptation.\n');

    buffer.writeln('#### 1. The Double-Progression Method (Gold Standard):');
    buffer.writeln('- Pick a target rep range (e.g., 3 sets of 8–12 reps).');
    buffer.writeln('- Keep the load constant until you can perform 12 clean reps on all 3 sets.');
    buffer.writeln('- Once achieved, increase resistance by **2.5%–5%** (micro-plates) and repeat from 8 reps.');

    buffer.writeln('\n#### 2. Alternative Overload Levers:');
    buffer.writeln('- **Set Volume:** Increase from 3 to 4 working sets over a 4-week meso-cycle.');
    buffer.writeln('- **Execution Quality:** Increase eccentric tempo (3-second lowering) for greater time under tension.');
    buffer.writeln('- **Rest Efficiency:** Reduce rest from 120s to 90s while maintaining rep count.');

    buffer.writeln('\n#### 3. RIR Management:');
    buffer.writeln('- Keep compound lifts at **2 RIR** (2 reps left in the tank) to limit systemic fatigue.');
    buffer.writeln('- Isolation lifts (bicep curls, lateral raises) can be taken to **0–1 RIR** safely.');

    return buffer.toString();
  }

  String _analyzeCardioAndHealth(
    CoachPersona persona,
    Profile? profile,
    DailyHealthSummary? health,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('### 🫀 Cardiovascular Health & Tanaka Training Zones\n');

    final age = profile?.age ?? 28;
    final hrMax = HeartRateZone.calculateMaxHr(age);
    final zones = HeartRateZone.calculateZones(age);

    buffer.writeln('**Tanaka Formula Age-Predicted HRmax:** $hrMax bpm *(208 - 0.7 × $age)*\n');
    for (final zone in zones) {
      buffer.writeln('• **${zone.name} (Z${zone.zoneNumber}):** ${(zone.minPercent * 100).round()}%–${(zone.maxPercent * 100).round()}% intensity (${zone.minBpm}–${zone.maxBpm} bpm)');
    }

    final steps = health?.steps ?? 0;
    buffer.writeln('\n**Today\'s Step Volume:** $steps steps');
    if (steps < 5000) {
      buffer.writeln('⚠️ Sedentary range (<5,000 steps). A 15-minute post-meal walk will help clear glucose and elevate daily NEAT.');
    } else if (steps >= 8000) {
      buffer.writeln('✅ Excellent daily activity (8,000+ steps)! Supports optimal cardiovascular longevity and recovery.');
    }

    return buffer.toString();
  }

  String _generateComprehensiveSummary(
    CoachPersona persona,
    Profile? profile,
    DailyNutritionLog? nutrition,
    DailyHealthSummary? health,
    List<WorkoutSession> recentWorkouts,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('### ⚡ FitForge AI Coach Daily Briefing\n');

    buffer.writeln('Welcome to your personalized coaching station! Here is your synthesized status:\n');

    // 1. Goal
    final goal = profile?.goal ?? 'General Fitness';
    final targetKcal = (profile?.calorieTarget ?? 2200).round();
    buffer.writeln('- **Primary Fitness Goal:** $goal');
    buffer.writeln('- **Energy Target:** $targetKcal kcal / day');

    // 2. Nutrition
    final consumedKcal = nutrition?.totalCalories.round() ?? 0;
    final consumedProtein = nutrition?.totalProtein.round() ?? 0;
    buffer.writeln('- **Today\'s Fuel:** $consumedKcal kcal | $consumedProtein g protein');

    // 3. Health & Readiness
    final steps = health?.steps ?? 0;
    final sleepHours = health?.sleepDurationMinutes != null && health!.sleepDurationMinutes! > 0
        ? (health.sleepDurationMinutes! / 60.0).toStringAsFixed(1)
        : 'Not logged';
    buffer.writeln('- **Activity & Rest:** $steps steps | $sleepHours hrs sleep');

    // 4. Workouts
    buffer.writeln('- **Recent Training:** ${recentWorkouts.length} logged sessions in history');

    buffer.writeln('\n#### How I can assist you today:');
    buffer.writeln('1. **Nutrition Check:** Ask *"How is my protein intake?"* for an ISSN macro breakdown.');
    buffer.writeln('2. **Recovery Evaluation:** Ask *"Assess my readiness"* based on your sleep and resting heart rate.');
    buffer.writeln('3. **Overload Coaching:** Ask *"How do I progress my lifts safely?"* for double-progression rules.');
    buffer.writeln('4. **Custom AI:** Configure your BYOK API Key in **Coach Settings** to unlock online LLM reasoning!');

    return buffer.toString();
  }
}
