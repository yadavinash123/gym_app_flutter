import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/profile_repository.dart';
import '../data/health_repository.dart';
import '../data/step_tracking_service.dart';
import '../models/daily_health_summary.dart';
import '../models/health_metric_type.dart';
import '../models/health_source.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/health_reference_dialog.dart';
import '../widgets/heart_rate_zone_chart.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key, this.initialDate});

  final String? initialDate;

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  late DateTime _selectedDate;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  String get _dateIso =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.onPrimary,
            surface: const Color(0xFF151B23),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dailyHealthSummaryProvider(_dateIso));
    final auditLogs = ref.watch(healthAuditLogsProvider).value ?? [];
    final profile = ref.watch(profileProvider).value;
    final age = profile?.age ?? 28;
    final stepState = ref.watch(stepTrackingStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Health'),
        actions: [
          IconButton(
            tooltip: 'Scientific references & Privacy',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const HealthReferenceDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Permissions & Privacy',
            icon: const Icon(Icons.security_outlined),
            onPressed: () => context.push('/health/permissions'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Navigation Bar
            _buildDateBar(),
            const SizedBox(height: 16),

            // Hero Daily Activity & Manual Log Card
            _buildDailyActivityCard(summary, stepState),
            const SizedBox(height: 20),

            // Metric Cards Grid
            _buildMetricGrid(summary),
            const SizedBox(height: 20),

            // Sleep Stages Breakdown Card
            if (summary.sleepDurationMinutes != null &&
                summary.sleepDurationMinutes! > 0) ...[
              _buildSleepStagesCard(summary),
              const SizedBox(height: 20),
            ],

            // Heart Rate Training Zones Card
            HeartRateZoneChart(
              age: age,
              restingBpm: summary.restingHeartRateBpm,
              source: summary.restingHeartRateSource,
            ),
            const SizedBox(height: 20),

            // Sync Audit Trail Card
            _buildAuditTrailCard(auditLogs),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBar() {
    final isToday =
        _dateIso ==
        '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousDay,
            tooltip: 'Previous day',
          ),
          Flexible(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isToday ? 'Today ($_dateIso)' : _dateIso,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextDay,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard(
    DailyHealthSummary summary,
    StepTrackingState? stepState,
  ) {
    final isWalking = stepState?.isWalking ?? false;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Activity & Manual Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      summary.notes != null && summary.notes!.isNotEmpty
                          ? 'Latest: ${summary.notes}'
                          : 'Record your steps, calories, heart rate, and sleep manually',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7B0BF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isWalking
                  ? primaryColor.withValues(alpha: 0.15)
                  : const Color(0xFF1C2430),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isWalking
                    ? primaryColor.withValues(alpha: 0.4)
                    : const Color(0xFF283241),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isWalking
                      ? Icons.directions_walk_rounded
                      : Icons.sensors_rounded,
                  size: 16,
                  color: isWalking
                      ? primaryColor
                      : const Color(0xFF00D4FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isWalking
                        ? '🚶 Active walking detected · Hardware counter live'
                        : 'Manual entry ready · Record and update metrics below',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isWalking
                          ? primaryColor
                          : const Color(0xFFA7B0BF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Main action button: Log Activity Record (full width, height 48, matched)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => context.push('/health/log?date=$_dateIso'),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Log Daily Activity Record',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick metric shortcuts:
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickMetricPill(
                  label: '+ Steps',
                  icon: Icons.directions_walk,
                  metricName: 'steps',
                ),
                const SizedBox(width: 8),
                _buildQuickMetricPill(
                  label: '+ Heart Rate',
                  icon: Icons.favorite_outline,
                  metricName: 'restingHeartRate',
                ),
                const SizedBox(width: 8),
                _buildQuickMetricPill(
                  label: '+ Sleep',
                  icon: Icons.bedtime_outlined,
                  metricName: 'sleep',
                ),
                const SizedBox(width: 8),
                _buildQuickMetricPill(
                  label: '+ Calories',
                  icon: Icons.local_fire_department_outlined,
                  metricName: 'activeEnergy',
                ),
                const SizedBox(width: 8),
                _buildQuickMetricPill(
                  label: '+ Distance',
                  icon: Icons.straighten,
                  metricName: 'distance',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricPill({
    required String label,
    required IconData icon,
    required String metricName,
  }) {
    return InkWell(
      onTap: () => context.push('/health/log?date=$_dateIso&metric=$metricName'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2430),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF283241)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFA7B0BF)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(DailyHealthSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HealthMetricCard(
                metric: HealthMetricType.steps,
                displayValue: '${summary.steps}',
                unit: 'steps',
                source: summary.stepSource,
                target: '10,000',
                progress: summary.stepProgress(10000),
                subtitle: '${summary.distanceKm.toStringAsFixed(2)} km walked',
                onTap: () => context.push('/health/log?date=$_dateIso'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HealthMetricCard(
                metric: HealthMetricType.activeEnergy,
                displayValue: summary.activeKcal.toStringAsFixed(0),
                unit: 'kcal',
                source: summary.activeKcalSource,
                target: '500 kcal',
                progress: (summary.activeKcal / 500).clamp(0.0, 1.0),
                subtitle: summary.activeKcal > 0
                    ? '${summary.activeKcal.toStringAsFixed(0)} kcal burned'
                    : 'Active burn goal',
                onTap: () => context.push('/health/log?date=$_dateIso'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HealthMetricCard(
                metric: HealthMetricType.restingHeartRate,
                displayValue: summary.restingHeartRateBpm != null
                    ? '${summary.restingHeartRateBpm}'
                    : '--',
                unit: 'bpm',
                source: summary.restingHeartRateSource ?? HealthSource.manual,
                target: '60-80 bpm',
                progress: summary.restingHeartRateBpm != null
                    ? (summary.restingHeartRateBpm! <= 80
                        ? 1.0
                        : ((100 - summary.restingHeartRateBpm!) / 100)
                            .clamp(0.1, 0.9))
                    : 0.0,
                subtitle: summary.restingHeartRateBpm != null
                    ? 'Optimal resting zone'
                    : 'Tap to log pulse',
                onTap: () => context.push('/health/log?date=$_dateIso'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HealthMetricCard(
                metric: HealthMetricType.sleep,
                displayValue: summary.sleepDurationMinutes != null
                    ? (summary.sleepDurationMinutes! / 60).toStringAsFixed(1)
                    : '--',
                unit: 'hrs',
                source: summary.sleepSource ?? HealthSource.manual,
                target: '8.0 hrs',
                progress: summary.sleepDurationMinutes != null
                    ? (summary.sleepDurationMinutes! / 480).clamp(0.0, 1.0)
                    : 0.0,
                subtitle: summary.sleepFormatted,
                onTap: () => context.push('/health/log?date=$_dateIso'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepStagesCard(DailyHealthSummary summary) {
    final deep = summary.deepSleepMinutes ?? 0;
    final rem = summary.remSleepMinutes ?? 0;
    final light = summary.lightSleepMinutes ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: Color(0xFFA78BFA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sleep Architecture & Stages',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stageChip(
                'Deep Sleep',
                '${deep ~/ 60}h ${deep % 60}m',
                const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              _stageChip(
                'REM Sleep',
                '${rem ~/ 60}h ${rem % 60}m',
                const Color(0xFFA78BFA),
              ),
              const SizedBox(width: 8),
              _stageChip(
                'Light Sleep',
                '${light ~/ 60}h ${light % 60}m',
                const Color(0xFF00D4FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageChip(String label, String duration, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                duration,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailCard(List auditLogs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Color(0xFFA7B0BF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Daily Activity Entry History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (auditLogs.isEmpty)
            const Text(
              'No manual logs recorded yet. Tap "Log Daily Activity Record" above to pass your entry.',
              style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
            )
          else
            ...auditLogs.take(5).map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      log.isSuccess ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: log.isSuccess
                          ? Theme.of(context).colorScheme.primary
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.details,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${log.source.shortBadge} • ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFA7B0BF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
