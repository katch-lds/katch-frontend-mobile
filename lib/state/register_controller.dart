import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/input_rules.dart';
import '../models/field_errors.dart';
import '../models/reference_item_dto.dart';
import '../models/register_candidate_request.dart';
import '../services/auth_service.dart';
import '../session/session_manager.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'reference_data_store.dart';

/// Passo do registo (modelo de classes, 8.2).
enum RegistrationStep { editing, completed }

/// Estado do registo do Candidato, M02 a M04 (modelo de classes, 8.2).
///
/// Valida localmente os campos (`InputRules`) e, só depois, envia o pedido. Os
/// motivos do servidor, por campo, também vão para `errors` (RF004). Em caso de
/// êxito, a conta fica ativa e a sessão é iniciada com a resposta do registo
/// (RF005).
class RegisterController extends ChangeNotifier {
  RegisterController({
    required AuthService auth,
    required SessionManager session,
    required ReferenceDataStore reference,
  }) : _auth = auth,
       _session = session,
       _reference = reference;

  /// Nomes dos campos, iguais aos do `RegisterCandidateRequest` (API 6.1.1).
  static const fullNameField = 'fullName';
  static const emailField = 'email';
  static const phoneNumberField = 'phoneNumber';
  static const locationIdField = 'locationId';
  static const passwordField = 'password';
  static const acceptTermsField = 'acceptTerms';

  final AuthService _auth;
  final SessionManager _session;
  final ReferenceDataStore _reference;

  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  String? _locationId;
  String _password = '';
  bool _acceptTerms = false;
  FieldErrors _errors = FieldErrors();
  LoadStatus _status = LoadStatus.idle;
  RegistrationStep _step = RegistrationStep.editing;
  String? _errorMessage;

  String get fullName => _fullName;

  String get email => _email;

  String get phoneNumber => _phoneNumber;

  String? get locationId => _locationId;

  String get password => _password;

  bool get acceptTerms => _acceptTerms;

  FieldErrors get errors => _errors;

  LoadStatus get status => _status;

  RegistrationStep get step => _step;

  /// Motivo geral da rejeição (por exemplo, falha de ligação, RNF014).
  String? get errorMessage => _errorMessage;

  List<ReferenceItemDto> get locations => _reference.locations;

  LoadStatus get locationsStatus => _reference.status;

  set fullName(String value) => _edit(fullNameField, () => _fullName = value);

  set email(String value) => _edit(emailField, () => _email = value);

  set phoneNumber(String value) =>
      _edit(phoneNumberField, () => _phoneNumber = value);

  set locationId(String? value) =>
      _edit(locationIdField, () => _locationId = value);

  set password(String value) => _edit(passwordField, () => _password = value);

  set acceptTerms(bool value) =>
      _edit(acceptTermsField, () => _acceptTerms = value);

  /// Pede a lista de localidades, sem credencial (API v02, 6.13.1).
  Future<void> loadLocations() async {
    await _reference.loadLocations();
    notifyListeners();
  }

  /// Valida todos os campos e indica cada um em causa (RF004).
  bool validate() {
    final errors = FieldErrors();
    if (InputRules.isBlank(_fullName)) {
      errors.add(fullNameField, InputRules.requiredReason);
    }
    if (InputRules.isBlank(_email)) {
      errors.add(emailField, InputRules.requiredReason);
    } else if (!InputRules.isValidEmail(_email)) {
      errors.add(emailField, InputRules.emailReason);
    }
    if (InputRules.isBlank(_phoneNumber)) {
      errors.add(phoneNumberField, InputRules.requiredReason);
    } else if (!InputRules.isValidPhone(_phoneNumber)) {
      errors.add(phoneNumberField, InputRules.phoneReason);
    }
    if (_locationId == null) {
      errors.add(locationIdField, InputRules.requiredReason);
    }
    if (InputRules.isBlank(_password)) {
      errors.add(passwordField, InputRules.requiredReason);
    } else if (!InputRules.isValidPassword(_password)) {
      errors.add(passwordField, InputRules.passwordReason);
    }
    if (!_acceptTerms) {
      errors.add(acceptTermsField, InputRules.acceptTermsReason);
    }
    _errors = errors;
    notifyListeners();
    return errors.isEmpty;
  }

  /// Envia o registo; em caso de êxito, inicia a sessão e conclui o registo.
  Future<void> submit() async {
    if (_status == LoadStatus.loading || !validate()) {
      return;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _auth.register(
        RegisterCandidateRequest(
          fullName: _fullName.trim(),
          email: _email.trim(),
          phoneNumber: _phoneNumber.trim(),
          locationId: _locationId!,
          password: _password,
          acceptTerms: _acceptTerms,
        ),
      );
      await _session.start(response);
      _status = LoadStatus.loaded;
      _step = RegistrationStep.completed;
    } on ApiRejection catch (rejection) {
      _status = LoadStatus.failed;
      _errors = FieldErrors.fromApi(rejection.error);
      _errorMessage = rejection.error.message;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    notifyListeners();
  }

  /// Altera um campo e retira o motivo que lhe estava associado.
  void _edit(String field, void Function() change) {
    change();
    _errors.remove(field);
    notifyListeners();
  }
}
