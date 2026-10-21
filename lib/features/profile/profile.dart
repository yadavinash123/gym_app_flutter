/// Canonical measurements are metric; units only control input and display.
/// Version 1 documents are migrated in memory and upgraded on an explicit save.
class Profile {
  const Profile({
    required this.name,
    required this.level,
    required this.goal,
    required this.days,
    required this.environment,
    this.gender = 'Prefer not to say',
    this.units = 'Metric',
    this.age,
    this.heightCm,
    this.weightKg,
    this.waistCm,
    this.energyEquation = 'Skip estimate',
    this.activityFactor = 1.4,
    this.secondaryGoal,
    this.equipment = const [],
    this.minutes = 30,
    this.trainingTime = 'Flexible',
    this.restDays = const [],
    this.diet = 'Vegetarian',
    this.allergies = '',
    this.foodRestrictions = '',
    this.cuisine = 'Indian',
    this.budgetInr,
    this.meals = 3,
    this.hasLimitations = false,
    this.limitations = '',
    this.avoidedExercises = '',
    this.clinicalNutrition = false,
    this.calorieTarget,
    this.proteinTarget,
    this.schedule = const [],
  });
  final String name, level, goal, environment;
  final int days;
  final String gender;
  final String units;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final String energyEquation;
  final double activityFactor;
  final String? secondaryGoal;
  final List<String> equipment;
  final int minutes;
  final String trainingTime;
  final List<int> restDays;
  final String diet;
  final String allergies;
  final String foodRestrictions;
  final String cuisine;
  final double? budgetInr;
  final int meals;
  final bool hasLimitations;
  final String limitations;
  final String avoidedExercises;
  final bool clinicalNutrition;
  final double? calorieTarget;
  final double? proteinTarget;
  final List<String> schedule;

  static const levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const goals = [
    'Build muscle',
    'Fat loss',
    'Weight maintenance',
    'Build strength',
    'Improve fitness',
    'Improve endurance',
    'Improve mobility',
    'Body recomposition',
  ];
  static const environments = ['Gym', 'Home', 'Both'];
  static const genders = [
    'Male',
    'Female',
    'Another identity',
    'Prefer not to say',
  ];
  static const unitOptions = ['Metric', 'Imperial'];
  static const equations = [
    'Skip estimate',
    'Male coefficient',
    'Female coefficient',
  ];
  static const equipmentOptions = [
    'Dumbbells',
    'Resistance bands',
    'Barbell',
    'Bench',
    'Gym machines',
    'Pull-up bar',
    'Other',
  ];
  static const diets = [
    'Vegetarian',
    'Vegetarian with eggs',
    'Vegan',
    'Non-vegetarian',
  ];
  static const times = ['Flexible', 'Morning', 'Afternoon', 'Evening'];
  static const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const sessionKinds = [
    'Recovery',
    'Full-body strength',
    'Upper-body strength',
    'Lower-body strength',
    'Easy cardio',
    'Mobility',
  ];

