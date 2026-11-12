import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/login_request.dart';
import '../services/auth_service.dart';
import '../session/session_manager.dart';
import 'failure_messages.dart';
import 'load_status.dart';

/// Estado do ecrã de início de sessão, M01 (modelo de classes, 8.2).
///
/// Quando o servidor rejeita o início de sessão, mostra a `message` do
/// `ApiErrorDto` sem a alterar: ERR-02 (a mesma para correio inexistente e
/// palavra-passe errada, RNF009), ERR-03, ERR-04 e ERR-05 (RF001).
class LoginController extends ChangeNotifier {
  LoginController({required AuthService auth, required SessionManager session})
    : _auth = auth,
      _session = session;

  final AuthService _auth;
  final SessionManager _session;

  String _email = '';
  String _password = '';
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  String get email => _email;

  String get password => _password;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      _status != LoadStatus.loading &&
      _email.trim().isNotEmpty &&
      _password.isNotEmpty;

  set email(String value) => _update(() => _email = value);

  set password(String value) => _update(() => _password = value);

  /// Inicia a sessão; devolve `true` em caso de êxito.
  Future<bool> submit() async {
    if (!canSubmit) {
      return false;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _auth.login(
        LoginRequest(email: _email.trim(), password: _password),
      );
      await _session.start(response);
      _status = LoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
      notifyListeners();
      return false;
    }
  }

  void _update(void Function() change) {
    change();
    notifyListeners();
  }
}
