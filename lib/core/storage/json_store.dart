import 'dart:convert';
import 'dart:io';

/// One store instance owns all writes in the application's main isolate.
/// Each document is replaced by a flushed file on the same filesystem.
class JsonStore {
  JsonStore(this.directory);
  final Directory directory;
  Future<void> _tail = Future.value();

  File _file(String key, [String suffix = '']) {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key)) {
      throw ArgumentError('Invalid storage key');
    }
    return File('${directory.path}/$key.json$suffix');
  }

  Future<Map<String, dynamic>?> read(String key) async {
    await _tail;
    return _read(key);
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    final file = _file(key);
    final backup = _file(key, '.bak');
    if (!await file.exists() && !await backup.exists()) return null;
    try {
      return await _decode(file);
    } on FormatException {
      if (await backup.exists()) return _decode(backup);
      rethrow;
    } on FileSystemException {
      if (await backup.exists()) return _decode(backup);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _decode(File file) async {
    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid document');
    }
    return value;
  }

  Future<void> write(String key, Map<String, dynamic> value) {
    // Snapshot now so callers cannot mutate a queued write.
    final encoded = jsonEncode(value);
    final result = _tail.then((_) async {
      await directory.create(recursive: true);
      final current = _file(key);
      final old = await _read(key);
      if (old != null) {
        final backupTemp = _file(key, '.bak.tmp');
        await backupTemp.writeAsString(jsonEncode(old), flush: true);
        await backupTemp.rename(_file(key, '.bak').path);
      }
      final temp = _file(key, '.tmp');
      await temp.writeAsString(encoded, flush: true);
      await temp.rename(current.path);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
