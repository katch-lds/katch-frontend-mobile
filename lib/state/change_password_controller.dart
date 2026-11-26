import '../core/input_rules.dart';
import '../models/change_password_request.dart';
import '../models/field_errors.dart';
import '../services/auth_service.dart';
import 'form_controller.dart';

/// Estado da alteração da palavra-passe, M21.
///
/// A palavra-passe nova tem de cumprir o P05, ser diferente da atual e
/// coincidir com a confirmação, que só existe no cliente. O servidor rejeita
/// uma palavra-passe atual errada com `400` no campo `currentPassword`
/// (API v02, 6.1.5), que não é confundido com sessão expirada (RF002).
class ChangePasswordController extends FormController {
  ChangePasswordController({required AuthService auth}) : _auth = auth;

  static const currentPasswordField = 'currentPassword';
  static const newPasswordField = 'newPassword';
  static const confirmationField = 'confirmation';

  /// Palavra-passe nova igual à atual.
  static const sameAsCurrentReason =
      'A palavra-passe nova tem de ser diferente da atual.';

  /// Confirmação diferente da palavra-passe nova.
  static const confirmationReason =
      'A confirmação não coincide com a palavra-passe nova.';

  final AuthService _auth;

  String _currentPassword = '';
  String _newPassword = '';
  String _confirmation = '';

  String get currentPassword => _currentPassword;

  String get newPassword => _newPassword;

  String get confirmation => _confirmation;

  set currentPassword(String value) =>
      edit(currentPasswordField, () => _currentPassword = value);

  set newPassword(String value) =>
      edit(newPasswordField, () => _newPassword = value);

  set confirmation(String value) =>
      edit(confirmationField, () => _confirmation = value);

  @override
  bool validate() {
    final errors = FieldErrors();
    if (_currentPassword.isEmpty) {
      errors.add(currentPasswordField, InputRules.requiredReason);
    }
    if (_newPassword.isEmpty) {
      errors.add(newPasswordField, InputRules.requiredReason);
    } else if (!InputRules.isValidPassword(_newPassword)) {
      errors.add(newPasswordField, InputRules.passwordReason);
    } else if (_newPassword == _currentPassword) {
      errors.add(newPasswordField, sameAsCurrentReason);
    }
    if (_confirmation != _newPassword) {
      errors.add(confirmationField, confirmationReason);
    }
    return applyValidation(errors);
  }

  /// Envia a alteração; devolve `true` em caso de êxito.
  Future<bool> submit() {
    return send(
      () => _auth.changePassword(
        ChangePasswordRequest(
          currentPassword: _currentPassword,
          newPassword: _newPassword,
        ),
      ),
    );
  }
}
