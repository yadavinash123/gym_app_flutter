import 'package:flutter/material.dart';

import '../../models/body_measurement.dart';

class WeightEntryDialog extends StatefulWidget {
  const WeightEntryDialog({
    super.key,
    required this.units, // 'Metric' or 'Imperial'
    this.initialWeightKg,
    this.initialWaistCm,
    this.existingEntry,
    required this.onSave,
  });

  final String units;
  final double? initialWeightKg;
  final double? initialWaistCm;
  final BodyMeasurementEntry? existingEntry;
  final ValueChanged<BodyMeasurementEntry> onSave;

  @override
  State<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<WeightEntryDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _waistController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String? _errorMessage;

  bool get isImperial => widget.units.toLowerCase() == 'imperial';
  String get weightUnit => isImperial ? 'lbs' : 'kg';
  String get lengthUnit => isImperial ? 'in' : 'cm';

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;

    final initialWeight = entry != null
        ? entry.weightInUnits(widget.units)
        : (widget.initialWeightKg != null
              ? (isImperial
                    ? widget.initialWeightKg! * 2.20462
                    : widget.initialWeightKg!)
              : null);

    final initialWaist = entry != null
        ? entry.waistInUnits(widget.units)
        : (widget.initialWaistCm != null
              ? (isImperial
                    ? widget.initialWaistCm! / 2.54
                    : widget.initialWaistCm!)
              : null);

    _weightController = TextEditingController(
      text: initialWeight != null ? initialWeight.toStringAsFixed(1) : '',
    );
    _waistController = TextEditingController(
      text: initialWaist != null ? initialWaist.toStringAsFixed(1) : '',
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');

    _selectedDate = entry != null
        ? DateTime.tryParse(entry.date) ?? DateTime.now()
        : DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final weightVal = double.tryParse(_weightController.text.trim());
    if (weightVal == null || weightVal <= 10.0 || weightVal >= 500.0) {
      setState(() {
        _errorMessage =
            'Please enter a valid weight between 10 and 500 $weightUnit';
      });
      return;
    }

    double? waistKg;
    if (_waistController.text.trim().isNotEmpty) {
      final waistVal = double.tryParse(_waistController.text.trim());
      if (waistVal == null || waistVal <= 0) {
        setState(() {
          _errorMessage = 'Please enter a valid waist circumference';
        });
        return;
      }
      waistKg = BodyMeasurementEntry.toCm(waistVal, widget.units);
    }

    final canonicalWeight = BodyMeasurementEntry.toKg(weightVal, widget.units);
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);

    final entry = BodyMeasurementEntry(
      id:
          widget.existingEntry?.id ??
          'weight_${DateTime.now().millisecondsSinceEpoch}',
      date: dateStr,
      weightKg: canonicalWeight,
      waistCm: waistKg,
      notes: _notesController.text.trim(),
      loggedAt: DateTime.now(),
    );

    widget.onSave(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF151B23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Measurement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFA7B0BF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Date Selector
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2430),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF00D4FF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate.toIso8601String().substring(0, 10),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Weight input
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Body Weight ($weightUnit)',
                  hintText: isImperial ? 'e.g. 175.5' : 'e.g. 78.5',
                  suffixText: weightUnit,
                ),
              ),
              const SizedBox(height: 14),
              // Waist input (optional)
              TextField(
                controller: _waistController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Waist Circumference (optional)',
                  hintText: isImperial ? 'e.g. 32.0' : 'e.g. 81.0',
                  suffixText: lengthUnit,
                ),
              ),
              const SizedBox(height: 14),
              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Morning weight, post-workout, etc.',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFF453A),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Save Record'),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
