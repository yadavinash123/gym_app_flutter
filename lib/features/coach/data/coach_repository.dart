import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../health/data/health_repository.dart';
import '../../health/models/daily_health_summary.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/models/meal_log.dart';
import '../../profile/profile.dart';
import '../../profile/profile_repository.dart';
import '../../workouts/data/workout_repository.dart';
import '../../workouts/models/workout_session.dart';
import '../models/ai_credentials.dart';
import '../models/ai_provider.dart';
import '../models/coach_consent.dart';
import '../models/coach_message.dart';
import '../models/coach_persona.dart';
import 'ai_client.dart';
import 'offline_coach_engine.dart';
import 'secure_credentials_store.dart';

class CoachRepository {
  CoachRepository({
    required this.store,
    required this.credentialsStore,
    required this.aiClient,
    this.offlineEngine = const OfflineCoachEngine(),
  });

  final JsonStore store;
  final SecureCredentialsStore credentialsStore;
  final AiClient aiClient;
  final OfflineCoachEngine offlineEngine;

  static const String chatStorageKey = 'coach_chat';
  static const String consentStorageKey = 'coach_consent';

  Future<void> _tail = Future.value();

  // ---------------------------------------------------------------------------
  // Chat History
  // ---------------------------------------------------------------------------

  Future<List<CoachMessage>> loadMessages() async {
    await _tail;
    final data = await store.read(chatStorageKey);
    if (data == null || data['messages'] is! List) {
      return _initialWelcomeMessage();
    }
    final raw = data['messages'] as List;
    final list = raw.map((e) => CoachMessage.fromJson(e as Map<String, dynamic>)).toList();
    return list.isEmpty ? _initialWelcomeMessage() : list;
  }

