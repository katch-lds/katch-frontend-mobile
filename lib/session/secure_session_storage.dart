import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/json.dart';
import 'session.dart';
import 'session_storage.dart';

/// Guarda a sessão no armazenamento seguro do sistema (Android Keystore).
///
/// A credencial nunca fica em texto simples nas preferências da aplicação nem
/// nos registos.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'katch.session';

  final FlutterSecureStorage _storage;

  @override
  Future<Session?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) {
      return null;
    }
    try {
      return Session.fromJson(jsonDecode(value) as Json);
    } on Object {
      // Uma sessão ilegível é apagada: o Candidato inicia sessão de novo.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(Session session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
