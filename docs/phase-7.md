# Phase 7: Bring-Your-Own-Key (BYOK) AI Coach, Secure Credentials, and Consent Previews

## Overview

Phase 7 introduces the intelligent, privacy-first **AI Coach Station** to FitForge AI. Designed strictly around an **offline-first and zero-PII architecture**, FitForge empowers users to receive evidence-based workout, nutrition, recovery, and hypertrophy guidance either via a 100% private, on-device heuristic engine or through their own online LLM API keys (**Bring Your Own Key / BYOK**).

Supported providers include:
1. **Offline Heuristic Rule Engine** (Default, zero network calls, 100% private on device).
2. **Google Gemini** (e.g. `gemini-1.5-flash`, `gemini-1.5-pro`).
3. **OpenAI** (e.g. `gpt-4o-mini`, `gpt-4o`).
4. **Custom OpenAI-Compatible Endpoints** (Local LLMs, Ollama, vLLM, self-hosted proxies).

Users maintain complete autonomy through **Granular Consent Previews**: before or during chat interactions, users can inspect the exact anonymized prompt payload sent to the model and toggle four independent data streams (Profile & Fitness Goals, Workout History, Nutrition Logs, and Health Biomarkers). Under all circumstances, personal identifiers (User Name, Email) are strictly stripped from the prompt payload.

---

## Architecture & Components

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FitForge UI Presentation Layer                  │
│   CoachScreen (/coach) ── CoachSettingsScreen (/coach/settings)        │
│          │                               │                             │
│          └── ConsentPreviewDialog ◄──────┘                             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Riverpod Providers
┌───────────────────────────────────▼────────────────────────────────────┐
│                       CoachRepository Pipeline                         │
│  - Anonymization Engine (Strips Name, Email, Identifiers)              │
│  - Granular Consent Filtering (Profile, Workouts, Nutrition, Health)   │
│  - Chat Persistence (`coach_chat.json`)                                │
│  - Automatic Offline Fallback on Network Error                         │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
      BYOK Configured & Online             Offline Mode / Network Fail
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│            HttpAiClient              │  │     OfflineCoachEngine       │
│  - Google Gemini REST API            │  │  - ISSN Protein Ratios       │
│  - OpenAI / Custom Chat Completions  │  │  - Tanaka HR Zones & Cardio  │
│  - Obfuscated Storage at Rest        │  │  - Double-Progression Rules  │
│    (`coach_credentials.json`)        │  │  - Autonomic Sleep & Rest HR │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

### 1. Data Models (`lib/features/coach/models/`)
- **`AiProvider` (`ai_provider.dart`)**:
  - Enum: `gemini`, `openai`, `custom`, `offline`.
  - Properties: `displayName`, `defaultModel`, `suggestedModels`, `icon`, `brandColor`, `documentationUrl`.
- **`AiCredentials` (`ai_credentials.dart`)**:
  - Encapsulates provider configuration: `provider`, `apiKey`, `modelName`, `customEndpointUrl`, `temperature`.
  - `maskedApiKey`: Displays key safely in UI (e.g., `AIza••••••••0XYZ`) without leaking secrets.
  - Serialization to/from JSON.
- **`CoachPersona` (`coach_persona.dart`)**:
  - Four distinct coaching styles:
    - `scientific`: Direct citations, precise volume landmarks, ISSN and Tanaka references.
    - `supportive`: Warm, encouraging, empathetic habit-building focus.
    - `hypertrophy`: Reps in Reserve (RIR), mechanical tension, metabolite accumulation, mesocycle fatigue management.
    - `wellness`: Holistic longevity, circadian rhythm optimization, mobility, stress mitigation.
  - Contains full immutable `systemDirective` instructions for LLM context.
- **`CoachConsent` (`coach_consent.dart`)**:
  - Granular privacy toggles:
    - `shareProfile`: Age, height, weight, experience level, goal (zero name or email).
    - `shareWorkouts`: Recent exercises, completed sets, volume, and PRs.
    - `shareNutrition`: Daily calories, protein, carbs, fats, and water intake.
    - `shareHealth`: Daily steps, resting heart rate, and sleep duration.
  - `activeShareCount`: Reactive count of enabled data streams displayed in the status bar.
