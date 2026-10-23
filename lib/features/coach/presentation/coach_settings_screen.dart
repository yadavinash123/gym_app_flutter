import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_client.dart';
import '../data/coach_repository.dart';
import '../models/ai_credentials.dart';
import '../models/ai_provider.dart';
import '../models/coach_persona.dart';
import '../models/coach_preferences.dart';

class CoachSettingsScreen extends ConsumerStatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  ConsumerState<CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends ConsumerState<CoachSettingsScreen> {
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  Future<void> _testConnection(AiCredentials creds) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final errorMsg =
        await ref.read(coachRepositoryProvider).checkConnection(creds);
    final success = errorMsg == null;

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testResult = success
          ? 'Connected successfully to ${creds.provider.displayName}!'
          : 'Connection failed: $errorMsg';
    });
  }

  void _showApiKeySheet(AiCredentials currentCreds) {
    final controller = TextEditingController(text: currentCreds.apiKey);
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentCreds.provider.displayName} API Key',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Your API key is stored securely on your device and never sent to any third-party server.',
                style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste API key here (sk-... or AIza...)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1E2836),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      setSheetState(() => obscure = !obscure);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (currentCreds.apiKey.isNotEmpty) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () async {
                        await ref
                            .read(coachCredentialsProvider.notifier)
                            .save(currentCreds.copyWith(apiKey: ''));
                        if (context.mounted) Navigator.pop(ctx);
                        setState(() {
                          _testResult = null;
                          _testSuccess = null;
                        });
                      },
                      child: const Text('Clear Key'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB6FF3B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final key = controller.text.trim();
                        final updated = currentCreds.copyWith(apiKey: key);
                        await ref
                            .read(coachCredentialsProvider.notifier)
                            .save(updated);
                        if (context.mounted) Navigator.pop(ctx);
                        if (key.isNotEmpty) {
                          _testConnection(updated);
                        }
                      },
                      child: const Text(
                        'Save API Key',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndpointSheet(AiCredentials currentCreds) {
    final controller = TextEditingController(
      text: currentCreds.customEndpointUrl.isNotEmpty
          ? currentCreds.customEndpointUrl
          : (currentCreds.provider == AiProvider.gemini
              ? ''
              : 'https://api.openai.com/v1'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'API Base URL / Endpoint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Specify base endpoint URL for OpenAI, OpenRouter, Groq, Ollama, or custom proxy.',
              style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://api.openai.com/v1',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E2836),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB6FF3B),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () async {
                final url = controller.text.trim();
                final normalized = url.isNotEmpty ? normalizeOpenAiEndpoint(url) : '';
                final updated = currentCreds.copyWith(customEndpointUrl: normalized);
                await ref.read(coachCredentialsProvider.notifier).save(updated);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Save Endpoint URL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(coachPreferencesProvider);
    final credsAsync = ref.watch(coachCredentialsProvider);

    final prefs = prefsAsync.value ?? const CoachPreferences();
    final creds = credsAsync.value ?? const AiCredentials();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AI Coach Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // -----------------------------------------------------------------
          // 1. AI Configuration Section
          // -----------------------------------------------------------------
          _buildSectionHeader('AI Configuration'),
          _buildGroupContainer(
            children: [
              _buildNavigationRow(
                icon: Icons.psychology_outlined,
                title: 'AI Model',
                value: prefs.aiModel,
                onTap: () => _pickOption(
                  title: 'Select AI Model',
                  options: [
                    'GPT-4o',
                    'GPT-4o-mini',
                    'gemini-1.5-flash',
                    'gemini-1.5-pro',
                    'claude-3-5-sonnet',
                    'llama-3.3-70b',
                  ],
                  current: prefs.aiModel,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(aiModel: val),
                        );
                    ref.read(coachCredentialsProvider.notifier).save(
                          creds.copyWith(modelName: val),
                        );
                  },
                ),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.dns_outlined,
                title: 'Provider',
                value: prefs.providerName,
                onTap: () => _pickProvider(creds),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.key_rounded,
                title: 'API Key',
                value: creds.apiKey.isNotEmpty ? creds.maskedApiKey : 'Not Configured',
                valueColor: creds.apiKey.isNotEmpty
                    ? const Color(0xFFB6FF3B)
                    : const Color(0xFFEF4444),
                onTap: () => _showApiKeySheet(creds),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.link_rounded,
                title: 'API Endpoint URL',
                value: creds.customEndpointUrl.isNotEmpty
                    ? (creds.customEndpointUrl.length > 20
                        ? '${creds.customEndpointUrl.substring(0, 20)}...'
                        : creds.customEndpointUrl)
                    : 'Default URL',
                onTap: () => _showEndpointSheet(creds),
              ),
              _buildDivider(),
              // Test Connection Row Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB6FF3B),
                          side: BorderSide(
                            color: const Color(0xFFB6FF3B).withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isTesting ? null : () => _testConnection(creds),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFB6FF3B),
                                ),
                              )
                            : const Icon(Icons.wifi_tethering_rounded, size: 18),
                        label: Text(
                          _isTesting ? 'Testing Connection...' : 'Test Connection',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _testSuccess == true
                              ? const Color(0xFF10281C)
                              : const Color(0xFF2E1719),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testSuccess == true
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess == true
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.language_rounded,
                title: 'Response Language',
                value: prefs.responseLanguage,
                onTap: () => _pickOption(
                  title: 'Select Language',
                  options: [
                    'English',
                    'Spanish',
                    'French',
                    'German',
                    'Japanese',
                    'Portuguese',
                    'Hindi',
                  ],
                  current: prefs.responseLanguage,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(responseLanguage: val),
                        );
                  },
                ),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.bolt_rounded,
                title: 'Streaming Responses',
                value: prefs.streamingResponses,
                onChanged: (val) {
                  ref.read(coachPreferencesProvider.notifier).savePreferences(
                        prefs.copyWith(streamingResponses: val),
                      );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 2. Personalization Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Personalization'),
          _buildGroupContainer(
            children: [
              _buildNavigationRow(
                icon: Icons.track_changes_rounded,
                title: 'Fitness Goal',
                value: prefs.fitnessGoal,
                onTap: () => _pickOption(
                  title: 'Select Fitness Goal',
                  options: [
                    'Muscle Gain',
                    'Fat Loss',
                    'Strength & Power',
                    'Cardio & Endurance',
                    'Mobility & Longevity',
                  ],
                  current: prefs.fitnessGoal,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(fitnessGoal: val),
                        );
                  },
                ),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.bar_chart_rounded,
                title: 'Training Level',
                value: prefs.trainingLevel,
                onTap: () => _pickOption(
                  title: 'Select Training Level',
                  options: [
                    'Beginner',
                    'Intermediate',
                    'Advanced',
                    'Elite Athlete',
                  ],
                  current: prefs.trainingLevel,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(trainingLevel: val),
                        );
                  },
                ),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.person_pin_circle_outlined,
                title: 'Preferred Coach Tone',
                value: prefs.preferredCoachTone,
                onTap: () => _pickOption(
                  title: 'Select Coach Tone',
                  options: [
                    'Motivational',
                    'Scientific / Evidence-Based',
                    'Strict Drill-Sergeant',
                    'Friendly & Casual',
                    'Holistic & Mindful',
                  ],
                  current: prefs.preferredCoachTone,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(preferredCoachTone: val),
                        );
                    if (val.contains('Scientific')) {
                      ref
                          .read(coachPersonaProvider.notifier)
                          .setPersona(CoachPersona.scientific);
                    } else if (val.contains('Motivational')) {
                      ref
                          .read(coachPersonaProvider.notifier)
                          .setPersona(CoachPersona.supportive);
                    } else if (val.contains('Strict')) {
                      ref
                          .read(coachPersonaProvider.notifier)
                          .setPersona(CoachPersona.hypertrophy);
                    } else if (val.contains('Holistic')) {
                      ref
                          .read(coachPersonaProvider.notifier)
                          .setPersona(CoachPersona.wellness);
                    }
                  },
                ),
              ),
              _buildDivider(),
              _buildNavigationRow(
                icon: Icons.format_align_left_rounded,
                title: 'Response Detail',
                value: prefs.responseDetail,
                onTap: () => _pickOption(
                  title: 'Select Response Detail',
                  options: [
                    'Balanced',
                    'Concise & Direct',
                    'In-Depth & Comprehensive',
                  ],
                  current: prefs.responseDetail,
                  onSelected: (val) {
                    ref.read(coachPreferencesProvider.notifier).savePreferences(
                          prefs.copyWith(responseDetail: val),
                        );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 3. Chat Preferences Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Chat Preferences'),
          _buildGroupContainer(
            children: [
              _buildSwitchRow(
                icon: Icons.schedule_rounded,
                title: 'Save Chat History',
                value: prefs.saveChatHistory,
                onChanged: (val) {
                  ref.read(coachPreferencesProvider.notifier).savePreferences(
                        prefs.copyWith(saveChatHistory: val),
                      );
                },
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.storage_rounded,
                title: 'Remember Conversation Context',
                value: prefs.rememberConversationContext,
                onChanged: (val) {
                  ref.read(coachPreferencesProvider.notifier).savePreferences(
                        prefs.copyWith(rememberConversationContext: val),
                      );
                },
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.mic_none_rounded,
                title: 'Voice Responses',
                value: prefs.voiceResponses,
                onChanged: (val) {
                  ref.read(coachPreferencesProvider.notifier).savePreferences(
                        prefs.copyWith(voiceResponses: val),
                      );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // -----------------------------------------------------------------
          // 4. Destructive Clear Chat History Button
          // -----------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A1519),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _confirmClearAllChats,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Clear Chat History',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 48,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFA7B0BF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFFA7B0BF),
                fontSize: 13,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6E7681),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA7B0BF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.black,
            activeTrackColor: const Color(0xFFB6FF3B),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: const Color(0xFF1F2937),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              ...options.map((opt) {
                final isSelected = opt == current;
                return ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFB6FF3B) : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFB6FF3B))
                      : null,
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _pickProvider(AiCredentials creds) {
    // Only Online Providers: Offline option removed
    final providers = [
      'OpenAI',
      'Google Gemini',
      'Custom (OpenAI-compatible)',
    ];
    _pickOption(
      title: 'Select AI Provider',
      options: providers,
      current: creds.provider == AiProvider.gemini
          ? 'Google Gemini'
          : (creds.provider == AiProvider.custom
              ? 'Custom (OpenAI-compatible)'
              : 'OpenAI'),
      onSelected: (val) {
        AiProvider selected = AiProvider.openai;
        if (val.contains('Gemini')) {
          selected = AiProvider.gemini;
        } else if (val.contains('Custom')) {
          selected = AiProvider.custom;
        }

        ref.read(coachPreferencesProvider.notifier).savePreferences(
              (ref.read(coachPreferencesProvider).value ?? const CoachPreferences())
                  .copyWith(providerName: val),
            );

        ref.read(coachCredentialsProvider.notifier).save(
              creds.copyWith(provider: selected),
            );
      },
    );
  }

  void _confirmClearAllChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Clear Chat History?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently erase all saved conversations and messages on this device.',
          style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(coachConversationsProvider.notifier).clearAll();
      await ref.read(coachMessagesProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat history cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
