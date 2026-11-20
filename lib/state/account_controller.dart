import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../session/session_manager.dart';
import 'safe_change_notifier.dart';

/// Estado do ecrã «Conta», M20.
///
/// `signOut()` pede o fim de sessão ao servidor, sem depender do resultado, e
/// termina a sessão local: o cliente descarta a credencial e passa a exigir
/// novo início de sessão (RF105; API v02, 3.5).
class AccountController extends SafeChangeNotifier {
  AccountController({
    required AuthService auth,
    required SessionManager session,
  }) : _auth = auth,
       _session = session;

  final AuthService _auth;
  final SessionManager _session;

  bool _signingOut = false;

  bool get signingOut => _signingOut;

  Future<void> signOut() async {
    if (_signingOut) {
      return;
    }
    _signingOut = true;
    notifyListeners();
    try {
      await _auth.logout();
    } on ApiException {
      // O fim de sessão local não depende da resposta do servidor.
    }
    await _session.end();
    _signingOut = false;
    // O fim de sessão fecha o ecrã «Conta», que pode já ter destruído o estado.
    notifyListeners();
  }
}