- **`CoachMessage` (`coach_message.dart`)**:
  - Message exchange model: `id`, `role` (`user`, `assistant`, `system`), `content`, `timestamp`, `offlineGenerated`, `provider`, `modelName`, `tokensUsed`, `suggestedActions`.

---

### 2. Security & Credentials Management (`lib/features/coach/data/secure_credentials_store.dart`)
- **At-Rest Obfuscation**:
  - `JsonSecureCredentialsStore` persists API credentials to `coach_credentials.json`.
  - Keys are never written as raw plaintext on disk; keys are transformed using XOR-salt obfuscation with device-specific salt seeds:
    $$\text{ObfuscatedKey} = \text{Base64}(\text{KeyBytes} \oplus \text{SaltBytes})$$
- **Immediate Zeroization**:
  - "Clear API Key" button in `CoachSettingsScreen` instantly overwrites disk credentials with empty keys, removing credentials from storage and switching the engine back to offline mode.

---

### 3. Multi-Provider BYOK Client (`lib/features/coach/data/ai_client.dart`)
- Implemented with zero third-party dependencies using standard Dart `dart:io` `HttpClient`:
- **Google Gemini**:
  - Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{modelName}:generateContent?key={apiKey}`
  - Supports system instructions and multi-turn content histories.
- **OpenAI & Custom Endpoints**:
  - Endpoint: `https://api.openai.com/v1/chat/completions` (or custom user URL).
  - Standard Bearer token authentication header (`Authorization: Bearer <API_KEY>`).
- **Resilience & Testing**:
  - 30-second timeout on network connections.
  - `testConnection(credentials)`: Probes model endpoint with a 1-token dummy prompt to validate API keys before saving.
  - Error classification: Categorizes 401 Unauthorized, 429 Rate Limits, 404 Model Not Found, and socket connection failures.

---

### 4. 100% Offline Rule-Based Heuristic Engine (`lib/features/coach/data/offline_coach_engine.dart`)
When offline or when online requests fail, FitForge falls back to an evidence-based exercise science engine:
- **ISSN Protein & Nutrition Analysis**:
  - Evaluates protein intake relative to bodyweight against the ISSN guideline ($1.6\text{--}2.2\text{ g/kg}$).
  - Computes caloric pacing relative to user Mifflin–St Jeor target.
  - Flags water hydration adequacy ($2.5\text{--}3.5\text{ L}$).
- **Tanaka Cardiovascular Training Zones**:
  - Evaluates age-predicted maximal heart rate:
    $$\text{HR}_{\max} = 208 - (0.7 \times \text{age})$$
  - Generates 5 physiological heart rate training zones (Zone 1 Active Recovery through Zone 5 Anaerobic Peak).
- **Double-Progression Progressive Overload**:
  - Explains micro-loading ($2.5\%\text{--}5\%$), working set rep ranges, eccentric tempo (3-second cadence), and RIR guidelines (2 RIR for compound lifts, 0–1 RIR for isolation lifts).
- **Autonomic Recovery & Sleep Evaluation**:
  - Classifies resting heart rate against clinical baselines.
  - Analyzes sleep volume ($<7\text{h}$ sub-optimal, $8+\text{h}$ optimal).
  - Adjusts recommended training volume and RPE load based on readiness.

---

### 5. Privacy-First Context Assembly (`lib/features/coach/data/coach_repository.dart`)
- **Zero-PII Guarantee**:
  - User name and email address are strictly omitted from `buildPromptContext()`.
  - Prompts use generic subject markers: `User Age`, `User Weight`, `User Height`, `Experience Level`.
- **Granular Redaction**:
  - When a user turns off a data stream (e.g. `shareNutrition: false`), the prompt replaces the section with `[Redacted by user privacy choice]`.
- **Live Preview Dialog (`ConsentPreviewDialog`)**:
  - Users can view and copy the raw assembled prompt payload to their clipboard at any time to verify that zero private information is exposed.

---