  factory Profile.fromJson(Map<String, dynamic> source) {
    if (source['schemaVersion'] != 1 && source['schemaVersion'] != 2) {
      throw const FormatException('Unsupported profile version');
    }
    final json = Map<String, dynamic>.from(source);
    // Version 1 did not contain the following preferences. Never rewrite on read.
    if (source['schemaVersion'] == 1) {
      json['gender'] = 'Prefer not to say';
      json['units'] = 'Metric';
      json['age'] = null;
      json['heightCm'] = null;
      json['weightKg'] = null;
      json['waistCm'] = null;
      json['energyEquation'] = 'Skip estimate';
      json['activityFactor'] = 1.4;
      json['secondaryGoal'] = null;
      json['equipment'] = const [];
      json['minutes'] = 30;
      json['trainingTime'] = 'Flexible';
      json['restDays'] = const [];
      json['diet'] = 'Vegetarian';
      json['allergies'] = '';
      json['foodRestrictions'] = '';
      json['cuisine'] = 'Indian';
      json['budgetInr'] = null;
      json['meals'] = 3;
      json['hasLimitations'] = false;
      json['limitations'] = '';
      json['avoidedExercises'] = '';
      json['clinicalNutrition'] = false;
      json['calorieTarget'] = null;
      json['proteinTarget'] = null;
      json['schedule'] = const [];
    }
    String text(String key, {int max = 500}) {
      final value = json[key];
      if (value is! String || value.length > max) {
        throw FormatException('Invalid $key');
      }
      return value;
    }

    String choice(String key, List<String> options) {
      final value = text(key);
      if (!options.contains(value)) throw FormatException('Invalid $key');
      return value;
    }

    double? number(String key, double min, double max) {
      final value = json[key];
      if (value == null) return null;
      if (value is! num || !value.isFinite || value < min || value > max) {
        throw FormatException('Invalid $key');
      }
      return value.toDouble();
    }

    int integer(String key, int min, int max) {
      final value = json[key];
      if (value is! int || value < min || value > max) {
        throw FormatException('Invalid $key');
      }
      return value;
    }

    bool flag(String key) {
      if (json[key] is! bool) throw FormatException('Invalid $key');
      return json[key] as bool;
    }

    List<T> items<T>(String key, List<T> allowed, {bool unique = true}) {
      final value = json[key];
      if (value is! List ||
          value.any((v) => !allowed.contains(v)) ||
          (unique && value.toSet().length != value.length)) {
        throw FormatException('Invalid $key');
      }
      return List<T>.unmodifiable(value.cast<T>());
    }

    final name = text('name', max: 60).trim();
    if (name.isEmpty) throw const FormatException('Invalid name');
    final days = integer('days', 1, 7);
    final rests = items<int>('restDays', [0, 1, 2, 3, 4, 5, 6]);
    if (days > 7 - rests.length) {
      throw const FormatException('Not enough available training days');
    }
    final schedule = items<String>('schedule', sessionKinds, unique: false);
    if (schedule.isNotEmpty && schedule.length != 7) {
      throw const FormatException('Invalid schedule');
    }
    final hasLimitations = flag('hasLimitations');
    if (schedule.isNotEmpty) {
      if (rests.any((d) => schedule[d] != 'Recovery') ||
          schedule.where((s) => s != 'Recovery').length != days) {
        throw const FormatException('Schedule conflicts with availability');
      }
      if (hasLimitations &&
          schedule.any((s) => s != 'Recovery' && s != 'Mobility')) {
        throw const FormatException(
          'Review limitations before adding training',
        );
      }
    }
    final secondary = json['secondaryGoal'];
    if (secondary != null &&
        (!goals.contains(secondary) || secondary == json['goal'])) {
      throw const FormatException('Invalid secondary goal');
    }
    return Profile(
      name: name,
      level: choice('level', levels),
      goal: choice('goal', goals),
      days: days,
      environment: choice('environment', environments),
      gender: choice('gender', genders),
      units: choice('units', unitOptions),
      age: json['age'] == null ? null : integer('age', 13, 100),
      heightCm: number('heightCm', 80, 250),
      weightKg: number('weightKg', 20, 400),
      waistCm: number('waistCm', 20, 300),
      energyEquation: choice('energyEquation', equations),
      activityFactor:
          number('activityFactor', 1.2, 1.9) ??
          (throw const FormatException('Missing activity factor')),
      secondaryGoal: secondary as String?,
      equipment: items<String>('equipment', equipmentOptions),
      minutes: integer('minutes', 10, 120),
      trainingTime: choice('trainingTime', times),
      restDays: rests,
      diet: choice('diet', diets),
      allergies: text('allergies'),
      foodRestrictions: text('foodRestrictions'),
      cuisine: text('cuisine', max: 100),
      budgetInr: number('budgetInr', 0, 100000),
      meals: integer('meals', 1, 8),
      hasLimitations: hasLimitations,
      limitations: text('limitations'),
      avoidedExercises: text('avoidedExercises'),
      clinicalNutrition: flag('clinicalNutrition'),
      calorieTarget: number('calorieTarget', 1, 10000),
      proteinTarget: number('proteinTarget', 1, 500),
      schedule: schedule,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'name': name,
    'level': level,
    'goal': goal,
    'days': days,
    'environment': environment,
    'gender': gender,
    'units': units,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'waistCm': waistCm,
    'energyEquation': energyEquation,
    'activityFactor': activityFactor,
    'secondaryGoal': secondaryGoal,
    'equipment': equipment,
    'minutes': minutes,
    'trainingTime': trainingTime,
    'restDays': restDays,
    'diet': diet,
    'allergies': allergies,
    'foodRestrictions': foodRestrictions,
    'cuisine': cuisine,
    'budgetInr': budgetInr,
    'meals': meals,
    'hasLimitations': hasLimitations,
    'limitations': limitations,
    'avoidedExercises': avoidedExercises,
    'clinicalNutrition': clinicalNutrition,
    'calorieTarget': calorieTarget,
    'proteinTarget': proteinTarget,
    'schedule': schedule,
  };
}
