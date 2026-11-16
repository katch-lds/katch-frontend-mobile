import 'package:flutter/foundation.dart';

import '../session/session_manager.dart';
import '../session/session_status.dart';

/// Base dos stores com dados do Candidato (modelo de classes, 8.1).
///
/// Observa o `SessionManager` e chama `reset()` quando a sessão deixa de estar
/// iniciada, para que nenhum dado de uma conta fique em memória depois do fim
/// de sessão (RF105).
abstract class SessionScopedStore extends ChangeNotifier {
  SessionScopedStore(this._session) {
    _session.addListener(_onSessionChanged);
  }

  final SessionManager _session;

  /// Esvazia os dados do Candidato.
  void reset();

  void _onSessionChanged() {
    if (_session.status != SessionStatus.signedIn) {
      reset();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
