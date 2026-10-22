import 'dart:convert';
import 'dart:io';

import '../models/ai_credentials.dart';
import '../models/ai_provider.dart';
import '../models/coach_message.dart';

abstract class AiClient {
  Future<CoachMessage> sendMessage({
    required List<CoachMessage> history,
    required String systemPrompt,
    required AiCredentials credentials,
  });

  Future<bool> testConnection(AiCredentials credentials);
}

class AiException implements Exception {
  const AiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AiException: $message ${statusCode != null ? "(HTTP $statusCode)" : ""}';
}

class HttpAiClient implements AiClient {
  HttpAiClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<CoachMessage> sendMessage({
    required List<CoachMessage> history,
    required String systemPrompt,
    required AiCredentials credentials,
  }) async {
    if (credentials.provider == AiProvider.offline) {
      throw const AiException('Cannot dispatch network request with offline provider.');
    }

    if (credentials.apiKey.trim().isEmpty) {
      throw const AiException('API key is missing. Please configure credentials in Coach Settings.');
    }

    switch (credentials.provider) {
      case AiProvider.gemini:
        return _sendGeminiRequest(history, systemPrompt, credentials);
      case AiProvider.openai:
      case AiProvider.custom:
        return _sendOpenAiRequest(history, systemPrompt, credentials);
      case AiProvider.offline:
        throw const AiException('Offline mode');
    }
  }

  @override
  Future<bool> testConnection(AiCredentials credentials) async {
    if (credentials.provider == AiProvider.offline) return true;
    if (credentials.apiKey.trim().isEmpty) return false;

    try {
      final testMessage = [
        CoachMessage(
          id: 'ping_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: 'Ping. Reply with "pong" only.',
          timestamp: DateTime.now(),
        ),
      ];
      final res = await sendMessage(
        history: testMessage,
        systemPrompt: 'Respond in 1 word.',
        credentials: credentials.copyWith(maxTokens: 10),
      );
      return res.content.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Google Gemini Provider
  // ---------------------------------------------------------------------------

  Future<CoachMessage> _sendGeminiRequest(
    List<CoachMessage> history,
    String systemPrompt,
    AiCredentials credentials,
  ) async {
    final model = credentials.activeModel;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${credentials.apiKey}',
    );

    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      if (msg.role == MessageRole.system) continue;
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      });
    }

    final payload = {
      'contents': contents,
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      'generationConfig': {
        'temperature': credentials.temperature,
        'maxOutputTokens': credentials.maxTokens,
      },
    };

    final response = await _postJson(uri, payload, headers: {});
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMsg = json['error']?['message'] as String? ?? 'Gemini API Error';
      throw AiException(errorMsg, statusCode: response.statusCode);
    }

    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const AiException('No response candidate returned by Gemini.');
    }

    final text = candidates[0]['content']?['parts']?[0]?['text'] as String? ?? '';
    final tokenUsage = json['usageMetadata']?['totalTokenCount'] as num?;

    return CoachMessage(
      id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.now(),
      offlineGenerated: false,
      provider: AiProvider.gemini,
      modelName: model,
      tokensUsed: tokenUsage?.toInt(),
      suggestedActions: const [
        'How does this affect my workout today?',
        'Can you adjust my nutrition targets?',
        'Explain the underlying science',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OpenAI & Custom OpenAI-compatible Provider
  // ---------------------------------------------------------------------------

  Future<CoachMessage> _sendOpenAiRequest(
    List<CoachMessage> history,
    String systemPrompt,
    AiCredentials credentials,
  ) async {
    final isCustom = credentials.provider == AiProvider.custom;
    final endpointUrl = isCustom && credentials.customEndpointUrl.trim().isNotEmpty
        ? credentials.customEndpointUrl.trim()
        : 'https://api.openai.com/v1/chat/completions';

    final uri = Uri.parse(endpointUrl);

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final msg in history) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    final payload = {
      'model': credentials.activeModel,
      'messages': messages,
      'temperature': credentials.temperature,
      'max_tokens': credentials.maxTokens,
    };

    final headers = {
      'Authorization': 'Bearer ${credentials.apiKey}',
    };

    final response = await _postJson(uri, payload, headers: headers);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMsg = json['error']?['message'] as String? ?? 'OpenAI API Error';
      throw AiException(errorMsg, statusCode: response.statusCode);
    }

    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const AiException('No choices returned by OpenAI.');
    }

    final text = choices[0]['message']?['content'] as String? ?? '';
    final totalTokens = json['usage']?['total_tokens'] as num?;

    return CoachMessage(
      id: 'openai_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.now(),
      offlineGenerated: false,
      provider: credentials.provider,
      modelName: credentials.activeModel,
      tokensUsed: totalTokens?.toInt(),
      suggestedActions: const [
        'How does this affect my workout today?',
        'Can you adjust my nutrition targets?',
        'Explain the underlying science',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Raw HTTP Execution
  // ---------------------------------------------------------------------------

  Future<({int statusCode, String body})> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    required Map<String, String> headers,
  }) async {
    try {
      final request = await _httpClient.postUrl(uri).timeout(const Duration(seconds: 25));
      request.headers.contentType = ContentType.json;
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final jsonPayload = utf8.encode(jsonEncode(body));
      request.contentLength = jsonPayload.length;
      request.add(jsonPayload);

      final response = await request.close().timeout(const Duration(seconds: 25));
      final responseBody = await utf8.decodeStream(response);

      return (statusCode: response.statusCode, body: responseBody);
    } on SocketException catch (e) {
      throw AiException('Network connection failed: ${e.message}');
    } on HandshakeException catch (e) {
      throw AiException('SSL Handshake error: ${e.message}');
    } on HttpException catch (e) {
      throw AiException('HTTP error: ${e.message}');
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException('AI request failed: $e');
    }
  }
}