  Future<void> saveMessages(List<CoachMessage> messages) {
    final payload = {
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    final result = _tail.then((_) => store.write(chatStorageKey, payload));
    _tail = result.catchError((_) {});
    return result;
  }

  Future<void> clearChat() async {
    await saveMessages(_initialWelcomeMessage());
  }

  List<CoachMessage> _initialWelcomeMessage() {
    return [
      CoachMessage(
        id: 'welcome_1',
        role: MessageRole.assistant,
        content: '👋 **Welcome to FitForge AI Coach!**\n\n'
            'I am your private, intelligent fitness companion. I can analyze your workout volume, '
            'review daily macros against ISSN guidelines, assess your recovery from sleep/heart rate biomarkers, '
            'and guide your progressive overload.\n\n'
            '🔒 **Privacy First:** By default, I operate **100% offline on your device** without sending any data. '
            'If you wish to enable online LLMs (Gemini / OpenAI), configure your own API key in **Coach Settings**.\n\n'
            'How can I help you today?',
        timestamp: DateTime.now(),
        offlineGenerated: true,
        suggestedActions: const [
          'Check today\'s macro balance',
          'Recovery & readiness assessment',
          'Today\'s workout recommendation',
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Persona
  // ---------------------------------------------------------------------------

  Future<CoachPersona> loadPersona() async {
    final data = await store.read(chatStorageKey);
    if (data == null || data['persona'] == null) {
      return CoachPersona.scientific;
    }
    return CoachPersona.fromString(data['persona'] as String?);
  }

  Future<void> savePersona(CoachPersona persona) async {
    final data = await store.read(chatStorageKey) ?? {'version': 1, 'messages': []};
    data['persona'] = persona.name;
    final result = _tail.then((_) => store.write(chatStorageKey, data));
    _tail = result.catchError((_) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Consent & Privacy Settings
  // ---------------------------------------------------------------------------

  Future<CoachConsent> loadConsent() async {
    final data = await store.read(consentStorageKey);
    if (data == null) return const CoachConsent();
    return CoachConsent.fromJson(data);
  }

  Future<void> saveConsent(CoachConsent consent) {
    final result = _tail.then((_) => store.write(consentStorageKey, consent.toJson()));
    _tail = result.catchError((_) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Credentials (BYOK)
  // ---------------------------------------------------------------------------

  Future<AiCredentials> loadCredentials() async {
    final creds = await credentialsStore.readCredentials();
    return creds ?? const AiCredentials();
  }

  Future<void> saveCredentials(AiCredentials credentials) {
    return credentialsStore.writeCredentials(credentials);
  }

  Future<void> clearCredentials() {
    return credentialsStore.clearCredentials();
  }

  Future<bool> testConnection(AiCredentials credentials) {
    return aiClient.testConnection(credentials);
  }

  Future<String?> checkConnection(AiCredentials credentials) {
    return aiClient.checkConnection(credentials);
  }

  // ---------------------------------------------------------------------------
  // Privacy-First Context Assembly & Anonymization
  // ---------------------------------------------------------------------------

  String buildPromptContext({
    required CoachConsent consent,
    Profile? profile,
    DailyNutritionLog? todayNutrition,
    DailyHealthSummary? todayHealth,
    List<WorkoutSession> recentWorkouts = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('--- ATHLETE CONTEXT (ANONYMIZED) ---');

    // 1. Profile & Goals (strictly no personal identifiers: name, email omitted)
    if (consent.shareProfile && profile != null) {
      buffer.writeln('BODY METRICS & GOALS:');
      buffer.writeln('- Age: ${profile.age ?? "Not set"} | Gender: ${profile.gender}');
      buffer.writeln('- Height: ${profile.heightCm?.round() ?? "Not set"} cm | Weight: ${profile.weightKg?.toStringAsFixed(1) ?? "Not set"} kg');
      buffer.writeln('- Primary Fitness Goal: ${profile.goal}');
      buffer.writeln('- Experience Level: ${profile.level}');
      buffer.writeln('- Training Environment: ${profile.environment}');
      buffer.writeln('- Scheduled Training Days: ${profile.days} days/week');
      if (profile.calorieTarget != null) {
        buffer.writeln('- Daily Energy Target: ${profile.calorieTarget!.round()} kcal');
      }
      if (profile.proteinTarget != null) {
        buffer.writeln('- Target Protein: ${profile.proteinTarget!.round()} g');
      }
      if (profile.hasLimitations && profile.limitations.isNotEmpty) {
        buffer.writeln('- Recorded Physical Limitations: ${profile.limitations}');
      }
    } else {
      buffer.writeln('BODY METRICS: [Redacted by user privacy choice]');
    }

    // 2. Nutrition
    if (consent.shareNutrition && todayNutrition != null) {
      buffer.writeln('\nTODAY\'S NUTRITION LOG:');
      buffer.writeln('- Calories Consumed: ${todayNutrition.totalCalories.round()} kcal');
      buffer.writeln('- Protein: ${todayNutrition.totalProtein.round()} g');
      buffer.writeln('- Carbohydrates: ${todayNutrition.totalCarbs.round()} g');
      buffer.writeln('- Fats: ${todayNutrition.totalFat.round()} g');
      buffer.writeln('- Water Intake: ${todayNutrition.waterMl} mL');
    } else {
      buffer.writeln('\nNUTRITION LOG: [Redacted by user privacy choice]');
    }

    // 3. Workouts
    if (consent.shareWorkouts && recentWorkouts.isNotEmpty) {
      buffer.writeln('\nRECENT WORKOUT HISTORY:');
      for (final w in recentWorkouts.take(3)) {
        buffer.writeln('- "${w.routineName}" on ${w.startedAt.toIso8601String().substring(0, 10)}: ${w.totalCompletedSets} sets, ${w.totalVolumeKg.round()} kg tonnage');
      }
    } else {
      buffer.writeln('\nWORKOUT HISTORY: [Redacted by user privacy choice]');
    }

    // 4. Health & Recovery
    if (consent.shareHealth && todayHealth != null) {
      buffer.writeln('\nDAILY HEALTH BIOMARKERS:');
      buffer.writeln('- Steps: ${todayHealth.steps}');
      if (todayHealth.restingHeartRateBpm != null) {
        buffer.writeln('- Resting Heart Rate: ${todayHealth.restingHeartRateBpm} bpm');
      }
      if (todayHealth.sleepDurationMinutes != null && todayHealth.sleepDurationMinutes! > 0) {
        buffer.writeln('- Sleep Duration: ${(todayHealth.sleepDurationMinutes! / 60.0).toStringAsFixed(1)} hours (${todayHealth.sleepFormatted})');
      }
    } else {
      buffer.writeln('\nHEALTH BIOMARKERS: [Redacted by user privacy choice]');
    }

    buffer.writeln('------------------------------------');
    return buffer.toString();
  }

  String buildFullSystemPrompt({
    required CoachPersona persona,
    required CoachConsent consent,
    Profile? profile,
    DailyNutritionLog? todayNutrition,
    DailyHealthSummary? todayHealth,
    List<WorkoutSession> recentWorkouts = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln(persona.systemDirective);
    buffer.writeln('\nCRITICAL GUIDELINES:');
    buffer.writeln('1. You are FitForge AI Coach, a supportive fitness educator. You provide evidence-based guidance.');
    buffer.writeln('2. Medical Disclaimer: You are NOT a doctor or registered dietitian. Remind user to seek professional clinical advice for pain, injury, or severe symptoms.');
    buffer.writeln('3. Format responses in clean GitHub markdown with bullet points and bolding for readability on mobile screens.');
    buffer.writeln('4. Keep advice actionable, direct, and under 350 words unless specifically asked for an in-depth essay.');
    buffer.writeln('\n${buildPromptContext(
      consent: consent,
      profile: profile,
      todayNutrition: todayNutrition,
      todayHealth: todayHealth,
      recentWorkouts: recentWorkouts,
    )}');
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Message Dispatch Pipeline
  // ---------------------------------------------------------------------------

  Future<List<CoachMessage>> sendMessage({
    required String text,
    required CoachPersona persona,
    Profile? profile,
    DailyNutritionLog? todayNutrition,
    DailyHealthSummary? todayHealth,
    List<WorkoutSession> recentWorkouts = const [],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return loadMessages();

    final currentMessages = await loadMessages();
    final userMessage = CoachMessage(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    final updatedWithUser = [...currentMessages, userMessage];
    await saveMessages(updatedWithUser);

    final credentials = await loadCredentials();
    final consent = await loadConsent();

    CoachMessage assistantMessage;

    if (!credentials.isConfigured || credentials.provider == AiProvider.offline) {
      // 100% Offline execution
      assistantMessage = offlineEngine.generateResponse(
        userQuery: trimmed,
        persona: persona,
        profile: profile,
        todayNutrition: todayNutrition,
        todayHealth: todayHealth,
        recentWorkouts: recentWorkouts,
      );
    } else {
      // Online BYOK execution with fallback
      try {
        final systemPrompt = buildFullSystemPrompt(
          persona: persona,
          consent: consent,
          profile: profile,
          todayNutrition: todayNutrition,
          todayHealth: todayHealth,
          recentWorkouts: recentWorkouts,
        );

        assistantMessage = await aiClient.sendMessage(
          history: updatedWithUser,
          systemPrompt: systemPrompt,
          credentials: credentials,
        );
      } catch (e) {
        // Fallback gracefully to offline engine with explanation
        final fallback = offlineEngine.generateResponse(
          userQuery: trimmed,
          persona: persona,
          profile: profile,
          todayNutrition: todayNutrition,
          todayHealth: todayHealth,
          recentWorkouts: recentWorkouts,
        );
        assistantMessage = fallback.copyWith(
          content: '⚠️ *Could not reach ${credentials.provider.displayName} (${e.toString()}). Falling back to Offline Rule Engine:*\n\n${fallback.content}',
        );
      }
    }

    final finalMessages = [...updatedWithUser, assistantMessage];
    await saveMessages(finalMessages);
    return finalMessages;
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final secureCredentialsStoreProvider = Provider<SecureCredentialsStore>((ref) {
  return JsonSecureCredentialsStore(ref.watch(storeProvider));
});

final aiClientProvider = Provider<AiClient>((ref) {
  return HttpAiClient();
});

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(
    store: ref.watch(storeProvider),
    credentialsStore: ref.watch(secureCredentialsStoreProvider),
    aiClient: ref.watch(aiClientProvider),
  );
});

final coachMessagesProvider =
    AsyncNotifierProvider<CoachMessagesNotifier, List<CoachMessage>>(
  CoachMessagesNotifier.new,
);

class CoachMessagesNotifier extends AsyncNotifier<List<CoachMessage>> {
  @override
  Future<List<CoachMessage>> build() {
    return ref.watch(coachRepositoryProvider).loadMessages();
  }

  Future<void> send(String text, CoachPersona persona) async {
    final repo = ref.read(coachRepositoryProvider);
    final profile = await ref.read(profileProvider.future);

    // Load today's nutrition and health if available
    DailyNutritionLog? todayLog;
    try {
      final allLogs = await ref.read(nutritionRepositoryProvider).loadAllLogs();
      todayLog = allLogs[todayIsoDate()];
    } catch (_) {}

    DailyHealthSummary? todayHealth;
    try {
      todayHealth = await ref.read(healthRepositoryProvider).getSummaryForDate(todayIsoDate());
    } catch (_) {}

    List<WorkoutSession> sessions = const [];
    try {
      sessions = await ref.read(workoutRepositoryProvider).loadSessions();
    } catch (_) {}

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return repo.sendMessage(
        text: text,
        persona: persona,
        profile: profile,
        todayNutrition: todayLog,
        todayHealth: todayHealth,
        recentWorkouts: sessions,
      );
    });
  }

  Future<void> clear() async {
    final repo = ref.read(coachRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.clearChat();
      return repo.loadMessages();
    });
  }
}

final coachPersonaProvider =
    AsyncNotifierProvider<CoachPersonaNotifier, CoachPersona>(
  CoachPersonaNotifier.new,
);

class CoachPersonaNotifier extends AsyncNotifier<CoachPersona> {
  @override
  Future<CoachPersona> build() {
    return ref.watch(coachRepositoryProvider).loadPersona();
  }

  Future<void> setPersona(CoachPersona persona) async {
    final repo = ref.read(coachRepositoryProvider);
    state = AsyncData(persona);
    await repo.savePersona(persona);
  }
}

final coachConsentProvider =
    AsyncNotifierProvider<CoachConsentNotifier, CoachConsent>(
  CoachConsentNotifier.new,
);

class CoachConsentNotifier extends AsyncNotifier<CoachConsent> {
  @override
  Future<CoachConsent> build() {
    return ref.watch(coachRepositoryProvider).loadConsent();
  }

  Future<void> updateConsent(CoachConsent consent) async {
    final repo = ref.read(coachRepositoryProvider);
    state = AsyncData(consent);
    await repo.saveConsent(consent);
  }
}

final coachCredentialsProvider =
    AsyncNotifierProvider<CoachCredentialsNotifier, AiCredentials>(
  CoachCredentialsNotifier.new,
);

class CoachCredentialsNotifier extends AsyncNotifier<AiCredentials> {
  @override
  Future<AiCredentials> build() {
    return ref.watch(coachRepositoryProvider).loadCredentials();
  }

  Future<void> save(AiCredentials credentials) async {
    final repo = ref.read(coachRepositoryProvider);
    state = AsyncData(credentials);
    await repo.saveCredentials(credentials);
  }

  Future<void> clear() async {
    final repo = ref.read(coachRepositoryProvider);
    const empty = AiCredentials();
    state = const AsyncData(empty);
    await repo.clearCredentials();
  }
}
