import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/data/health_repository.dart';
import '../../health/models/daily_health_summary.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/models/meal_log.dart';
import '../../profile/profile_repository.dart';
import '../../workouts/data/workout_repository.dart';
import '../../workouts/models/workout_session.dart';
import '../data/coach_repository.dart';
import '../models/coach_persona.dart';

class ConsentPreviewDialog extends ConsumerWidget {
  const ConsentPreviewDialog({super.key, this.persona = CoachPersona.scientific});

  final CoachPersona persona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(coachConsentProvider);
    final repo = ref.watch(coachRepositoryProvider);

    return Dialog(
      backgroundColor: const Color(0xFF151B23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Header
              Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Prompt & Privacy Inspection',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2430),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF00D4FF), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Zero-PII Guarantee: Your name, email, and identity are NEVER included. Only anonymized fitness metrics are assembled.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFA7B0BF), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data Categories Included:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      consentAsync.when(
                        data: (consent) => Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Profile & Goals', style: TextStyle(fontSize: 11)),
                              selected: consent.shareProfile,
                              onSelected: (val) => ref
                                  .read(coachConsentProvider.notifier)
                                  .updateConsent(consent.copyWith(shareProfile: val)),
                            ),
                            FilterChip(
                              label: const Text('Workouts', style: TextStyle(fontSize: 11)),
                              selected: consent.shareWorkouts,
                              onSelected: (val) => ref
                                  .read(coachConsentProvider.notifier)
                                  .updateConsent(consent.copyWith(shareWorkouts: val)),
                            ),
                            FilterChip(
                              label: const Text('Nutrition', style: TextStyle(fontSize: 11)),
                              selected: consent.shareNutrition,
                              onSelected: (val) => ref
                                  .read(coachConsentProvider.notifier)
                                  .updateConsent(consent.copyWith(shareNutrition: val)),
                            ),
                            FilterChip(
                              label: const Text('Health & Sleep', style: TextStyle(fontSize: 11)),
                              selected: consent.shareHealth,
                              onSelected: (val) => ref
                                  .read(coachConsentProvider.notifier)
                                  .updateConsent(consent.copyWith(shareHealth: val)),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (_, _) => const Text('Could not load privacy settings'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Raw System Prompt & Payload Preview:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 200,
                        child: FutureBuilder<String>(
                          future: _generatePayloadPreview(ref, repo, persona),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final previewText = snapshot.data ?? 'No preview available';
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0F14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  previewText,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Color(0xFFB6FF3B),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Pinned Bottom Actions
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Payload', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final text = await _generatePayloadPreview(ref, repo, persona);
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payload copied to clipboard')),
                        );
                      }
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _generatePayloadPreview(
    WidgetRef ref,
    CoachRepository repo,
    CoachPersona persona,
  ) async {
    final consent = await ref.read(coachConsentProvider.future);
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

    return repo.buildFullSystemPrompt(
      persona: persona,
      consent: consent,
      profile: profile,
      todayNutrition: todayLog,
      todayHealth: todayHealth,
      recentWorkouts: sessions,
    );
  }
}
