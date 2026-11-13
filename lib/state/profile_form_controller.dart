import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/input_rules.dart';
import '../models/field_errors.dart';
import '../models/profile_enums.dart';
import '../models/profile_requests.dart';
import '../models/reference_item_dto.dart';
import '../services/candidate_profile_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'profile_store.dart';
import 'reference_data_store.dart';

/// Estado dos dados do perfil em M05 (modelo de classes, 8.3; RF006).
///
/// Função pretendida, localidade (da lista), disponibilidade e resumo da
/// experiência, com o contador «n/1000». Valida os limites (P08) antes de
/// enviar e grava com `updateProfile`.
class ProfileFormController extends ChangeNotifier {
  ProfileFormController({
    required CandidateProfileService service,
    required ProfileStore profile,
    required ReferenceDataStore reference,
  }) : _service = service,
       _profile = profile,
       _reference = reference;

  static const desiredRoleField = 'desiredRole';
  static const locationIdField = 'locationId';
  static const availabilityField = 'availability';
  static const experienceSummaryField = 'experienceSummary';

  final CandidateProfileService _service;
  final ProfileStore _profile;
  final ReferenceDataStore _reference;

  String _desiredRole = '';
  String? _locationId;
  Availability? _availability;
  String _experienceSummary = '';
  FieldErrors _errors = FieldErrors();
  LoadStatus _loadStatus = LoadStatus.idle;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _disposed = false;

  String get desiredRole => _desiredRole;

  String? get locationId => _locationId;

  Availability? get availability => _availability;

  String get experienceSummary => _experienceSummary;

  /// Caracteres do resumo, para o contador «n/1000».
  int get summaryLength => _experienceSummary.length;

  List<ReferenceItemDto> get locations => _reference.locations;

  FieldErrors get errors => _errors;

  /// Estado do carregamento do perfil e das localidades.
  LoadStatus get loadStatus => _loadStatus;

  /// Estado da gravação.
  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  set desiredRole(String value) =>
      _edit(desiredRoleField, () => _desiredRole = value);

  set locationId(String? value) =>
      _edit(locationIdField, () => _locationId = value);

  set availability(Availability? value) =>
      _edit(availabilityField, () => _availability = value);

  set experienceSummary(String value) =>
      _edit(experienceSummaryField, () => _experienceSummary = value);

  /// Carrega o perfil e a lista de localidades e preenche o formulário.
  Future<void> load() async {
    _loadStatus = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    await Future.wait([_profile.load(), _reference.loadLocations()]);
    final profile = _profile.profile;
    final failure = _profile.error ?? _reference.error;
    if (profile == null || _reference.status != LoadStatus.loaded) {
      _loadStatus = LoadStatus.failed;
      _errorMessage = failure == null ? null : failureMessage(failure);
      _notify();
      return;
    }
    _desiredRole = profile.desiredRole ?? '';
    _locationId = profile.locationId;
    _availability = profile.availability;
    _experienceSummary = profile.experienceSummary ?? '';
    _errors = FieldErrors();
    _loadStatus = LoadStatus.loaded;
    _notify();
  }

  bool validate() {
    final errors = FieldErrors();
    if (_desiredRole.trim().length > InputRules.desiredRoleMaxLength) {
      errors.add(
        desiredRoleField,
        InputRules.textTooLongReason(InputRules.desiredRoleMaxLength),
      );
    }
    if (_locationId == null) {
      errors.add(locationIdField, InputRules.requiredReason);
    }
    if (!InputRules.isValidSummary(_experienceSummary)) {
      errors.add(
        experienceSummaryField,
        InputRules.textTooLongReason(InputRules.summaryMaxLength),
      );
    }
    _errors = errors;
    _notify();
    return errors.isEmpty;
  }

  /// Grava os quatro campos; devolve `true` em caso de êxito.
  Future<bool> save() async {
    if (_status == LoadStatus.loading || !validate()) {
      return false;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      final updated = await _service.updateProfile(
        UpdateCandidateProfileRequest(
          desiredRole: _blankToNull(_desiredRole),
          locationId: _locationId!,
          availability: _availability,
          experienceSummary: _blankToNull(_experienceSummary),
        ),
      );
      _profile.update(updated);
      _status = LoadStatus.loaded;
      _notify();
      return true;
    } on ApiRejection catch (rejection) {
      _status = LoadStatus.failed;
      _errors = FieldErrors.fromApi(rejection.error);
      _errorMessage = rejection.error.message;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    _notify();
    return false;
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _edit(String field, void Function() change) {
    change();
    _errors.remove(field);
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
