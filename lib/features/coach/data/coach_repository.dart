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
import '../models/coach_conversation.dart';
import '../models/coach_message.dart';
import '../models/coach_persona.dart';
import '../models/coach_preferences.dart';
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
  static const String conversationsStorageKey = 'coach_conversations';
  static const String preferencesStorageKey = 'coach_preferences';

  Future<void> _tail = Future.value();

  // ---------------------------------------------------------------------------
  // Multi-Session Conversations
  // ---------------------------------------------------------------------------

  Future<List<CoachConversation>> loadConversations() async {
    await _tail;
    final data = await store.read(conversationsStorageKey);
    if (data == null || data['conversations'] is! List) {
      final seed = CoachConversation.seedConversations();
      await saveConversations(seed);
      return seed;
    }
    final raw = data['conversations'] as List;
    final list = raw
        .map((e) => CoachConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isEmpty) {
      final seed = CoachConversation.seedConversations();
      await saveConversations(seed);
      return seed;
    }
    // Filter redundant empty conversations
    final cleaned = <CoachConversation>[];
    bool hasEmpty = false;
    for (final c in list) {
      if (c.messages.isEmpty && c.lastMessageSnippet.isEmpty) {
        if (!hasEmpty) {
          cleaned.add(c);
          hasEmpty = true;
        }
      } else {
        cleaned.add(c);
      }
    }
    return cleaned.isEmpty ? list : cleaned;
  }

  Future<void> saveConversations(List<CoachConversation> conversations) {
    final payload = {
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'conversations': conversations.map((c) => c.toJson()).toList(),
    };
    final result =
        _tail.then((_) => store.write(conversationsStorageKey, payload));
    _tail = result.catchError((_) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  Future<CoachPreferences> loadPreferences() async {
    await _tail;
    final data = await store.read(preferencesStorageKey);
    if (data == null) return const CoachPreferences();
    return CoachPreferences.fromJson(data);
  }

  Future<void> savePreferences(CoachPreferences prefs) {
    final result =
        _tail.then((_) => store.write(preferencesStorageKey, prefs.toJson()));
    _tail = result.catchError((_) {});
    return result;
  }

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
        content: '👋 Welcome to FitForge AI Coach!\n\n'
            'I am your intelligent fitness companion. I can analyze your workout volume, '
            'review daily macros against ISSN guidelines, assess your recovery from sleep/heart rate biomarkers, '
            'and guide your progressive overload.\n\n'
            '🔒 Privacy First: Your personal identifiable information is never shared. '
            'Connect your AI API key in Coach Settings to start personalized coaching.\n\n'
            'How can I help you today?',
        timestamp: DateTime.now(),
        offlineGenerated: false,
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
    buffer.writeln('3. Format responses in clean GitHub markdown with bullet points (•) and bold headers for readability on mobile screens. DO NOT use ASCII or pipe tables (| col | col |); always present structured comparisons, nutrition targets, and workout plans as clean bullet points, exactly like ChatGPT.');
    buffer.writeln('4. Keep advice actionable, direct, and under 350 words unless specifically asked for an in-depth essay.');
    buffer.writeln('5. NEVER include raw unformatted markdown asterisks or stray "**" characters. For emphasis, properly wrap text like "**keyword**". Never output lonely or dangling "**".');
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

final activeConversationIdProvider =
    NotifierProvider<ActiveConversationIdNotifier, String>(
  ActiveConversationIdNotifier.new,
);

class ActiveConversationIdNotifier extends Notifier<String> {
  @override
  String build() => 'conv_muscle_plan';

  void setActive(String id) => state = id;
}

final coachConversationsProvider =
    AsyncNotifierProvider<CoachConversationsNotifier, List<CoachConversation>>(
  CoachConversationsNotifier.new,
);

class CoachConversationsNotifier extends AsyncNotifier<List<CoachConversation>> {
  @override
  Future<List<CoachConversation>> build() {
    return ref.watch(coachRepositoryProvider).loadConversations();
  }

  Future<String> createConversation({
    String? title,
    ConversationCategory category = ConversationCategory.workout,
    String? initialPrompt,
  }) async {
    final repo = ref.read(coachRepositoryProvider);
    final current = state.value ?? [];

    // If creating an empty chat (+ New Chat), reuse existing empty chat if available
    if (initialPrompt == null &&
        current.isNotEmpty &&
        current.first.messages.isEmpty &&
        current.first.lastMessageSnippet.isEmpty) {
      final existingId = current.first.id;
      ref.read(activeConversationIdProvider.notifier).setActive(existingId);
      ref.invalidate(coachMessagesProvider);
      return existingId;
    }

    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    final newConv = CoachConversation(
      id: id,
      title: title ??
          (initialPrompt != null && initialPrompt.length > 25
              ? '${initialPrompt.substring(0, 25)}...'
              : 'New Conversation'),
      lastMessageSnippet: initialPrompt ?? '',
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
      category: category,
      messages: const [],
    );
    final updated = [newConv, ...current];
    state = AsyncData(updated);
    await repo.saveConversations(updated);
    ref.read(activeConversationIdProvider.notifier).setActive(id);
    ref.invalidate(coachMessagesProvider);
    return id;
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final repo = ref.read(coachRepositoryProvider);
    final current = state.value ?? [];
    final updated = current.map((c) {
      if (c.id == id) {
        return c.copyWith(title: newTitle, updatedAt: DateTime.now());
      }
      return c;
    }).toList();
    state = AsyncData(updated);
    await repo.saveConversations(updated);
  }

  Future<void> deleteConversation(String id) async {
    final repo = ref.read(coachRepositoryProvider);
    final current = state.value ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
    await repo.saveConversations(updated);
    if (ref.read(activeConversationIdProvider) == id && updated.isNotEmpty) {
      ref.read(activeConversationIdProvider.notifier).setActive(updated.first.id);
      ref.invalidate(coachMessagesProvider);
    }
  }

  Future<void> clearAll() async {
    final repo = ref.read(coachRepositoryProvider);
    final empty = <CoachConversation>[];
    state = AsyncData(empty);
    await repo.saveConversations(empty);
    ref.invalidate(coachMessagesProvider);
  }
}

final coachMessagesProvider =
    AsyncNotifierProvider<CoachMessagesNotifier, List<CoachMessage>>(
  CoachMessagesNotifier.new,
);

class CoachMessagesNotifier extends AsyncNotifier<List<CoachMessage>> {
  @override
  Future<List<CoachMessage>> build() async {
    final activeId = ref.watch(activeConversationIdProvider);
    final conversations = await ref.watch(coachConversationsProvider.future);
    final activeConv = conversations.firstWhere(
      (c) => c.id == activeId,
      orElse: () => conversations.isNotEmpty
          ? conversations.first
          : CoachConversation.seedConversations().first,
    );
    return activeConv.messages;
  }

  Future<void> send(String text, CoachPersona persona) async {
    final activeId = ref.read(activeConversationIdProvider);
    final repo = ref.read(coachRepositoryProvider);
    final profile = await ref.read(profileProvider.future);

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

    final currentMessages = state.value ?? [];
    final userMessage = CoachMessage(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    final withUser = [...currentMessages, userMessage];
    state = AsyncData(withUser);

    final credentials = await repo.loadCredentials();
    final consent = await repo.loadConsent();

    CoachMessage assistantMessage;
    if (!credentials.isConfigured || credentials.provider == AiProvider.offline) {
      assistantMessage = repo.offlineEngine.generateResponse(
        userQuery: text,
        persona: persona,
        profile: profile,
        todayNutrition: todayLog,
        todayHealth: todayHealth,
        recentWorkouts: sessions,
      );
    } else {
      try {
        final systemPrompt = repo.buildFullSystemPrompt(
          persona: persona,
          consent: consent,
          profile: profile,
          todayNutrition: todayLog,
          todayHealth: todayHealth,
          recentWorkouts: sessions,
        );
        assistantMessage = await repo.aiClient.sendMessage(
          history: withUser,
          systemPrompt: systemPrompt,
          credentials: credentials,
        );
      } catch (e) {
        final fallback = repo.offlineEngine.generateResponse(
          userQuery: text,
          persona: persona,
          profile: profile,
          todayNutrition: todayLog,
          todayHealth: todayHealth,
          recentWorkouts: sessions,
        );
        assistantMessage = fallback.copyWith(
          content: '⚠️ *Could not reach ${credentials.provider.displayName} (${e.toString()}). Falling back to Offline Engine:*\n\n${fallback.content}',
        );
      }
    }

    final finalMessages = [...withUser, assistantMessage];
    state = AsyncData(finalMessages);

    // Update conversation in list
    final convs = await repo.loadConversations();
    final updatedConvs = convs.map((c) {
      if (c.id == activeId) {
        final cleanContent = assistantMessage.content
            .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
            .replaceAll(RegExp(r'</?think>', caseSensitive: false), '')
            .replaceAll('**', '')
            .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
            .replaceAll('\n', ' ')
            .trim();
        return c.copyWith(
          messages: finalMessages,
          lastMessageSnippet: cleanContent.length > 60
              ? '${cleanContent.substring(0, 60)}...'
              : cleanContent,
          updatedAt: DateTime.now(),
        );
      }
      return c;
    }).toList();

    await repo.saveConversations(updatedConvs);
    ref.invalidate(coachConversationsProvider);
  }

  Future<void> toggleLike(String messageId, bool? isLiked) async {
    final current = state.value ?? [];
    final updated = current.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isLiked: isLiked);
      }
      return m;
    }).toList();
    state = AsyncData(updated);

    final activeId = ref.read(activeConversationIdProvider);
    final repo = ref.read(coachRepositoryProvider);
    final convs = await repo.loadConversations();
    final updatedConvs = convs.map((c) {
      if (c.id == activeId) {
        return c.copyWith(messages: updated);
      }
      return c;
    }).toList();
    await repo.saveConversations(updatedConvs);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    final activeId = ref.read(activeConversationIdProvider);
    final repo = ref.read(coachRepositoryProvider);
    final convs = await repo.loadConversations();
    final updatedConvs = convs.map((c) {
      if (c.id == activeId) {
        return c.copyWith(messages: [], lastMessageSnippet: '');
      }
      return c;
    }).toList();
    await repo.saveConversations(updatedConvs);
    ref.invalidate(coachConversationsProvider);
  }
}

final coachPreferencesProvider =
    AsyncNotifierProvider<CoachPreferencesNotifier, CoachPreferences>(
  CoachPreferencesNotifier.new,
);

class CoachPreferencesNotifier extends AsyncNotifier<CoachPreferences> {
  @override
  Future<CoachPreferences> build() {
    return ref.watch(coachRepositoryProvider).loadPreferences();
  }

  Future<void> savePreferences(CoachPreferences prefs) async {
    final repo = ref.read(coachRepositoryProvider);
    state = AsyncData(prefs);
    await repo.savePreferences(prefs);
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
