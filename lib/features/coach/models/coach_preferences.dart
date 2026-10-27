class CoachPreferences {
  const CoachPreferences({
    this.aiModel = 'GPT-4o',
    this.providerName = 'OpenAI',
    this.responseLanguage = 'English',
    this.streamingResponses = true,
    this.fitnessGoal = 'Muscle Gain',
    this.trainingLevel = 'Beginner',
    this.preferredCoachTone = 'Motivational',
    this.responseDetail = 'Balanced',
    this.saveChatHistory = true,
    this.rememberConversationContext = true,
    this.voiceResponses = false,
  });

  final String aiModel;
  final String providerName;
  final String responseLanguage;
  final bool streamingResponses;
  final String fitnessGoal;
  final String trainingLevel;
  final String preferredCoachTone;
  final String responseDetail;
  final bool saveChatHistory;
  final bool rememberConversationContext;
  final bool voiceResponses;

  CoachPreferences copyWith({
    String? aiModel,
    String? providerName,
    String? responseLanguage,
    bool? streamingResponses,
    String? fitnessGoal,
    String? trainingLevel,
    String? preferredCoachTone,
    String? responseDetail,
    bool? saveChatHistory,
    bool? rememberConversationContext,
    bool? voiceResponses,
  }) {
    return CoachPreferences(
      aiModel: aiModel ?? this.aiModel,
      providerName: providerName ?? this.providerName,
      responseLanguage: responseLanguage ?? this.responseLanguage,
      streamingResponses: streamingResponses ?? this.streamingResponses,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      preferredCoachTone: preferredCoachTone ?? this.preferredCoachTone,
      responseDetail: responseDetail ?? this.responseDetail,
      saveChatHistory: saveChatHistory ?? this.saveChatHistory,
      rememberConversationContext:
          rememberConversationContext ?? this.rememberConversationContext,
      voiceResponses: voiceResponses ?? this.voiceResponses,
    );
  }

  Map<String, dynamic> toJson() => {
    'aiModel': aiModel,
    'providerName': providerName,
    'responseLanguage': responseLanguage,
    'streamingResponses': streamingResponses,
    'fitnessGoal': fitnessGoal,
    'trainingLevel': trainingLevel,
    'preferredCoachTone': preferredCoachTone,
    'responseDetail': responseDetail,
    'saveChatHistory': saveChatHistory,
    'rememberConversationContext': rememberConversationContext,
    'voiceResponses': voiceResponses,
  };

  factory CoachPreferences.fromJson(Map<String, dynamic> json) {
    return CoachPreferences(
      aiModel: (json['aiModel'] as String?) ?? 'GPT-4o',
      providerName: (json['providerName'] as String?) ?? 'OpenAI',
      responseLanguage: (json['responseLanguage'] as String?) ?? 'English',
      streamingResponses: (json['streamingResponses'] as bool?) ?? true,
      fitnessGoal: (json['fitnessGoal'] as String?) ?? 'Muscle Gain',
      trainingLevel: (json['trainingLevel'] as String?) ?? 'Beginner',
      preferredCoachTone:
          (json['preferredCoachTone'] as String?) ?? 'Motivational',
      responseDetail: (json['responseDetail'] as String?) ?? 'Balanced',
      saveChatHistory: (json['saveChatHistory'] as bool?) ?? true,
      rememberConversationContext:
          (json['rememberConversationContext'] as bool?) ?? true,
      voiceResponses: (json['voiceResponses'] as bool?) ?? false,
    );
  }
}
