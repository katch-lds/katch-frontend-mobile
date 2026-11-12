import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/clock.dart';
import '../core/credential_provider.dart';
import '../models/login_response.dart';
import '../models/user_type.dart';
import 'session.dart';
import 'session_status.dart';
import 'session_storage.dart';

/// Guarda, restaura e termina a sessão do Candidato (modelo de classes, 6).
///
/// A credencial fica no armazenamento seguro (`SessionStorage`) e é dada ao
/// `HttpApiClient` através de `CredentialProvider`. A expiração (8 horas,
/// RNF005) é verificada sempre que a credencial é pedida: uma sessão expirada
/// não é enviada e passa ao estado `expired`.
class SessionManager extends ChangeNotifier implements CredentialProvider {
  SessionManager({
    required SessionStorage storage,
    Clock clock = const SystemClock(),
  }) : _storage = storage,
       _clock = clock;

  final SessionStorage _storage;
  final Clock _clock;

  Session? _current;
  SessionStatus _status = SessionStatus.restoring;

  Session? get current => _current;

  SessionStatus get status => _status;

  String? get userId => _current?.userId;

  bool get isAuthenticated => _status == SessionStatus.signedIn;

  @override
  String? get accessToken {
    final session = _current;
    if (session == null) {
      return null;
    }
    if (session.isExpiredAt(_clock.now())) {
      scheduleMicrotask(expire);
      return null;
    }
    return session.token;
  }

  /// Lê a sessão guardada no arranque; uma sessão expirada é apagada.
  Future<void> restore() async {
    Session? saved;
    try {
      saved = await _storage.read();
    } on Object {
      await _clearAndSet(SessionStatus.signedOut);
      return;
    }
    if (saved == null || saved.isExpiredAt(_clock.now())) {
      await _clearAndSet(SessionStatus.signedOut);
      return;
    }
    _current = saved;
    _setStatus(SessionStatus.signedIn);
  }

  /// Inicia a sessão com a resposta do início de sessão ou do registo.
  ///
  /// A aplicação móvel é exclusiva do Candidato (RF001): outro tipo de conta é
  /// rejeitado com `AuthenticationFailure` e nada é guardado.
  Future<void> start(LoginResponse response) async {
    if (response.userType != UserType.candidate) {
      throw const AuthenticationFailure(
        'Esta conta não tem acesso por este ponto de acesso.',
      );
    }
    final session = Session.fromLoginResponse(response);
    await _storage.write(session);
    _current = session;
    _setStatus(SessionStatus.signedIn);
  }

  /// Fim de sessão pedido pelo Candidato (RF105).
  Future<void> end() => _clearAndSet(SessionStatus.signedOut);

  /// A sessão expirou ou a credencial foi recusada pelo servidor.
  Future<void> expire() async {
    if (_current == null) {
      return;
    }
    await _clearAndSet(SessionStatus.expired);
  }

  @override
  void rejectCredential() {
    unawaited(expire());
  }

  Future<void> _clearAndSet(SessionStatus status) async {
    _current = null;
    _setStatus(status);
    try {
      await _storage.clear();
    } on Object {
      // A sessão local já foi descartada; a falha do armazenamento não a repõe.
    }
  }

  void _setStatus(SessionStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    notifyListeners();
  }
}
