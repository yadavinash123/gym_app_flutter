class CoachConsent {
  const CoachConsent({
    this.shareProfile = true,
    this.shareWorkouts = true,
    this.shareNutrition = true,
    this.shareHealth = true,
  });

  final bool shareProfile;
  final bool shareWorkouts;
  final bool shareNutrition;
  final bool shareHealth;

  int get activeShareCount {
    var count = 0;
    if (shareProfile) count++;
    if (shareWorkouts) count++;
    if (shareNutrition) count++;
    if (shareHealth) count++;
    return count;
  }

  CoachConsent copyWith({
    bool? shareProfile,
    bool? shareWorkouts,
    bool? shareNutrition,
    bool? shareHealth,
  }) {
    return CoachConsent(
      shareProfile: shareProfile ?? this.shareProfile,
      shareWorkouts: shareWorkouts ?? this.shareWorkouts,
      shareNutrition: shareNutrition ?? this.shareNutrition,
      shareHealth: shareHealth ?? this.shareHealth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareProfile': shareProfile,
      'shareWorkouts': shareWorkouts,
      'shareNutrition': shareNutrition,
      'shareHealth': shareHealth,
    };
  }

  factory CoachConsent.fromJson(Map<String, dynamic> json) {
    return CoachConsent(
      shareProfile: (json['shareProfile'] as bool?) ?? true,
      shareWorkouts: (json['shareWorkouts'] as bool?) ?? true,
      shareNutrition: (json['shareNutrition'] as bool?) ?? true,
      shareHealth: (json['shareHealth'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachConsent &&
          runtimeType == other.runtimeType &&
          shareProfile == other.shareProfile &&
          shareWorkouts == other.shareWorkouts &&
          shareNutrition == other.shareNutrition &&
          shareHealth == other.shareHealth;

  @override
  int get hashCode =>
      Object.hash(shareProfile, shareWorkouts, shareNutrition, shareHealth);
}
