import 'ai_provider.dart';

enum MessageRole {
  user,
  assistant,
  system;

  static MessageRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'system':
        return MessageRole.system;
      case 'assistant':
      default:
        return MessageRole.assistant;
    }
  }
}

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.offlineGenerated = false,
    this.provider,
    this.modelName,
    this.tokensUsed,
    this.suggestedActions = const [],
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool offlineGenerated;
  final AiProvider? provider;
  final String? modelName;
  final int? tokensUsed;
  final List<String> suggestedActions;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  CoachMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? offlineGenerated,
    AiProvider? provider,
    String? modelName,
    int? tokensUsed,
    List<String>? suggestedActions,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      offlineGenerated: offlineGenerated ?? this.offlineGenerated,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'offlineGenerated': offlineGenerated,
      'provider': provider?.name,
      'modelName': modelName,
      'tokensUsed': tokensUsed,
      'suggestedActions': suggestedActions,
    };
  }

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: (json['id'] as String?) ?? '',
      role: MessageRole.fromString(json['role'] as String?),
      content: (json['content'] as String?) ?? '',
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.now(),
      offlineGenerated: (json['offlineGenerated'] as bool?) ?? false,
      provider: json['provider'] != null
          ? AiProvider.fromString(json['provider'] as String?)
          : null,
      modelName: json['modelName'] as String?,
      tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
      suggestedActions: (json['suggestedActions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          content == other.content &&
          timestamp == other.timestamp &&
          offlineGenerated == other.offlineGenerated;

  @override
  int get hashCode => Object.hash(
        id,
        role,
        content,
        timestamp,
        offlineGenerated,
      );
}
