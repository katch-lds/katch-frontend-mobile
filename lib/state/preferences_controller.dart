import '../core/input_rules.dart';
import '../models/field_errors.dart';
import '../models/profile_enums.dart';
import '../models/search_preferences_dto.dart';
import '../services/candidate_profile_service.dart';
import 'form_controller.dart';
import 'profile_store.dart';

/// Estado de M08, preferências de procura (RF007).
///
/// Distância máxima (1 a 500 km, P06), pretensão salarial mínima, regimes de
/// trabalho e tipos de contrato. Um campo vazio ou nenhuma opção escolhida
/// significa sem filtro. Grava com `updatePreferences` e entrega as novas
/// preferências ao `ProfileStore`, que a área de exploração observa (RF023).
class PreferencesController extends FormController {
  PreferencesController({
    required CandidateProfileService service,
    required ProfileStore profile,
  }) : _service = service,
       _profile = profile;

  static const maxDistanceKmField = 'maxDistanceKm';
  static const minSalaryExpectationField = 'minSalaryExpectation';

  static final _integer = RegExp(r'^[0-9]+$');
  static final _amount = RegExp(r'^[0-9]+([.,][0-9]+)?$');

  final CandidateProfileService _service;
  final ProfileStore _profile;

  String _maxDistanceText = '';
  String _minSalaryText = '';
  final Set<WorkMode> _workModes = {};
  final Set<ContractType> _contractTypes = {};

  /// Texto do campo da distância máxima, como o Candidato o escreveu.
  String get maxDistanceText => _maxDistanceText;

  /// Texto do campo da pretensão salarial mínima.
  String get minSalaryText => _minSalaryText;

  /// Distância máxima, ou `null` sem valor ou com um valor que não é inteiro.
  int? get maxDistanceKm {
    final text = _maxDistanceText.trim();
    return _integer.hasMatch(text) ? int.tryParse(text) : null;
  }

  /// Pretensão salarial mínima em euros, ou `null`.
  double? get minSalaryExpectation {
    final text = _minSalaryText.trim();
    return _amount.hasMatch(text)
        ? double.tryParse(text.replaceAll(',', '.'))
        : null;
  }

  Set<WorkMode> get workModes => Set.unmodifiable(_workModes);

  Set<ContractType> get contractTypes => Set.unmodifiable(_contractTypes);

  set maxDistanceText(String value) =>
      edit(maxDistanceKmField, () => _maxDistanceText = value);

  set minSalaryText(String value) =>
      edit(minSalaryExpectationField, () => _minSalaryText = value);

  /// Preenche o formulário com as preferências do perfil.
  void load() {
    final preferences = _profile.preferences ?? const SearchPreferencesDto();
    _maxDistanceText = preferences.maxDistanceKm?.toString() ?? '';
    _minSalaryText = _formatAmount(preferences.minSalaryExpectation);
    _workModes
      ..clear()
      ..addAll(preferences.workModes);
    _contractTypes
      ..clear()
      ..addAll(preferences.contractTypes);
    errors = FieldErrors();
    notifyListeners();
  }

  void toggleWorkMode(WorkMode mode) {
    if (!_workModes.remove(mode)) {
      _workModes.add(mode);
    }
    notifyListeners();
  }

  void toggleContractType(ContractType type) {
    if (!_contractTypes.remove(type)) {
      _contractTypes.add(type);
    }
    notifyListeners();
  }

  @override
  bool validate() {
    final errors = FieldErrors();
    final distance = maxDistanceKm;
    if (_maxDistanceText.trim().isNotEmpty &&
        (distance == null || !InputRules.isValidDistanceKm(distance))) {
      errors.add(maxDistanceKmField, InputRules.distanceReason);
    }
    final salary = minSalaryExpectation;
    if (_minSalaryText.trim().isNotEmpty &&
        (salary == null || !InputRules.isValidSalary(salary))) {
      errors.add(minSalaryExpectationField, InputRules.salaryReason);
    }
    return applyValidation(errors);
  }

  /// Grava as preferências; devolve `true` em caso de êxito.
  Future<bool> save() {
    return send(() async {
      final saved = await _service.updatePreferences(
        SearchPreferencesDto(
          maxDistanceKm: maxDistanceKm,
          minSalaryExpectation: minSalaryExpectation,
          workModes: [
            for (final mode in WorkMode.values)
              if (_workModes.contains(mode)) mode,
          ],
          contractTypes: [
            for (final type in ContractType.values)
              if (_contractTypes.contains(type)) type,
          ],
        ),
      );
      _profile.updatePreferences(saved);
    });
  }

  /// Valor em euros sem casas decimais desnecessárias («1200» e «1200.5»).
  static String _formatAmount(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}
