import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/coach/data/ai_client.dart';
import 'package:fitforge_ai/features/coach/data/coach_repository.dart';
import 'package:fitforge_ai/features/coach/data/offline_coach_engine.dart';
import 'package:fitforge_ai/features/coach/data/secure_credentials_store.dart';
import 'package:fitforge_ai/features/coach/models/ai_credentials.dart';
import 'package:fitforge_ai/features/coach/models/ai_provider.dart';
import 'package:fitforge_ai/features/coach/models/coach_consent.dart';
import 'package:fitforge_ai/features/coach/models/coach_message.dart';
import 'package:fitforge_ai/features/coach/models/coach_persona.dart';
import 'package:fitforge_ai/features/coach/presentation/coach_screen.dart';
import 'package:fitforge_ai/features/coach/presentation/coach_settings_screen.dart';
import 'package:fitforge_ai/features/coach/presentation/consent_preview_dialog.dart';
import 'package:fitforge_ai/features/health/models/daily_health_summary.dart';
import 'package:fitforge_ai/features/nutrition/models/meal_log.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';
import 'package:fitforge_ai/features/coach/presentation/widgets/formatted_coach_text.dart';

class FakeAiClient implements AiClient {
  FakeAiClient({this.shouldSucceed = true, this.mockResponse = 'Mock LLM Response'});

  bool shouldSucceed;
  String mockResponse;
  int callCount = 0;
  String lastSystemPrompt = '';

  @override
  Future<CoachMessage> sendMessage({
    required List<CoachMessage> history,
    required String systemPrompt,
    required AiCredentials credentials,
  }) async {
    callCount++;
    lastSystemPrompt = systemPrompt;
    if (!shouldSucceed) {
      throw const AiException('Network connection failed (simulated)');
    }
    return CoachMessage(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: mockResponse,
      timestamp: DateTime.now(),
      offlineGenerated: false,
      provider: credentials.provider,
      modelName: credentials.activeModel,
      tokensUsed: 120,
    );
  }

  @override
  Future<bool> testConnection(AiCredentials credentials) async {
    return shouldSucceed;
  }

  @override
  Future<String?> checkConnection(AiCredentials credentials) async {
    return shouldSucceed ? null : 'Simulated connection failure';
  }
}

class FakeCoachMessagesNotifier extends CoachMessagesNotifier {
  FakeCoachMessagesNotifier(this._initial, this._repo);
  final List<CoachMessage> _initial;
  final CoachRepository _repo;

  @override
  Future<List<CoachMessage>> build() {
    state = AsyncData(_initial);
    return Future.value(_initial);
  }

  @override
  Future<void> send(String text, CoachPersona persona) async {
    final current = state.value ?? _initial;
    final userMsg = CoachMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    final responseMsg = _repo.offlineEngine.generateResponse(
      userQuery: text,
      persona: persona,
    );
    state = AsyncData([...current, userMsg, responseMsg]);
  }
}

class FakeCoachCredentialsNotifier extends CoachCredentialsNotifier {
  FakeCoachCredentialsNotifier([this._initial = const AiCredentials()]);
  final AiCredentials _initial;

  @override
  Future<AiCredentials> build() {
    state = AsyncData(_initial);
    return Future.value(_initial);
  }

  @override
  Future<void> save(AiCredentials credentials) async {
    state = AsyncData(credentials);
  }
}

class FakeCoachConsentNotifier extends CoachConsentNotifier {
  FakeCoachConsentNotifier([this._initial = const CoachConsent()]);
  final CoachConsent _initial;

  @override
  Future<CoachConsent> build() {
    state = AsyncData(_initial);
    return Future.value(_initial);
  }

  @override
  Future<void> updateConsent(CoachConsent consent) async {
    state = AsyncData(consent);
  }
}

class FakeCoachPersonaNotifier extends CoachPersonaNotifier {
  FakeCoachPersonaNotifier([this._initial = CoachPersona.scientific]);
  final CoachPersona _initial;

