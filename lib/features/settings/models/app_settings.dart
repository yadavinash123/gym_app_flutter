/// Application and Character settings inspired by openGym reference architecture.
/// Controls character model geometry for the 2D Muscle Map (body diagram),
/// character drawings for exercise animations and clips (figure),
/// and workout preferences.
class AppSettings {
  const AppSettings({
    this.bodyDiagram = 'male', // 'male' or 'female'
    this.exerciseFigure = 'male', // 'male' or 'female'
    this.themeMode = 'dark', // 'dark', 'light', 'system'
    this.accentColor = 'lime', // 'lime', 'cyan', 'amber', 'purple', 'emerald'
    this.units = 'Metric', // 'Metric', 'Imperial'
    this.weighInBeforeWorkout = true,
    this.keepScreenAwake = true,
    this.exerciseAnimations = 'full', // 'full', 'mini', 'off'
    this.firstDayOfWeek = 'Monday', // 'Monday', 'Sunday'
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      bodyDiagram: (json['bodyDiagram'] as String?)?.toLowerCase() == 'female'
          ? 'female'
          : 'male',
      exerciseFigure:
          (json['exerciseFigure'] as String?)?.toLowerCase() == 'female'
              ? 'female'
              : 'male',
      themeMode: json['themeMode'] as String? ?? 'dark',
      accentColor: json['accentColor'] as String? ?? 'lime',
      units: json['units'] as String? ?? 'Metric',
      weighInBeforeWorkout: json['weighInBeforeWorkout'] as bool? ?? true,
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? true,
      exerciseAnimations: json['exerciseAnimations'] as String? ?? 'full',
      firstDayOfWeek: json['firstDayOfWeek'] as String? ?? 'Monday',
    );
  }

  final String bodyDiagram;
  final String exerciseFigure;
  final String themeMode;
  final String accentColor;
  final String units;
  final bool weighInBeforeWorkout;
  final bool keepScreenAwake;
  final String exerciseAnimations;
  final String firstDayOfWeek;

  AppSettings copyWith({
    String? bodyDiagram,
    String? exerciseFigure,
    String? themeMode,
    String? accentColor,
    String? units,
    bool? weighInBeforeWorkout,
    bool? keepScreenAwake,
    String? exerciseAnimations,
    String? firstDayOfWeek,
  }) {
    return AppSettings(
      bodyDiagram: bodyDiagram ?? this.bodyDiagram,
      exerciseFigure: exerciseFigure ?? this.exerciseFigure,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      units: units ?? this.units,
      weighInBeforeWorkout: weighInBeforeWorkout ?? this.weighInBeforeWorkout,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      exerciseAnimations: exerciseAnimations ?? this.exerciseAnimations,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  Map<String, dynamic> toJson() => {
    'bodyDiagram': bodyDiagram,
    'exerciseFigure': exerciseFigure,
    'themeMode': themeMode,
    'accentColor': accentColor,
    'units': units,
    'weighInBeforeWorkout': weighInBeforeWorkout,
    'keepScreenAwake': keepScreenAwake,
    'exerciseAnimations': exerciseAnimations,
    'firstDayOfWeek': firstDayOfWeek,
  };
}