### 6. User Interface & Experience
- **`CoachScreen` (`/coach`)**:
  - Status Bar: Provider badge (color-coded by brand), persona dropdown selector, privacy stream count banner, and prompt payload inspection button.
  - Chat Bubble List: Markdown-formatted responses, provider tags, token count badges, and one-tap copy button.
  - Follow-up Suggestion Chips: Contextual action chips allowing one-tap follow-up questions.
  - Responsive Layout: Engineered and tested down to 320px narrow screens with zero RenderFlex overflows.
- **`CoachSettingsScreen` (`/coach/settings`)**:
  - Provider selection chips with brand colors.
  - Masked API key input with toggleable visibility.
  - Model selection suggestions chip row.
  - Custom endpoint URL input.
  - Creativity (Temperature) slider ($0.0\text{--}1.0$).
  - "Test Connection" button with real-time ping indicator.
  - Four independent privacy switches.
  - "Inspect Assembled Payload Preview" launcher.
  - Data management: "Clear API Key" and "Reset Chat History".
  - Medical educational disclaimer.
- **Dashboard Integration**:
  - Added "AI COACH STATION" quick access card on `DashboardScreen` displaying the active provider status and direct navigation to the coach.

---

## Scientific Citations

1. **ISSN Position Stand on Protein & Exercise**:
   - Jäger, R., Kerksick, C. M., Campbell, B. I., et al. (2017). *International Society of Sports Nutrition Position Stand: protein and exercise.* Journal of the International Society of Sports Nutrition, 14(1), 20.
   - Guideline: $1.4\text{--}2.0\text{ g/kg/day}$ for building and maintaining muscle mass; upwards of $2.2\text{ g/kg/day}$ in hypocaloric conditions.
2. **Tanaka Age-Predicted HRmax Formula**:
   - Tanaka, H., Monahan, K. D., & Seals, D. R. (2001). *Age-predicted maximal heart rate revisited.* Journal of the American College of Cardiology, 37(1), 153–156.
   - Formula: $\text{HR}_{\max} = 208 - (0.7 \times \text{age})$.
3. **Double-Progression & Hypertrophy Mechanisms**:
   - Schoenfeld, B. J., Ogborn, D., & Krieger, J. W. (2016). *Dose-response relationship between weekly resistance training volume and increases in muscle mass.* Journal of Sports Sciences, 35(11), 1073–1082.
   - Helms, E. R., Cronin, J., Storey, A., & Zourdos, M. C. (2016). *Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training.* Strength and Conditioning Journal, 38(4), 42–49.
4. **Sleep Architecture & Physical Performance**:
   - Walker, M. P. (2017). *Why We Sleep: Unlocking the Power of Sleep and Dreams.* Scribner.
   - Deep (slow-wave) sleep regulates growth hormone secretion and glycogen synthesis; sub-7 hour sleep elevates cortisol and impairs motor unit recruitment.

---

## Verification & Test Results

- **Test Suite Results**:
  - **105 out of 105 tests passing** (19 new tests in `test/coach_test.dart` + 86 existing regression tests from Phases 1–6).
- **Test Categories**:
  - `AiProvider Model`: Enum serialization, metadata, brand colors, default models.
  - `AiCredentials Model`: Masking (`AIza••••••••0XYZ`), active model selection, JSON roundtrip.
  - `CoachPersona Model`: Persona directives and display naming.
  - `CoachConsent & Privacy Model`: Active stream counting and copyWith immutability.
  - `CoachMessage Model`: Message history serialization and offline flags.
  - `SecureCredentialsStore & Obfuscation`: Disk obfuscation, key extraction, and zeroization.
  - `OfflineCoachEngine Reasoning`: ISSN protein calculations, sleep/heart rate evaluation, progressive overload explanation, Tanaka zones, general briefings.
  - `CoachRepository`: Zero-PII sanitization, privacy redaction, chat persistence, network fallback to offline engine.
  - `CoachScreen Widget Tests`: Status bar, persona selector, quick suggestion chips, message input, prompt dispatching.
  - `CoachSettingsScreen Widget Tests`: Provider switching, connection testing, privacy toggles, key clearing.
  - `ConsentPreviewDialog Widget Tests`: Payload rendering, clipboard copy, zero overflow.
  - `Responsive Narrow Layout Tests`: Verified zero RenderFlex overflow on 320x640 mobile viewports.
- **Static Analysis**:
  - `flutter analyze`: **0 issues found** across the entire codebase.
