import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_body.dart';
import '../data/coach_repository.dart';
import '../models/ai_credentials.dart';
import '../models/ai_provider.dart';
import 'consent_preview_dialog.dart';

class CoachSettingsScreen extends ConsumerStatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  ConsumerState<CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends ConsumerState<CoachSettingsScreen> {
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  final _endpointController = TextEditingController();

  AiProvider _selectedProvider = AiProvider.gemini;
  double _temperature = 0.7;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromStore());
  }

  Future<void> _initFromStore() async {
    final creds = await ref.read(coachCredentialsProvider.future);
    if (!mounted) return;
    setState(() {
      _selectedProvider = creds.provider;
      _keyController.text = creds.apiKey;
      _modelController.text = creds.modelName.isNotEmpty
          ? creds.modelName
          : creds.provider.defaultModel;
      _endpointController.text = creds.customEndpointUrl;
      _temperature = creds.temperature;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    final updated = AiCredentials(
      provider: _selectedProvider,
      apiKey: _keyController.text.trim(),
      modelName: _modelController.text.trim(),
      customEndpointUrl: _endpointController.text.trim(),
      temperature: _temperature,
    );
    await ref.read(coachCredentialsProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Coach configuration saved successfully')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final tempCreds = AiCredentials(
      provider: _selectedProvider,
      apiKey: _keyController.text.trim(),
      modelName: _modelController.text.trim(),
      customEndpointUrl: _endpointController.text.trim(),
      temperature: _temperature,
    );

    final success = await ref.read(coachRepositoryProvider).testConnection(tempCreds);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testResult = success
          ? 'Connected successfully to ${_selectedProvider.displayName}!'
          : 'Connection failed. Verify your API key, endpoint, or network connection.';
    });
  }

  Future<void> _confirmClearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        title: const Text('Clear API Key?'),
        content: const Text(
          'This will remove your API key from this device and return FitForge to 100% Offline Coach mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Key'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(coachCredentialsProvider.notifier).clear();
      setState(() {
        _keyController.clear();
        _selectedProvider = AiProvider.offline;
        _testResult = null;
        _testSuccess = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API credentials cleared. Switched to Offline mode.')),
        );
      }
    }
  }

  Future<void> _confirmResetChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        title: const Text('Reset Chat History?'),
        content: const Text('This will delete all past conversation messages with the coach.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(coachMessagesProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history reset.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consentAsync = ref.watch(coachConsentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('COACH & AI SETTINGS'),
        actions: [
          IconButton(
            tooltip: 'Inspect Prompt Payload',
            icon: const Icon(Icons.privacy_tip_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ConsentPreviewDialog(),
            ),
          ),
        ],
      ),
      body: PageBody(
        children: [
          // 1. AI Provider Selection
          Text('AI Engine & Provider (BYOK)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'FitForge is offline-first. Connect your own API key to enable online LLM reasoning, or use the 100% private offline engine.',
            style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AiProvider.values.map((p) {
              final isSelected = _selectedProvider == p;
              return ChoiceChip(
                avatar: Icon(p.icon, size: 18, color: isSelected ? Colors.black : p.brandColor),
                label: Text(p.displayName),
                selected: isSelected,
                selectedColor: p.brandColor,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedProvider = p;
                      if (_modelController.text.isEmpty ||
                          AiProvider.values.any((item) => item.suggestedModels.contains(_modelController.text))) {
                        _modelController.text = p.defaultModel;
                      }
                      _testResult = null;
                      _testSuccess = null;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 2. Credentials Configuration (if not offline)
          if (_selectedProvider != AiProvider.offline) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _selectedProvider.brandColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(_selectedProvider.icon, color: _selectedProvider.brandColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedProvider.displayName} Credentials',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // API Key Field
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: _selectedProvider == AiProvider.gemini ? 'AIzaSy...' : 'sk-...',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  if (_selectedProvider.keyDocumentationUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Get your key from: ${_selectedProvider.keyDocumentationUrl}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF00D4FF)),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Model Selection
                  TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model Name',
                      hintText: _selectedProvider.defaultModel,
                      prefixIcon: const Icon(Icons.memory_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  if (_selectedProvider.suggestedModels.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedProvider.suggestedModels.map((m) {
                        return ActionChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _modelController.text = m),
                        );
                      }).toList(),
                    ),
                  ],

                  if (_selectedProvider == AiProvider.custom) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _endpointController,
                      decoration: InputDecoration(
                        labelText: 'Custom Endpoint URL',
                        hintText: 'https://api.groq.com/openai/v1/chat/completions',
                        prefixIcon: const Icon(Icons.link_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.bolt, size: 14, color: Color(0xFFF55036)),
                          label: const Text('Use Groq Preset', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _endpointController.text = 'https://api.groq.com/openai/v1/chat/completions';
                              _modelController.text = 'llama-3.3-70b-versatile';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.computer, size: 14, color: Color(0xFF00D4FF)),
                          label: const Text('Local Ollama Preset', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _endpointController.text = 'http://localhost:11434/v1/chat/completions';
                              _modelController.text = 'llama3.2';
                            });
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Temperature Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Creativity (Temperature):', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      Text(_temperature.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB6FF3B))),
                    ],
                  ),
                  Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (val) => setState(() => _temperature = val),
                  ),

                  const SizedBox(height: 12),

                  // Test Connection & Save Controls
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: _isTesting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.network_check, size: 18),
                        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                        onPressed: _isTesting ? null : _testConnection,
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save Config'),
                        onPressed: _saveCredentials,
                      ),
                    ],
                  ),

                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _testSuccess == true
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testSuccess == true ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testSuccess == true ? Icons.check_circle : Icons.error_outline,
                            color: _testSuccess == true ? Colors.green : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _testSuccess == true ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB6FF3B).withValues(alpha: 0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined, color: Color(0xFFB6FF3B), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline Heuristic Mode Active',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All coaching advice is evaluated locally on this phone using deterministic exercise science algorithms, ISSN nutrition guidelines, and the Tanaka HR formula. Zero network requests are made.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Offline Setting'),
              onPressed: _saveCredentials,
            ),
          ],

          const SizedBox(height: 28),

          // 3. Privacy & Granular Consent Toggles
          Text('Privacy & Data Sharing Toggles', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Control what anonymized fitness data is included in the AI context prompt. You can inspect the exact payload at any time.',
            style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF)),
          ),
          const SizedBox(height: 12),

          consentAsync.when(
            data: (consent) => Material(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Profile & Fitness Goals'),
                    subtitle: const Text('Age, height, weight, experience level, goal (No name or email)'),
                    value: consent.shareProfile,
                    onChanged: (val) => ref
                        .read(coachConsentProvider.notifier)
                        .updateConsent(consent.copyWith(shareProfile: val)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Workout History'),
                    subtitle: const Text('Recent exercise names, completed sets, volume, and PRs'),
                    value: consent.shareWorkouts,
                    onChanged: (val) => ref
                        .read(coachConsentProvider.notifier)
                        .updateConsent(consent.copyWith(shareWorkouts: val)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Nutrition & Fuel Logs'),
                    subtitle: const Text('Daily calories, protein, carbs, fats, and water intake'),
                    value: consent.shareNutrition,
                    onChanged: (val) => ref
                        .read(coachConsentProvider.notifier)
                        .updateConsent(consent.copyWith(shareNutrition: val)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Health & Sleep Biomarkers'),
                    subtitle: const Text('Daily steps, resting heart rate, and sleep duration'),
                    value: consent.shareHealth,
                    onChanged: (val) => ref
                        .read(coachConsentProvider.notifier)
                        .updateConsent(consent.copyWith(shareHealth: val)),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Unable to load privacy toggles'),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            icon: const Icon(Icons.remove_red_eye_outlined),
            label: const Text('Inspect Assembled Payload Preview'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ConsentPreviewDialog(),
            ),
          ),

          const SizedBox(height: 28),

          // 4. Data Management & Key Clearing
          Text('Data & Security Management', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear API Key'),
                onPressed: _confirmClearKey,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset Chat History'),
                onPressed: _confirmResetChat,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 5. Medical Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2430),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFFA7B0BF), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'FitForge AI Coach offers educational suggestions based on general exercise and nutrition science. It does not provide medical diagnosis, treatment, or physical therapy. Consult a physician before beginning any strenuous regimen.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
