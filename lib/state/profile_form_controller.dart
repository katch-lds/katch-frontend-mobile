import '../core/input_rules.dart';
import '../models/field_errors.dart';
import '../models/profile_enums.dart';
import '../models/profile_requests.dart';
import '../models/reference_item_dto.dart';
import '../services/candidate_profile_service.dart';
import 'failure_messages.dart';
import 'form_controller.dart';
import 'load_status.dart';
import 'profile_store.dart';
import 'reference_data_store.dart';

/// Estado dos dados do perfil em M05 (RF006).
///
/// Função pretendida, localidade (da lista), disponibilidade e resumo da
/// experiência, com o contador «n/1000». Valida os limites (P08) antes de
/// enviar e grava com `updateProfile`.
class ProfileFormController extends FormController {
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
  LoadStatus _loadStatus = LoadStatus.idle;

  String get desiredRole => _desiredRole;

  String? get locationId => _locationId;

  Availability? get availability => _availability;

  String get experienceSummary => _experienceSummary;

  /// Caracteres do resumo, para o contador «n/1000», contados como na
  /// validação e no backend: sem os espaços das extremidades (P08).
  int get summaryLength => _experienceSummary.trim().length;

  List<ReferenceItemDto> get locations => _reference.locations;

  /// Estado do carregamento do perfil e das localidades.
  LoadStatus get loadStatus => _loadStatus;

  set desiredRole(String value) =>
      edit(desiredRoleField, () => _desiredRole = value);

  set locationId(String? value) =>
      edit(locationIdField, () => _locationId = value);

  set availability(Availability? value) =>
      edit(availabilityField, () => _availability = value);

  set experienceSummary(String value) =>
      edit(experienceSummaryField, () => _experienceSummary = value);

  /// Carrega o perfil e a lista de localidades e preenche o formulário.
  Future<void> load() async {
    _loadStatus = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    await Future.wait([_profile.load(), _reference.loadLocations()]);
    final profile = _profile.profile;
    final failure = _profile.error ?? _reference.error;
    if (profile == null || _reference.status != LoadStatus.loaded) {
      _loadStatus = LoadStatus.failed;
      errorMessage = failure == null ? null : failureMessage(failure);
      notifyListeners();
      return;
    }
    _desiredRole = profile.desiredRole ?? '';
    _locationId = profile.locationId;
    _availability = profile.availability;
    _experienceSummary = profile.experienceSummary ?? '';
    errors = FieldErrors();
    _loadStatus = LoadStatus.loaded;
    notifyListeners();
  }

  @override
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
    return applyValidation(errors);
  }

  /// Grava os quatro campos; devolve `true` em caso de êxito.
  Future<bool> save() {
    return send(() async {
      final updated = await _service.updateProfile(
        UpdateCandidateProfileRequest(
          desiredRole: _blankToNull(_desiredRole),
          locationId: _locationId!,
          availability: _availability,
          experienceSummary: _blankToNull(_experienceSummary),
        ),
      );
      _profile.update(updated);
    });
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