  @override
  Future<CoachPersona> build() {
    state = AsyncData(_initial);
    return Future.value(_initial);
  }

  @override
  Future<void> setPersona(CoachPersona persona) async {
    state = AsyncData(persona);
  }
}

void main() {
  late Directory tempDir;
  late JsonStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitforge_coach_test_');
    store = JsonStore(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AiProvider Model', () {
    test('verifies all enum values, models, and metadata', () {
      expect(AiProvider.gemini.displayName, 'Google Gemini');
      expect(AiProvider.openai.displayName, 'OpenAI');
      expect(AiProvider.custom.displayName, 'Custom (OpenAI-compatible)');
      expect(AiProvider.offline.displayName, 'Offline Heuristic Coach');

      expect(AiProvider.gemini.defaultModel, 'gemini-1.5-flash');
      expect(AiProvider.openai.defaultModel, 'gpt-4o-mini');

      expect(AiProvider.gemini.suggestedModels, contains('gemini-1.5-flash'));
      expect(AiProvider.openai.suggestedModels, contains('gpt-4o-mini'));
      expect(AiProvider.custom.suggestedModels, contains('openai/gpt-oss-20b'));
      expect(AiProvider.custom.suggestedModels, contains('llama-3.3-70b-versatile'));

      expect(AiProvider.fromString('gemini'), AiProvider.gemini);
      expect(AiProvider.fromString('openai'), AiProvider.openai);
      expect(AiProvider.fromString('custom'), AiProvider.custom);
      expect(AiProvider.fromString('offline'), AiProvider.offline);
      expect(AiProvider.fromString('unknown'), AiProvider.offline);
    });

    test('normalizeOpenAiEndpoint handles base URLs and variations', () {
      expect(
        normalizeOpenAiEndpoint('https://api.groq.com/openai/v1'),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(
        normalizeOpenAiEndpoint('https://api.groq.com/openai/v1/'),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(
        normalizeOpenAiEndpoint('https://api.groq.com/openai/v1/chat/completions'),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(
        normalizeOpenAiEndpoint('http://localhost:11434'),
        'http://localhost:11434/v1/chat/completions',
      );
      expect(
        normalizeOpenAiEndpoint(''),
        'https://api.openai.com/v1/chat/completions',
      );
    });
  });

  group('AiCredentials Model', () {
    test('default state, masking, and JSON serialization', () {
      const defaultCreds = AiCredentials();
      expect(defaultCreds.provider, AiProvider.offline);
      expect(defaultCreds.isConfigured, isTrue);
      expect(defaultCreds.maskedApiKey, 'Not configured');

      const onlineCreds = AiCredentials(
        provider: AiProvider.gemini,
        apiKey: 'AIzaSyDemoKey1234567890XYZ',
        modelName: 'gemini-1.5-pro',
      );
      expect(onlineCreds.isConfigured, isTrue);
      expect(onlineCreds.activeModel, 'gemini-1.5-pro');
      expect(onlineCreds.maskedApiKey, 'AIza••••••••0XYZ');

      final json = onlineCreds.toJson();
      final revived = AiCredentials.fromJson(json);
      expect(revived, equals(onlineCreds));
      expect(revived.apiKey, 'AIzaSyDemoKey1234567890XYZ');
    });
  });

  group('CoachPersona Model', () {
    test('verifies all 4 personas and directives', () {
      expect(CoachPersona.values.length, 4);
      for (final p in CoachPersona.values) {
        expect(p.displayName.isNotEmpty, isTrue);
        expect(p.shortDescription.isNotEmpty, isTrue);
        expect(p.systemDirective.isNotEmpty, isTrue);
      }

      expect(CoachPersona.fromString('scientific'), CoachPersona.scientific);
      expect(CoachPersona.fromString('supportive'), CoachPersona.supportive);
      expect(CoachPersona.fromString('hypertrophy'), CoachPersona.hypertrophy);
      expect(CoachPersona.fromString('wellness'), CoachPersona.wellness);
      expect(CoachPersona.fromString('invalid'), CoachPersona.scientific);
    });
  });

  group('CoachConsent & Privacy Model', () {
    test('defaults to all true with active count tracking', () {
      const consent = CoachConsent();
      expect(consent.shareProfile, isTrue);
      expect(consent.shareWorkouts, isTrue);
      expect(consent.shareNutrition, isTrue);
      expect(consent.shareHealth, isTrue);
      expect(consent.activeShareCount, 4);

      final partial = consent.copyWith(shareHealth: false, shareNutrition: false);
      expect(partial.activeShareCount, 2);

      final json = partial.toJson();
      final revived = CoachConsent.fromJson(json);
      expect(revived, equals(partial));
    });
  });

  group('CoachMessage Model', () {
    test('serializes and deserializes message history', () {
      final msg = CoachMessage(
        id: 'msg_1',
        role: MessageRole.assistant,
        content: 'Hello, Athlete!',
        timestamp: DateTime(2026, 10, 22, 10, 30),
        offlineGenerated: true,
        suggestedActions: const ['Next workout', 'Macros'],
      );

      final json = msg.toJson();
      final revived = CoachMessage.fromJson(json);
      expect(revived.id, 'msg_1');
      expect(revived.isAssistant, isTrue);
      expect(revived.content, 'Hello, Athlete!');
      expect(revived.offlineGenerated, isTrue);
      expect(revived.suggestedActions, contains('Next workout'));
    });
  });

  group('SecureCredentialsStore & Obfuscation at Rest', () {
    test('obfuscates API key on disk and retrieves it intact', () async {
      final secureStore = JsonSecureCredentialsStore(store);

      final initial = await secureStore.readCredentials();
      expect(initial, isNull);

      const creds = AiCredentials(
        provider: AiProvider.gemini,
        apiKey: 'AIzaSySecretTestingKey99',
        modelName: 'gemini-1.5-flash',
      );
      await secureStore.writeCredentials(creds);

      final rawDiskData = await store.read(JsonSecureCredentialsStore.storageKey);
      expect(rawDiskData, isNotNull);
      expect(rawDiskData!.containsKey('apiKey'), isFalse);
      expect(rawDiskData.containsKey('obfuscatedKey'), isTrue);
      expect(rawDiskData['obfuscatedKey'], isNot(equals('AIzaSySecretTestingKey99')));

      final restored = await secureStore.readCredentials();
      expect(restored, isNotNull);
      expect(restored!.apiKey, 'AIzaSySecretTestingKey99');
      expect(restored.provider, AiProvider.gemini);

      await secureStore.clearCredentials();
      final afterClear = await secureStore.readCredentials();
      expect(afterClear!.apiKey, isEmpty);
    });
  });

  group('OfflineCoachEngine Reasoning', () {
    const engine = OfflineCoachEngine();

    final testProfile = const Profile(
      name: 'Jane Doe',
      level: 'Intermediate',
      goal: 'Build muscle',
      days: 4,
      environment: 'Gym',
      age: 26,
      heightCm: 172.0,
      weightKg: 68.0,
      calorieTarget: 2400.0,
      proteinTarget: 140.0,
      schedule: ['Chest & Triceps', 'Back & Biceps', 'Rest', 'Legs', 'Shoulders', 'Rest', 'Rest'],
    );

    test('analyzes nutrition question and calculates ISSN protein ratio', () {
      final mealLog = DailyNutritionLog(
        date: '2026-10-22',
        waterMl: 2800,
      );
      mealLog.meals[MealType.breakfast]!.items.add(
        LoggedFoodItem(
          id: 'item_1',
          foodId: 'f1',
          name: 'Eggs',
          portionName: 'Whole',
          grams: 100,
          quantity: 2,
          calories: 300,
          protein: 26,
          carbs: 2,
          fat: 20,
          fiber: 0,
        ),
      );

      final response = engine.generateResponse(
        userQuery: 'How is my protein intake today?',
        persona: CoachPersona.scientific,
        profile: testProfile,
        todayNutrition: mealLog,
      );

      expect(response.offlineGenerated, isTrue);
      expect(response.content, contains('Nutritional Balance & Fueling Analysis'));
      expect(response.content, contains('ISSN Protein Evaluation'));
      expect(response.content, contains('g/kg bodyweight'));
      expect(response.suggestedActions.isNotEmpty, isTrue);
    });

    test('analyzes recovery and evaluates sleep and resting HR', () {
      const healthSummary = DailyHealthSummary(
        date: '2026-10-22',
        sleepDurationMinutes: 510,
        restingHeartRateBpm: 56,
      );

      final response = engine.generateResponse(
        userQuery: 'Am I recovered enough to train hard today?',
        persona: CoachPersona.wellness,
        profile: testProfile,
        todayHealth: healthSummary,
      );

      expect(response.offlineGenerated, isTrue);
      expect(response.content, contains('Recovery & Readiness Assessment'));
      expect(response.content, contains('8.5 hours'));
      expect(response.content, contains('Optimal Sleep Duration'));
      expect(response.content, contains('56 bpm'));
    });

    test('explains progressive overload and double-progression rules', () {
      final response = engine.generateResponse(
        userQuery: 'How do I progress my lifts safely?',
        persona: CoachPersona.hypertrophy,
        profile: testProfile,
      );

      expect(response.content, contains('Double-Progression Method'));
      expect(response.content, contains('2.5%–5%'));
      expect(response.content, contains('RIR Management'));
    });

    test('evaluates Tanaka cardiovascular zones based on user age', () {
      final response = engine.generateResponse(
        userQuery: 'What are my heart rate training zones?',
        persona: CoachPersona.scientific,
        profile: testProfile,
      );

      expect(response.content, contains('Tanaka Formula Age-Predicted HRmax'));
      expect(response.content, contains('Zone 1: Active Recovery'));
      expect(response.content, contains('Zone 2: Aerobic Base'));
    });

    test('generates comprehensive briefing for general greetings', () {
      final response = engine.generateResponse(
        userQuery: 'Good morning coach, what is my overview today?',
        persona: CoachPersona.supportive,
        profile: testProfile,
      );

      expect(response.content, contains('FitForge AI Coach Daily Briefing'));
      expect(response.content, contains('Primary Fitness Goal:'));
      expect(response.content, contains('Build muscle'));
      expect(response.content, contains('Energy Target:'));
      expect(response.content, contains('2400 kcal'));
    });
  });

  group('CoachRepository & Anonymization Privacy Guarantee', () {
    late SecureCredentialsStore secureStore;
    late FakeAiClient fakeClient;
    late CoachRepository repo;

    setUp(() {
      secureStore = JsonSecureCredentialsStore(store);
      fakeClient = FakeAiClient();
      repo = CoachRepository(
        store: store,
        credentialsStore: secureStore,
        aiClient: fakeClient,
      );
    });

    final testProfile = const Profile(
      name: 'SuperSecretUserName Jane',
      level: 'Advanced',
      goal: 'Fat loss',
      days: 5,
      environment: 'Home',
      age: 32,
      heightCm: 165.0,
      weightKg: 62.0,
      calorieTarget: 1800.0,
      proteinTarget: 130.0,
    );

    test('buildPromptContext strictly strips user name and PII', () {
      final contextText = repo.buildPromptContext(
        consent: const CoachConsent(),
        profile: testProfile,
      );

      expect(contextText, isNot(contains('SuperSecretUserName')));
      expect(contextText, isNot(contains('Jane')));
      expect(contextText, contains('Age: 32'));
      expect(contextText, contains('Primary Fitness Goal: Fat loss'));
      expect(contextText, contains('Daily Energy Target: 1800 kcal'));
    });

    test('buildPromptContext respects privacy toggles when disabled', () {
      const consent = CoachConsent(
        shareProfile: false,
        shareWorkouts: false,
        shareNutrition: false,
        shareHealth: false,
      );

      final contextText = repo.buildPromptContext(
        consent: consent,
        profile: testProfile,
      );

      expect(contextText, contains('BODY METRICS: [Redacted by user privacy choice]'));
      expect(contextText, contains('NUTRITION LOG: [Redacted by user privacy choice]'));
      expect(contextText, contains('WORKOUT HISTORY: [Redacted by user privacy choice]'));
      expect(contextText, contains('HEALTH BIOMARKERS: [Redacted by user privacy choice]'));
    });

    test('chat persistence and clearing', () async {
      final initial = await repo.loadMessages();
      expect(initial.length, 1);
      expect(initial.first.content, contains('Welcome to FitForge AI Coach'));

      final updated = await repo.sendMessage(
        text: 'How should I overload my bench press?',
        persona: CoachPersona.hypertrophy,
        profile: testProfile,
      );

      expect(updated.length, 3);
      expect(updated[1].isUser, isTrue);
      expect(updated[2].isAssistant, isTrue);
      expect(updated[2].offlineGenerated, isTrue);

      final reloaded = await repo.loadMessages();
      expect(reloaded.length, 3);

      await repo.clearChat();
      final cleared = await repo.loadMessages();
      expect(cleared.length, 1);
    });

    test('dispatches to online LLM when BYOK key configured and falls back on network error', () async {
      await repo.saveCredentials(const AiCredentials(
        provider: AiProvider.gemini,
        apiKey: 'AIzaSyValidApiKey123',
        modelName: 'gemini-1.5-flash',
      ));

      fakeClient.shouldSucceed = true;
      fakeClient.mockResponse = 'Detailed hypertrophy advice from Gemini';

      final res1 = await repo.sendMessage(
        text: 'Tell me about volume landmarks',
        persona: CoachPersona.hypertrophy,
        profile: testProfile,
      );

      expect(fakeClient.callCount, 1);
      expect(res1.last.content, 'Detailed hypertrophy advice from Gemini');
      expect(res1.last.offlineGenerated, isFalse);
      expect(res1.last.provider, AiProvider.gemini);

      fakeClient.shouldSucceed = false;

      final res2 = await repo.sendMessage(
        text: 'How to recover from deadlifts?',
        persona: CoachPersona.wellness,
        profile: testProfile,
      );

      expect(res2.last.offlineGenerated, isTrue);
      expect(res2.last.content, contains('Could not reach Google Gemini'));
      expect(res2.last.content, contains('Falling back to Offline Rule Engine'));
    });
  });

  group('Coach UI & Widget Tests', () {
    final welcomeMessage = [
      CoachMessage(
        id: 'welcome_1',
        role: MessageRole.assistant,
        content: '👋 Welcome to FitForge AI Coach!\n\nHow can I help you today?',
        timestamp: DateTime.now(),
        offlineGenerated: true,
      ),
    ];

    testWidgets('CoachScreen renders status bar, welcome bubble, suggestions, and sends a prompt', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final secureStore = JsonSecureCredentialsStore(store);
      final fakeClient = FakeAiClient();
      final repo = CoachRepository(
        store: store,
        credentialsStore: secureStore,
        aiClient: fakeClient,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            coachRepositoryProvider.overrideWithValue(repo),
            coachMessagesProvider.overrideWith(() => FakeCoachMessagesNotifier(welcomeMessage, repo)),
            coachCredentialsProvider.overrideWith(() => FakeCoachCredentialsNotifier(const AiCredentials())),
            coachConsentProvider.overrideWith(() => FakeCoachConsentNotifier(const CoachConsent())),
            coachPersonaProvider.overrideWith(() => FakeCoachPersonaNotifier(CoachPersona.scientific)),
          ],
          child: const MaterialApp(
            home: CoachScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('FitForge'), findsOneWidget);
      expect(find.text('AI Coach • Ready'), findsOneWidget);
      expect(find.textContaining('crush your goals'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Continue Last Chat'),
        find.byType(SingleChildScrollView),
        const Offset(0, -150),
      );
      await tester.pump();

      await tester.tap(find.text('Continue Last Chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FitForge AI'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'How to overload safely?');
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('How to overload safely?'), findsOneWidget);
      expect(find.textContaining('Progressive Overload'), findsOneWidget);
    });

    testWidgets('CoachSettingsScreen displays sections and preferences', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final secureStore = JsonSecureCredentialsStore(store);
      final fakeClient = FakeAiClient();
      final repo = CoachRepository(
        store: store,
        credentialsStore: secureStore,
        aiClient: fakeClient,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            coachRepositoryProvider.overrideWithValue(repo),
            coachCredentialsProvider.overrideWith(() => FakeCoachCredentialsNotifier(const AiCredentials())),
            coachConsentProvider.overrideWith(() => FakeCoachConsentNotifier(const CoachConsent())),
          ],
          child: const MaterialApp(
            home: CoachSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('AI Coach Settings'), findsOneWidget);
      expect(find.text('AI Configuration'), findsOneWidget);
      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Fitness Goal'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Chat Preferences'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pump();
      expect(find.text('Chat Preferences'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Clear Chat History'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pump();

      expect(find.text('Clear Chat History'), findsOneWidget);
    });

    testWidgets('ConsentPreviewDialog renders payload without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final secureStore = JsonSecureCredentialsStore(store);
      final fakeClient = FakeAiClient();
      final repo = CoachRepository(
        store: store,
        credentialsStore: secureStore,
        aiClient: fakeClient,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            coachRepositoryProvider.overrideWithValue(repo),
            coachConsentProvider.overrideWith(() => FakeCoachConsentNotifier(const CoachConsent())),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConsentPreviewDialog(persona: CoachPersona.scientific),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Prompt & Privacy Inspection'), findsOneWidget);
      expect(find.textContaining('Zero-PII Guarantee'), findsOneWidget);
      expect(find.text('Copy Payload'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('CoachScreen responsive render on narrow screen (320x640) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final secureStore = JsonSecureCredentialsStore(store);
      final fakeClient = FakeAiClient();
      final repo = CoachRepository(
        store: store,
        credentialsStore: secureStore,
        aiClient: fakeClient,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            coachRepositoryProvider.overrideWithValue(repo),
            coachMessagesProvider.overrideWith(() => FakeCoachMessagesNotifier(welcomeMessage, repo)),
            coachCredentialsProvider.overrideWith(() => FakeCoachCredentialsNotifier(const AiCredentials())),
            coachConsentProvider.overrideWith(() => FakeCoachConsentNotifier(const CoachConsent())),
            coachPersonaProvider.overrideWith(() => FakeCoachPersonaNotifier(CoachPersona.scientific)),
          ],
          child: const MaterialApp(
            home: CoachScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('FormattedCoachText removes all stray and unclosed ** characters and renders clean text', (tester) async {
      const responseWithAsterisks = '''
### **Zone 2 Cardiovascular Plan**
• **Optimal Target:** 135 bpm
- **Energy:** **2100 / 2500 kcal**
**Sub-optimal Sleep Volume:** Under 7 hours
| Nutrient | Target |
| Protein | **160g** |
**
• **
*- **Consistency is key**
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormattedCoachText(text: responseWithAsterisks),
          ),
        ),
      );

      await tester.pump();

      // Ensure no raw "**" is displayed anywhere in text widgets
      expect(find.textContaining('**'), findsNothing);
      expect(find.text('Zone 2 Cardiovascular Plan'), findsOneWidget);
      expect(find.textContaining('Optimal Target:'), findsOneWidget);
      expect(find.textContaining('Sub-optimal Sleep Volume:'), findsOneWidget);
      expect(find.textContaining('Consistency is key'), findsOneWidget);
    });
  });
}

