import 'ai_provider.dart';

class AiCredentials {
  const AiCredentials({
    this.provider = AiProvider.offline,
    this.apiKey = '',
    this.modelName = '',
    this.customEndpointUrl = '',
    this.temperature = 0.7,
    this.maxTokens = 1024,
  });

  final AiProvider provider;
  final String apiKey;
  final String modelName;
  final String customEndpointUrl;
  final double temperature;
  final int maxTokens;

  bool get isConfigured {
    if (provider == AiProvider.offline) return true;
    return apiKey.trim().isNotEmpty;
  }

  String get activeModel {
    if (modelName.trim().isNotEmpty) return modelName.trim();
    return provider.defaultModel;
  }

  String get maskedApiKey {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return 'Not configured';
    if (trimmed.length <= 8) return '••••••••';
    final start = trimmed.substring(0, 4);
    final end = trimmed.substring(trimmed.length - 4);
    return '$start••••••••$end';
  }

  AiCredentials copyWith({
    AiProvider? provider,
    String? apiKey,
    String? modelName,
    String? customEndpointUrl,
    double? temperature,
    int? maxTokens,
  }) {
    return AiCredentials(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      customEndpointUrl: customEndpointUrl ?? this.customEndpointUrl,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'apiKey': apiKey,
      'modelName': modelName,
      'customEndpointUrl': customEndpointUrl,
      'temperature': temperature,
      'maxTokens': maxTokens,
    };
  }

  factory AiCredentials.fromJson(Map<String, dynamic> json) {
    return AiCredentials(
      provider: AiProvider.fromString(json['provider'] as String?),
      apiKey: (json['apiKey'] as String?) ?? '',
      modelName: (json['modelName'] as String?) ?? '',
      customEndpointUrl: (json['customEndpointUrl'] as String?) ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 1024,
    );
  }

  @override
  String toString() =>
      'AiCredentials(provider: ${provider.name}, model: $activeModel, key: $maskedApiKey)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCredentials &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          apiKey == other.apiKey &&
          modelName == other.modelName &&
          customEndpointUrl == other.customEndpointUrl &&
          temperature == other.temperature &&
          maxTokens == other.maxTokens;

  @override
  int get hashCode => Object.hash(
    provider,
    apiKey,
    modelName,
    customEndpointUrl,
    temperature,
    maxTokens,
  );
}
