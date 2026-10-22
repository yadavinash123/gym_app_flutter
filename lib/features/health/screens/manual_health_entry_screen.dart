import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/health_repository.dart';
import '../models/health_metric_type.dart';

class ManualHealthEntryScreen extends ConsumerStatefulWidget {
  const ManualHealthEntryScreen({super.key, required this.date});

  final String date;

  @override
  ConsumerState<ManualHealthEntryScreen> createState() =>
      _ManualHealthEntryScreenState();
}

class _ManualHealthEntryScreenState extends ConsumerState<ManualHealthEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  HealthMetricType _selectedMetric = HealthMetricType.steps;
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMetricChanged(HealthMetricType metric) {
    setState(() {
      _selectedMetric = metric;
      _valueController.clear();
    });
  }

  String? _validateValue(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter a value';
    }
    final val = double.tryParse(text.trim());
    if (val == null || val < 0) {
      return 'Please enter a valid positive number';
    }

    switch (_selectedMetric) {
      case HealthMetricType.steps:
        if (val > 100000) return 'Steps cannot exceed 100,000/day';
        break;
      case HealthMetricType.distance:
        if (val > 100) return 'Distance cannot exceed 100 km/day';
        break;
      case HealthMetricType.activeEnergy:
        if (val > 10000) return 'Active calories cannot exceed 10,000 kcal';
        break;
      case HealthMetricType.restingHeartRate:
        if (val < 30 || val > 220) return 'Resting HR must be between 30 and 220 bpm';
        break;
      case HealthMetricType.sleep:
        if (val > 1440) return 'Sleep cannot exceed 24 hours (1440 minutes)';
        break;
      case HealthMetricType.workouts:
        if (val > 20) return 'Session count cannot exceed 20';
        break;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final value = double.parse(_valueController.text.trim());
      await ref.read(dailyHealthSummariesProvider.notifier).logManual(
            date: widget.date,
            metric: _selectedMetric,
            value: value,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded ${_selectedMetric.label}: $value ${_selectedMetric.unitLabel} (Manual Entry)',
            ),
            backgroundColor: const Color(0xFFB6FF3B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Health Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151B23),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1C2430)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: Color(0xFFB6FF3B), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Source Attribution: Manual Entry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target Date: ${widget.date} • Saved locally on device',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA7B0BF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Metric',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HealthMetricType.values.map((metric) {
                  final isSelected = metric == _selectedMetric;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          metric.icon,
                          size: 16,
                          color: isSelected ? Colors.black : metric.color,
                        ),
                        const SizedBox(width: 6),
                        Text(metric.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onMetricChanged(metric),
                    selectedColor: const Color(0xFFB6FF3B),
                    backgroundColor: const Color(0xFF151B23),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'Value (${_selectedMetric == HealthMetricType.sleep ? 'minutes, e.g. 480 for 8h' : _selectedMetric.unitLabel})',
                  hintText: _selectedMetric == HealthMetricType.steps
                      ? 'e.g. 8500'
                      : _selectedMetric == HealthMetricType.restingHeartRate
                          ? 'e.g. 62'
                          : _selectedMetric == HealthMetricType.sleep
                              ? 'e.g. 450 (7.5 hours)'
                              : 'e.g. 350',
                  prefixIcon: Icon(_selectedMetric.icon, color: _selectedMetric.color),
                  filled: true,
                  fillColor: const Color(0xFF151B23),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1C2430)),
                  ),
                ),
                validator: _validateValue,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Optional Notes / Context',
                  hintText: 'e.g. Tracked via gym treadmill or morning pulse',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  filled: true,
                  fillColor: const Color(0xFF151B23),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1C2430)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB6FF3B),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const Icon(Icons.hourglass_top, size: 20)
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? 'Saving...' : 'Record Metric',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
