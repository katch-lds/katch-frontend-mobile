import 'package:flutter/foundation.dart';

import '../core/credential_provider.dart';

/// Guarda a credencial de sessão em memória (I120).
///
/// O armazenamento seguro e o restauro da sessão chegam com o ecrã de início
/// de sessão do Candidato (modelo de classes do mobile v02, secção 6).
class SessionManager extends ChangeNotifier implements CredentialProvider {
  String? _accessToken;

  @override
  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;

  void start(String accessToken) {
    _accessToken = accessToken;
    notifyListeners();
  }

  void end() {
    _accessToken = null;
    notifyListeners();
  }

  @override
  void rejectCredential() => end();
}
