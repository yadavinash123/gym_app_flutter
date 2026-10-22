import 'dart:convert';
import '../../../core/storage/json_store.dart';
import '../models/ai_credentials.dart';

abstract class SecureCredentialsStore {
  Future<AiCredentials?> readCredentials();
  Future<void> writeCredentials(AiCredentials credentials);
  Future<void> clearCredentials();
}

class JsonSecureCredentialsStore implements SecureCredentialsStore {
  JsonSecureCredentialsStore(this.store);

  final JsonStore store;
  static const String storageKey = 'coach_credentials';
  static const String _salt = 'FitForgeAI_BYOK_Salt_2026';

  @override
  Future<AiCredentials?> readCredentials() async {
    final data = await store.read(storageKey);
    if (data == null) return null;

    final rawObfuscated = data['obfuscatedKey'] as String?;
    final decodedKey = rawObfuscated != null ? _deobfuscate(rawObfuscated) : '';

    final modified = Map<String, dynamic>.from(data);
    modified['apiKey'] = decodedKey;

    return AiCredentials.fromJson(modified);
  }

  @override
  Future<void> writeCredentials(AiCredentials credentials) async {
    final json = credentials.toJson();
    final plainKey = credentials.apiKey;

    // Remove plain key from disk payload and store obfuscated form
    json.remove('apiKey');
    json['obfuscatedKey'] = _obfuscate(plainKey);
    json['savedAt'] = DateTime.now().toIso8601String();

    await store.write(storageKey, json);
  }

  @override
  Future<void> clearCredentials() async {
    // Overwrite with empty credentials to ensure no orphaned key remnants exist
    await writeCredentials(const AiCredentials());
  }

  static String _obfuscate(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    final saltBytes = utf8.encode(_salt);
    final obfuscated = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ saltBytes[i % saltBytes.length],
    );
    return base64Encode(obfuscated);
  }

  static String _deobfuscate(String input) {
    if (input.isEmpty) return '';
    try {
      final bytes = base64Decode(input);
      final saltBytes = utf8.encode(_salt);
      final deobfuscated = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ saltBytes[i % saltBytes.length],
      );
      return utf8.decode(deobfuscated);
    } catch (_) {
      return '';
    }
  }
}
