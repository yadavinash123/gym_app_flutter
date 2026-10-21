import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../planning/initial_plan.dart';
import '../profile/profile.dart';
import '../profile/profile_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initial, this.initialStep = 0});
  final Profile? initial;
  final int initialStep;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final Map<String, TextEditingController> _fields = {};
  late String _gender,
      _units,
      _level,
      _goal,
      _environment,
      _equation,
      _time,
      _diet;
  String? _secondary;
  late int _days, _minutes, _meals, _step;
  late double _activity;
  late bool _limitations, _clinical;
  late Set<String> _equipment;
  late Set<int> _rests;
  late List<String> _schedule;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _step = widget.initialStep.clamp(0, 9);
    _gender = p?.gender ?? 'Prefer not to say';
    _units = p?.units ?? 'Metric';
    _level = p?.level ?? 'Beginner';
    _goal = p?.goal ?? 'Build muscle';
    _environment = p?.environment ?? 'Gym';
    _equation = p?.energyEquation ?? 'Skip estimate';
    _time = p?.trainingTime ?? 'Flexible';
    _diet = p?.diet ?? 'Vegetarian';
    _secondary = p?.secondaryGoal;
    _days = p?.days ?? 3;
    _minutes = p?.minutes ?? 30;
    _meals = p?.meals ?? 3;
    _activity = p?.activityFactor ?? 1.4;
    _limitations = p?.hasLimitations ?? false;
    _clinical = p?.clinicalNutrition ?? false;
    _equipment = {...?p?.equipment};
    _rests = {...?p?.restDays};
    _schedule = [...?p?.schedule];
    final imperial = _units == 'Imperial';
    String measure(double? value, double divisor) =>
        value == null ? '' : (value / divisor).toStringAsFixed(2);
    final values = {
      'name': p?.name ?? '',
      'age': p?.age?.toString() ?? '',
      'height': measure(p?.heightCm, imperial ? 2.54 : 1),
      'weight': measure(p?.weightKg, imperial ? 0.45359237 : 1),
      'waist': measure(p?.waistCm, imperial ? 2.54 : 1),
      'allergies': p?.allergies ?? '',
      'restrictions': p?.foodRestrictions ?? '',
      'cuisine': p?.cuisine ?? 'Indian',
      'budget': p?.budgetInr?.toString() ?? '',
      'limitations': p?.limitations ?? '',
      'avoided': p?.avoidedExercises ?? '',
      'calories': p?.calorieTarget?.toString() ?? '',
      'protein': p?.proteinTarget?.toString() ?? '',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  bool get _effectiveLimitations =>
      _limitations ||
      _text('limitations').isNotEmpty ||
      _text('avoided').isNotEmpty;

  String _text(String key) => _fields[key]!.text.trim();
  double? _number(String key) => double.tryParse(_text(key));
  Profile _draft() => Profile(
    name: _text('name'),
    gender: _gender,
    units: _units,
    level: _level,
    goal: _goal,
    days: _days,
    environment: _environment,
    secondaryGoal: _secondary,
    age: int.tryParse(_text('age')),
    heightCm: _number('height') == null
        ? null
        : _number('height')! * (_units == 'Imperial' ? 2.54 : 1),
    weightKg: _number('weight') == null
        ? null
        : _number('weight')! * (_units == 'Imperial' ? 0.45359237 : 1),
    waistCm: _number('waist') == null
        ? null
        : _number('waist')! * (_units == 'Imperial' ? 2.54 : 1),
    energyEquation: _equation,
    activityFactor: _activity,
    equipment: _equipment.toList(),
    minutes: _minutes,
    trainingTime: _time,
    restDays: _rests.toList()..sort(),
    diet: _diet,
    allergies: _text('allergies'),
    foodRestrictions: _text('restrictions'),
    cuisine: _text('cuisine'),
    budgetInr: _number('budget'),
    meals: _meals,
    hasLimitations: _effectiveLimitations,
    limitations: _text('limitations'),
    avoidedExercises: _text('avoided'),
    clinicalNutrition: _clinical,
    calorieTarget: _number('calories'),
    proteinTarget: _number('protein'),
    schedule: _schedule,
  );

  void _changeStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate()) return;
    if (_step == 6 && _days > 7 - _rests.length) {
      setState(
        () => _error =
            'Choose fewer training days or release a preferred rest day.',
      );
      return;
    }
    if (_step < 9) {
      _changeStep(_step + 1);
      return;
    }
    if (_schedule.where((s) => s != 'Recovery').length != _days) {
      setState(
        () => _error =
            'Set exactly $_days active days, or change your availability using Back.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).save(_draft());
      ref.invalidate(profileProvider);
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not save your profile. Check your entries and retry. Your previous saved profile is unchanged.';
          _saving = false;
        });
      }
    }
  }

  void _unitsChanged(String value) {
    if (value == _units) return;
    final toImperial = value == 'Imperial';
    for (final key in ['height', 'waist', 'weight']) {
      final number = _number(key);
      if (number == null) continue;
      final factor = key == 'weight' ? 0.45359237 : 2.54;
      _fields[key]!.text = (toImperial ? number / factor : number * factor)
          .toStringAsFixed(2);
    }
    _units = value;
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    int max = 500,
    double? min,
    double? upper,
    bool integer = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey(key),
      controller: _fields[key],
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        helperMaxLines: 3,
      ),
      keyboardType: min == null
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      maxLength: min == null ? max : null,
      onChanged: (value) {
        if (key == 'limitations' || key == 'avoided') _schedule = [];
      },
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return required ? 'Enter $label' : null;
        if (min != null) {
          final number = double.tryParse(text);
          if (number == null ||
              !number.isFinite ||
              number < min ||
              number > upper! ||
              (integer && int.tryParse(text) == null)) {
            return 'Enter ${integer ? 'a whole number' : 'a number'} from ${min.toStringAsFixed(1)} to ${upper!.toStringAsFixed(1)}';
          }
        }
        return null;
      },
    ),
  );

  Widget _choice(
    String label,
    List<String> values,
    String value,
    ValueChanged<String> onChange,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => onChange(v));
      },
    ),
  );

  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(value, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget _note(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      value,
      style: const TextStyle(color: Color(0xFFA7B0BF), height: 1.5),
    ),
  );

  List<Widget> _content() {
    switch (_step) {
      case 0:
        return [
          const Icon(Icons.fitness_center, size: 72, color: Color(0xFFB6FF3B)),
          const SizedBox(height: 24),
          _note(
            'Build strength. Track progress. Become better. Set up your starting plan with no account or AI connection.',
          ),
          _field('name', 'Name or nickname', required: true, max: 60),
          _note(
            'Your details are optional except your nickname. Nothing is saved until you confirm your plan.',
          ),
        ];
      case 1:
        return [
          _choice(
            'Gender preference',
            Profile.genders,
            _gender,
            (v) => _gender = v,
          ),
          _note(
            'Gender identity does not determine training ability. The optional energy-equation input is collected separately.',
          ),
        ];
      case 2:
        return [
          _choice('Training experience', Profile.levels, _level, (v) {
            _level = v;
            _schedule = [];
          }),
          _note(
            'Beginner: new to structured training. Intermediate: comfortable with common exercises. Advanced: experienced with structured programming.',
          ),
        ];
      case 3:
        final imperial = _units == 'Imperial';
        return [
          _choice(
            'Measurement units',
            Profile.unitOptions,
            _units,
            _unitsChanged,
          ),
          _field('age', 'Age (optional)', min: 13, upper: 100, integer: true),
          _field(
            'height',
            'Height (${imperial ? 'in' : 'cm'})',
            min: imperial ? 80 / 2.54 : 80,
            upper: imperial ? 250 / 2.54 : 250,
          ),
          _field(
            'weight',
            'Weight (${imperial ? 'lb' : 'kg'})',
            min: imperial ? 20 / 0.45359237 : 20,
            upper: imperial ? 400 / 0.45359237 : 400,
          ),
          _field(
            'waist',
            'Waist (${imperial ? 'in' : 'cm'}, optional)',
            min: imperial ? 20 / 2.54 : 20,
            upper: imperial ? 300 / 2.54 : 300,
          ),
          _choice(
            'Energy equation (optional)',
            Profile.equations,
            _equation,
            (v) => _equation = v,
          ),
          _note(
            'Mifflin–St Jeor uses age, height, weight and a sex-specific coefficient. Choose the coefficient only if appropriate for you, or skip it. Adult estimates may not apply during pregnancy or to medical conditions.',
          ),
          _heading('Activity multiplier: ${_activity.toStringAsFixed(1)}'),
          Slider(
            value: _activity,
            min: 1.2,
            max: 1.9,
            divisions: 7,
            label: _activity.toStringAsFixed(1),
            onChanged: (v) => setState(() => _activity = (v * 10).round() / 10),
          ),
          _note(
            '1.2 = mostly sedentary; 1.9 = very active. This is a rough, adjustable assumption about your whole day, not a sensor measurement.',
          ),
        ];
      case 4:
        return [
          _choice('Primary goal', Profile.goals, _goal, (v) {
            _goal = v;
            if (_secondary == v) _secondary = null;
            _schedule = [];
          }),
          _choice(
            'Secondary goal',
            ['None', ...Profile.goals.where((g) => g != _goal)],
            _secondary ?? 'None',
            (v) => _secondary = v == 'None' ? null : v,
          ),
          _note(
            'Your primary goal shapes the starting weekly outline. Your secondary goal is saved as a preference for future workout planning. No calorie deficit or surplus is imposed automatically.',
          ),
        ];
      case 5:
        return [
          _choice(
            'Training environment',
            Profile.environments,
            _environment,
            (v) => _environment = v,
          ),
          _heading('Available equipment'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Profile.equipmentOptions
                .map(
                  (e) => FilterChip(
                    label: Text(e),
                    selected: _equipment.contains(e),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _equipment.add(e);
                      } else {
                        _equipment.remove(e);
                      }
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _note(
            'Leave equipment unselected for bodyweight-only training. Specific exercise selection arrives with the exercise library.',
          ),
        ];
      case 6:
        return [
          _heading('Training days per week: $_days'),
          Slider(
            value: _days.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_days days',
            onChanged: (v) => setState(() {
              _days = v.round();
              _schedule = [];
            }),
          ),
          _heading('Minutes per session: $_minutes'),
          Slider(
            value: _minutes.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            label: '$_minutes minutes',
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          _choice(
            'Preferred training time',
            Profile.times,
            _time,
            (v) => _time = v,
          ),
          _heading('Preferred rest days'),
          Wrap(
            spacing: 8,
            children: List.generate(
              7,
              (i) => FilterChip(
                label: Text(Profile.weekdays[i]),
                selected: _rests.contains(i),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _rests.add(i);
                  } else {
                    _rests.remove(i);
                  }
                  _schedule = [];
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _note(
            'Your chosen rest days stay free. Changing experience, goals, availability or limitations regenerates the outline for you to review before saving.',
          ),
        ];
      case 7:
        return [
          _choice('Food preference', Profile.diets, _diet, (v) => _diet = v),
          _field('allergies', 'Food allergies (optional)'),
          _field('restrictions', 'Religious or personal food restrictions'),
          _field('cuisine', 'Preferred cuisine', max: 100),
          _field(
            'budget',
            'Daily food budget (₹, optional)',
            min: 0,
            upper: 100000,
          ),
          _heading('Meals per day: $_meals'),
          Slider(
            value: _meals.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '$_meals meals',
            onChanged: (v) => setState(() => _meals = v.round()),
          ),
          _note(
            'These preferences are saved for the nutrition phase. No meals or current market prices are generated here.',
          ),
        ];
      case 8:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I have pain, an injury, or a movement restriction',
            ),
            value: _limitations,
            onChanged: (v) => setState(() {
              _limitations = v;
              _schedule = [];
            }),
          ),
          _field(
            'limitations',
            'Injuries, pain or mobility restrictions (optional)',
          ),
          _field('avoided', 'Exercises to avoid (optional)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Use personal nutrition guidance instead of estimates',
            ),
            subtitle: const Text(
              'For example, pregnancy or a relevant medical restriction.',
            ),
            value: _clinical,
            onChanged: (v) => setState(() => _clinical = v),
          ),
          _note(
            'The app cannot assess injuries or medical conditions. If you report limitations, strength and cardio suggestions are withheld. The outline marks time for reviewing suitable movement with a qualified professional; it is not exercise clearance.',
          ),
          _note(
            'Providing restriction notes or exercises to avoid also withholds strength and cardio suggestions. Clear the notes and switch only when those restrictions no longer apply.',
          ),
        ];
      default:
        return _preview();
    }
  }

  List<Widget> _preview() {
    final p = _draft();
    if (_schedule.isEmpty) _schedule = InitialPlan.generate(p);
    final estimate = NutritionEstimate.forProfile(p);
    return [
      _note(
        '$_days planned days • $_minutes minutes • $_environment\nReview and edit before saving. This is a weekly outline; exercise instructions and session logging arrive in later phases.',
      ),
      if (p.hasLimitations)
        _note(
          'Limitations noted: active slots are reserved for a professional movement review. Do not treat the Mobility label as a prescribed routine.',
        ),
      ...List.generate(
        7,
        (i) => _choice(
          Profile.weekdays[i],
          _rests.contains(i)
              ? ['Recovery']
              : p.hasLimitations
              ? ['Recovery', 'Mobility']
              : Profile.sessionKinds,
          _schedule[i],
          (v) => _schedule[i] = v,
        ),
      ),
      OutlinedButton(
        onPressed: () =>
            setState(() => _schedule = InitialPlan.generate(_draft())),
        child: const Text('Reset weekly outline'),
      ),
      const SizedBox(height: 24),
      _heading('Nutrition starting point'),
      if (estimate.maintenanceKcal != null)
        _note(
          'Estimated maintenance: ${estimate.maintenanceKcal!.round()} kcal/day\nResting estimate: ${estimate.restingKcal!.round()} kcal/day × ${_activity.toStringAsFixed(1)} activity multiplier. This is not a weight-loss prescription.',
        )
      else
        _note(
          'Energy estimate unavailable. Enter adult age, height, weight and an appropriate equation coefficient, or use a personal target. Estimates are disabled for under-18s and when personal nutrition guidance is selected.',
        ),
      if (estimate.proteinLow != null)
        _note(
          'General protein range for healthy exercising adults: ${estimate.proteinLow!.round()}–${estimate.proteinHigh!.round()} g/day (1.4–2.0 g/kg). Individual requirements vary.',
        ),
      _field(
        'calories',
        'Personal calorie target (kcal/day, optional)',
        min: 1,
        upper: 10000,
        hint: 'Blank uses estimated maintenance when available.',
      ),
      _field(
        'protein',
        'Personal protein target (g/day, optional)',
        min: 1,
        upper: 500,
        hint: 'Blank keeps the estimated range, without choosing a single target.',
      ),
      _note(
        'Personal targets are your entries, not app recommendations. Seek appropriate professional advice for individual needs.',
      ),
      if (estimate.bmi != null)
        ExpansionTile(
          title: const Text('Optional BMI context'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Estimated BMI: ${estimate.bmi!.toStringAsFixed(1)}. BMI alone does not measure fitness, muscle mass, or health.',
              ),
            ),
          ],
        ),
      ExpansionTile(
        title: const Text('Calculation references'),
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: SelectableText(
              'Mifflin et al. (1990), DOI: 10.1093/ajcn/51.2.241.\nJäger et al. (2017), DOI: 10.1186/s12970-017-0177-8.\nThese estimates are educational, based on adult populations, and may not fit your circumstances.',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Make it yours.',
      'Your identity.',
      'Your starting point.',
      'Know your baseline.',
      'Choose your direction.',
      'Your training space.',
      'Make room for progress.',
      'Food that fits you.',
      'Move with care.',
      'Your starting plan.',
    ];
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? 'FITFORGE' : 'EDIT PROFILE'),
          actions: [
            if (widget.initial == null)
              TextButton(
                onPressed: _saving ? null : () => context.go('/home'),
                child: const Text('Explore'),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: AbsorbPointer(
                absorbing: _saving,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'YOUR STARTING LINE  /  ${_step + 1} OF 10',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: (_step + 1) / 10),
                        const SizedBox(height: 24),
                        Text(
                          titles[_step],
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 24),
                        ..._content(),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _saving ? null : _next,
                          child: Text(
                            _saving
                                ? 'Saving…'
                                : _step == 9
                                ? 'Save profile and plan'
                                : 'Continue',
                          ),
                        ),
                        if (_step > 0)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => _changeStep(_step - 1),
                            child: const Text('Back'),
                          ),
                        if (widget.initial != null)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => context.go('/settings'),
                            child: const Text('Cancel changes'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
