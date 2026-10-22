import 'package:flutter/material.dart';

enum AiProvider {
  gemini,
  openai,
  custom,
  offline;

  String get displayName {
    switch (this) {
      case AiProvider.gemini:
        return 'Google Gemini';
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.custom:
        return 'Custom (OpenAI-compatible)';
      case AiProvider.offline:
        return 'Offline Heuristic Coach';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProvider.gemini:
        return 'gemini-1.5-flash';
      case AiProvider.openai:
        return 'gpt-4o-mini';
      case AiProvider.custom:
        return 'custom-model';
      case AiProvider.offline:
        return 'offline-rules-v1';
    }
  }

  List<String> get suggestedModels {
    switch (this) {
      case AiProvider.gemini:
        return const ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'];
      case AiProvider.openai:
        return const ['gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo'];
      case AiProvider.custom:
        return const ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'custom-model'];
      case AiProvider.offline:
        return const ['offline-rules-v1'];
    }
  }

  IconData get icon {
    switch (this) {
      case AiProvider.gemini:
        return Icons.auto_awesome;
      case AiProvider.openai:
        return Icons.psychology;
      case AiProvider.custom:
        return Icons.hub_outlined;
      case AiProvider.offline:
        return Icons.offline_bolt_outlined;
    }
  }

  Color get brandColor {
    switch (this) {
      case AiProvider.gemini:
        return const Color(0xFF00D4FF); // Cyan
      case AiProvider.openai:
        return const Color(0xFF10A37F); // OpenAI Green
      case AiProvider.custom:
        return const Color(0xFFFFB800); // Amber
      case AiProvider.offline:
        return const Color(0xFFB6FF3B); // FitForge Neon
    }
  }

  String get keyDocumentationUrl {
    switch (this) {
      case AiProvider.gemini:
        return 'https://aistudio.google.com/app/apikey';
      case AiProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case AiProvider.custom:
        return '';
      case AiProvider.offline:
        return '';
    }
  }

  static AiProvider fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'gemini':
        return AiProvider.gemini;
      case 'openai':
        return AiProvider.openai;
      case 'custom':
        return AiProvider.custom;
      case 'offline':
      default:
        return AiProvider.offline;
    }
  }
}
