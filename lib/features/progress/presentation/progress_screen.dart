import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../workouts/models/workout_session.dart';
import '../data/progress_repository.dart';
import '../models/habit_streak.dart';
import 'widgets/interactive_line_chart.dart';
import 'widgets/milestone_grid.dart';
import 'widgets/muscle_recovery_card.dart';
import 'widgets/streak_tracker_card.dart';
import 'widgets/volume_bar_chart.dart';
import 'widgets/weight_entry_dialog.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _chartDaysFilter = 30; // 7, 30, 90, 365
  String? _selectedPrExerciseId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(progressDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PROGRESS & ANALYTICS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Log Measurement',
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFFB6FF3B),
            ),
            onPressed: () =>
                _openWeightEntryDialog(dashboardAsync.asData?.value),
          ),
          IconButton(
            tooltip: 'Reminders & Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/progress/reminders'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          indicatorColor: const Color(0xFFB6FF3B),
          indicatorWeight: 3,
          labelColor: const Color(0xFFB6FF3B),
          unselectedLabelColor: const Color(0xFFA7B0BF),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'CHARTS'),
            Tab(text: 'RECOVERY'),
            Tab(text: 'BADGES'),
          ],
        ),
      ),
      body: dashboardAsync.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(data),
            _buildChartsTab(data),
            _buildRecoveryTab(data),
            _buildMilestonesTab(data),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 12),
              Text(
                'Unable to load progress data: $err',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(progressDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 1: Overview
  // ===========================================================================

  Widget _buildOverviewTab(ProgressDashboardData data) {
    final units = data.profile?.units ?? 'Metric';
    final isImperial = units.toLowerCase() == 'imperial';
    final weightUnit = isImperial ? 'lbs' : 'kg';

    final measurements = data.measurements;
    final latestWeightKg = measurements.isNotEmpty
        ? measurements.last.weightKg
        : data.profile?.weightKg;

    final latestWeightDisplay = latestWeightKg != null
        ? (isImperial ? latestWeightKg * 2.20462 : latestWeightKg)
              .toStringAsFixed(1)
        : '--';

    // Calculate weight change compared to initial
    String? weightChangeStr;
    if (measurements.length >= 2) {
      final initial = measurements.first.weightKg;
      final current = measurements.last.weightKg;
      final diffKg = current - initial;
      final diffDisplay = isImperial ? diffKg * 2.20462 : diffKg;
      final sign = diffDisplay > 0 ? '+' : '';
      weightChangeStr =
          '$sign${diffDisplay.toStringAsFixed(1)} $weightUnit overall';
    }

    final workoutStreak =
        data.streaks[HabitType.workouts] ??
        const HabitStreak(
          type: HabitType.workouts,
          currentStreak: 0,
          longestStreak: 0,
        );
    final nutritionStreak = data.streaks[HabitType.nutrition];
    final hydrationStreak = data.streaks[HabitType.hydration];

    // Weekly volume calculation
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentSessions = data.sessions
        .where((s) => s.completedAt.isAfter(sevenDaysAgo))
        .toList();
    final weeklyVolume = recentSessions.fold(
      0.0,
      (sum, s) => sum + s.totalVolumeKg,
    );
    final weeklySets = recentSessions.fold(
      0,
      (sum, s) => sum + s.totalCompletedSets,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Weight Summary Card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151B23),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'BODY WEIGHT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFFA7B0BF),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openWeightEntryDialog(data),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6FF3B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB6FF3B).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Color(0xFFB6FF3B)),
                          SizedBox(width: 4),
                          Text(
                            'Log Weight',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB6FF3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    latestWeightDisplay,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    weightUnit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB6FF3B),
                    ),
                  ),
                  if (weightChangeStr != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weightChangeStr,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00D4FF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (measurements.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Last logged on ${measurements.last.date}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA7B0BF),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 2. Habit Streaks Card
        StreakTrackerCard(
          workoutStreak: workoutStreak,
          nutritionStreak: nutritionStreak,
          hydrationStreak: hydrationStreak,
        ),
        const SizedBox(height: 16),
        // 3. System Recovery Quick Card
        MuscleRecoveryCard(readiness: data.readiness),
        const SizedBox(height: 16),
        // 4. 7-Day Training Volume Summary
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151B23),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '7-DAY TRAINING LOAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFA7B0BF),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      label: 'Volume Lifted',
                      value: weeklyVolume >= 1000
                          ? '${(weeklyVolume / 1000).toStringAsFixed(1)}k'
                          : weeklyVolume.toStringAsFixed(0),
                      unit: 'kg',
                      color: const Color(0xFF00D4FF),
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      label: 'Sessions',
                      value: '${recentSessions.length}',
                      unit: 'completed',
                      color: const Color(0xFFB6FF3B),
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      label: 'Total Sets',
                      value: '$weeklySets',
                      unit: 'sets',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 5. Recent Milestones Preview
        _buildMilestonePreviewCard(data.milestones),
      ],
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA7B0BF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA7B0BF)),
        ),
      ],
    );
  }

  Widget _buildMilestonePreviewCard(List<dynamic> milestones) {
    final unlocked = milestones.where((m) => m.isUnlocked).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACHIEVEMENTS UNLOCKED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFA7B0BF),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(3),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB6FF3B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (unlocked.isEmpty)
            const Text(
              'No milestones unlocked yet. Complete workouts, log nutrition, and maintain streaks to earn badges!',
              style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlocked.take(4).map((badge) {
                return Chip(
                  avatar: Icon(
                    badge.iconData,
                    size: 16,
                    color: const Color(0xFFB6FF3B),
                  ),
                  label: Text(
                    badge.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1C2430),
                  side: BorderSide(
                    color: const Color(0xFFB6FF3B).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 2: Charts & Trends
  // ===========================================================================

  Widget _buildChartsTab(ProgressDashboardData data) {
    final units = data.profile?.units ?? 'Metric';
    final isImperial = units.toLowerCase() == 'imperial';
    final weightUnit = isImperial ? 'lbs' : 'kg';

    // Filter date bounds
    final now = DateTime.now();
    final filterThreshold = now.subtract(Duration(days: _chartDaysFilter));

    // 1. Weight data points
    final filteredMeasurements = data.measurements.where((m) {
      if (_chartDaysFilter == 365) return true;
      final dt = DateTime.tryParse(m.date);
      return dt != null && dt.isAfter(filterThreshold);
    }).toList();

    final weightPoints = filteredMeasurements.map((m) {
      final dt = DateTime.tryParse(m.date) ?? DateTime.now();
      final val = m.weightInUnits(units);
      return ChartDataPoint(date: dt, value: val);
    }).toList();

    // 2. Weekly Volume data
    final volumeBars = _computeWeeklyVolumeBars(
      data.sessions,
      _chartDaysFilter,
    );

    // 3. Compound lift 1RM list
    final prExercises = data.prs.map((pr) => pr.exerciseId).toSet().toList();
    if (_selectedPrExerciseId == null && prExercises.isNotEmpty) {
      _selectedPrExerciseId = prExercises.first;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Time filter chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('7 Days', 7),
            _buildFilterChip('30 Days', 30),
            _buildFilterChip('90 Days', 90),
            _buildFilterChip('All Time', 365),
          ],
        ),
        const SizedBox(height: 20),
        // Chart 1: Body Weight Trend
        const Text(
          'BODY WEIGHT TREND',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFFA7B0BF),
          ),
        ),
        const SizedBox(height: 10),
        InteractiveLineChart(
          points: weightPoints,
          lineColor: const Color(0xFFB6FF3B),
          unit: weightUnit,
          emptyMessage:
              'Log your body weight to view progress curves over time',
        ),
        const SizedBox(height: 24),
        // Chart 2: Weekly Volume Bar Chart
        const Text(
          'TRAINING VOLUME TONNAGE (KG)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFFA7B0BF),
          ),
        ),
        const SizedBox(height: 10),
        VolumeBarChart(bars: volumeBars, primaryColor: const Color(0xFF00D4FF)),
        const SizedBox(height: 24),
        // Chart 3: Personal Records / Strength 1RM Trends
        if (data.prs.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PERSONAL RECORD STRENGTH (1RM)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFA7B0BF),
                ),
              ),
              if (prExercises.length > 1)
                DropdownButton<String>(
                  value: _selectedPrExerciseId,
                  dropdownColor: const Color(0xFF151B23),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB6FF3B),
                  ),
                  items: prExercises.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(id.replaceAll('_', ' ').toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedPrExerciseId = val),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStrengthTrendCard(data, _selectedPrExerciseId),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final isSelected = _chartDaysFilter == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _chartDaysFilter = days),
      selectedColor: const Color(0xFFB6FF3B),
      backgroundColor: const Color(0xFF151B23),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? const Color(0xFF0B0F14) : const Color(0xFFA7B0BF),
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFFB6FF3B)
            : Colors.white.withOpacity(0.08),
      ),
    );
  }

  List<VolumeBarData> _computeWeeklyVolumeBars(
    List<WorkoutSession> sessions,
    int daysLimit,
  ) {
    if (sessions.isEmpty) return [];

    final now = DateTime.now();
    final weekCount = (daysLimit / 7).ceil().clamp(4, 12);
    final bars = <VolumeBarData>[];

    for (int i = weekCount - 1; i >= 0; i--) {
      final start = now.subtract(Duration(days: (i + 1) * 7));
      final end = now.subtract(Duration(days: i * 7));

      final weekSessions = sessions.where((s) {
        return s.completedAt.isAfter(start) && s.completedAt.isBefore(end);
      }).toList();

      final volume = weekSessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
      final sets = weekSessions.fold(0, (sum, s) => sum + s.totalCompletedSets);

      final label = i == 0 ? 'This Wk' : '${end.month}/${end.day}';

      bars.add(
        VolumeBarData(
          label: label,
          volumeKg: volume,
          setCount: sets,
          sessionCount: weekSessions.length,
        ),
      );
    }

    return bars;
  }

  Widget _buildStrengthTrendCard(
    ProgressDashboardData data,
    String? exerciseId,
  ) {
    if (exerciseId == null) return const SizedBox.shrink();

    // Find PR record
    final pr = data.prs.firstWhere(
      (p) => p.exerciseId == exerciseId,
      orElse: () => data.prs.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pr.exerciseId.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6FF3B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PERSONAL RECORD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB6FF3B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                label: 'Est. 1RM',
                value: pr.estimatedOneRepMaxKg.toStringAsFixed(1),
                unit: 'kg',
                color: const Color(0xFFB6FF3B),
              ),
              _buildStatColumn(
                label: 'Max Weight',
                value: pr.maxWeightKg.toStringAsFixed(1),
                unit: 'kg',
                color: const Color(0xFF00D4FF),
              ),
              _buildStatColumn(
                label: 'Reps at Max',
                value: '${pr.maxRepsAtMaxWeight}',
                unit: 'reps',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Recovery
  // ===========================================================================

  Widget _buildRecoveryTab(ProgressDashboardData data) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MuscleRecoveryCard(readiness: data.readiness),
        const SizedBox(height: 20),
        // Science notes card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151B23),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF00D4FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Supercompensation & Recovery Curve',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'After resistance stimulus, muscle protein breakdown exceeds synthesis for the first 24 hours. Full tissue remodeling and glycogen replenishment typically require 48–72 hours depending on training volume. Adequate sleep (>7.5h) and consistent protein intake are critical to accelerate the supercompensation curve.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA7B0BF),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Tab 4: Milestones
  // ===========================================================================

  Widget _buildMilestonesTab(ProgressDashboardData data) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [MilestoneGrid(milestones: data.milestones)],
    );
  }

  void _openWeightEntryDialog(ProgressDashboardData? data) {
    final units = data?.profile?.units ?? 'Metric';
    final latestWeight = data?.measurements.isNotEmpty == true
        ? data!.measurements.last.weightKg
        : data?.profile?.weightKg;
    final latestWaist = data?.measurements.isNotEmpty == true
        ? data!.measurements.last.waistCm
        : data?.profile?.waistCm;

    showDialog<void>(
      context: context,
      builder: (context) {
        return WeightEntryDialog(
          units: units,
          initialWeightKg: latestWeight,
          initialWaistCm: latestWaist,
          onSave: (entry) async {
            final repo = ref.read(progressRepositoryProvider);
            await repo.addMeasurement(entry);
            ref.invalidate(progressDashboardProvider);
            ref.invalidate(bodyMeasurementsProvider);
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement recorded successfully'),
                  backgroundColor: Color(0xFF151B23),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }
}
