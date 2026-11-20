import '../core/api_exception.dart';
import '../core/input_rules.dart';
import '../models/candidate_profile_dto.dart';
import '../models/custom_skill_dto.dart';
import '../models/field_errors.dart';
import '../models/profile_requests.dart';
import '../models/reference_item_dto.dart';
import '../services/candidate_profile_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'profile_store.dart';
import 'reference_data_store.dart';
import 'safe_change_notifier.dart';

/// Estado de M07, competências como etiquetas (RF008, RF009).
///
/// O Candidato escolhe da lista pré-definida (`toggle`), acrescenta uma
/// competência «Outro», validada antes de enviar (P07), ou remove uma
/// etiqueta. `save()` envia só as diferenças em relação ao perfil.
class SkillsController extends SafeChangeNotifier {
  SkillsController({
    required CandidateProfileService service,
    required ReferenceDataStore reference,
    required ProfileStore profile,
  }) : _service = service,
       _reference = reference,
       _profile = profile;

  /// Campo da competência «Outro» (o mesmo nome da API v02, 6.2.10).
  static const labelField = 'label';

  /// Campo da competência da lista (o mesmo nome da API v02, 6.2.4).
  static const skillIdField = 'skillId';

  /// Competência já indicada no perfil (igual ao motivo da API v02).
  static const alreadyAddedReason =
      'A competência já está associada ao perfil.';

  final CandidateProfileService _service;
  final ReferenceDataStore _reference;
  final ProfileStore _profile;

  List<ReferenceItemDto> _selected = [];
  List<CustomSkillDto> _selectedCustom = [];
  bool _customEnabled = false;
  String _customLabel = '';
  FieldErrors _errors = FieldErrors();
  LoadStatus _loadStatus = LoadStatus.idle;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  /// Competências da lista escolhidas.
  List<ReferenceItemDto> get selected => List.unmodifiable(_selected);

  /// Competências «Outro»; as novas ainda não têm `customSkillId`.
  List<CustomSkillDto> get selectedCustom => List.unmodifiable(_selectedCustom);

  /// Competências da lista ainda por escolher.
  List<ReferenceItemDto> get available => [
    for (final skill in _reference.skills)
      if (!_selected.any((item) => item.id == skill.id)) skill,
  ];

  /// O campo da competência «Outro» está visível.
  bool get customEnabled => _customEnabled;

  String get customLabel => _customLabel;

  FieldErrors get errors => _errors;

  LoadStatus get loadStatus => _loadStatus;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  set customLabel(String value) {
    _customLabel = value;
    _errors.remove(labelField);
    notifyListeners();
  }

  /// Carrega o perfil e a lista de competências.
  Future<void> load() async {
    _loadStatus = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    await Future.wait([_profile.load(), _reference.loadSkills()]);
    final profile = _profile.profile;
    final failure = _profile.error ?? _reference.skillsError;
    if (profile == null || _reference.skillsStatus != LoadStatus.loaded) {
      _loadStatus = LoadStatus.failed;
      _errorMessage = failure == null ? null : failureMessage(failure);
      notifyListeners();
      return;
    }
    _syncFrom(profile);
    _loadStatus = LoadStatus.loaded;
    notifyListeners();
  }

  /// Escolhe ou retira uma competência da lista (RF008).
  void toggle(ReferenceItemDto skill) {
    final index = _selected.indexWhere((item) => item.id == skill.id);
    if (index < 0) {
      _selected.add(skill);
    } else {
      _selected.removeAt(index);
    }
    _errors.remove(skillIdField);
    notifyListeners();
  }

  /// Mostra ou esconde o campo da opção «Outro» (RF009).
  void showCustom(bool enabled) {
    _customEnabled = enabled;
    if (!enabled) {
      _customLabel = '';
      _errors.remove(labelField);
    }
    notifyListeners();
  }

  /// Acrescenta a competência «Outro», se cumprir o P07; devolve `true` se a
  /// acrescentou.
  bool addCustom() {
    final label = _customLabel.trim();
    final String? reason;
    if (!InputRules.isValidCustomSkill(label)) {
      reason = InputRules.customSkillReason;
    } else if (_selectedCustom.any(
      (item) => item.label.toLowerCase() == label.toLowerCase(),
    )) {
      reason = alreadyAddedReason;
    } else {
      reason = null;
    }
    if (reason != null) {
      _errors.remove(labelField);
      _errors.add(labelField, reason);
      notifyListeners();
      return false;
    }
    _selectedCustom.add(CustomSkillDto(customSkillId: '', label: label));
    _customLabel = '';
    _customEnabled = false;
    _errors.remove(labelField);
    notifyListeners();
    return true;
  }

  void removeCustom(CustomSkillDto skill) {
    _selectedCustom.remove(skill);
    notifyListeners();
  }

  /// Envia as diferenças: retira e acrescenta as competências da lista e as
  /// competências «Outro»; devolve `true` se tudo foi gravado.
  Future<bool> save() async {
    final profile = _profile.profile;
    if (_status == LoadStatus.loading || profile == null) {
      return false;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    _errors = FieldErrors();
    notifyListeners();
    CandidateProfileDto? latest;
    var removed = false;
    try {
      for (final skill in profile.skills) {
        if (!_selected.any((item) => item.id == skill.id)) {
          await _service.removeSkill(skill.id);
          removed = true;
        }
      }
      for (final skill in profile.customSkills) {
        if (!_selectedCustom.any(
          (item) => item.customSkillId == skill.customSkillId,
        )) {
          await _service.removeCustomSkill(skill.customSkillId);
          removed = true;
        }
      }
      for (final skill in _selected) {
        if (!profile.skills.any((item) => item.id == skill.id)) {
          latest = await _service.addSkill(AddSkillRequest(skill.id));
        }
      }
      for (final skill in _selectedCustom) {
        if (skill.customSkillId.isEmpty) {
          latest = await _service.addCustomSkill(
            AddCustomSkillRequest(skill.label),
          );
        }
      }
      if (latest != null) {
        _profile.update(latest);
      } else if (removed) {
        await _profile.refresh();
      }
      final current = _profile.profile;
      if (current != null) {
        _syncFrom(current);
      }
      _status = LoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiRejection catch (rejection) {
      _status = LoadStatus.failed;
      _errors = FieldErrors.fromApi(rejection.error);
      _errorMessage = rejection.error.message;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    // Parte das diferenças pode já ter sido gravada: o perfil volta a ser
    // pedido e a gravação seguinte só envia as que faltam.
    await _profile.refresh();
    _keepSavedCustomIds();
    notifyListeners();
    return false;
  }

  /// Depois de uma falha, as competências «Outro» novas que o servidor já
  /// gravou passam a ter o `customSkillId`, para não serem enviadas outra vez.
  void _keepSavedCustomIds() {
    final saved = _profile.profile?.customSkills ?? const <CustomSkillDto>[];
    _selectedCustom = [
      for (final skill in _selectedCustom)
        if (skill.customSkillId.isNotEmpty)
          skill
        else
          saved.firstWhere(
            (item) => item.label.toLowerCase() == skill.label.toLowerCase(),
            orElse: () => skill,
          ),
    ];
  }

  void _syncFrom(CandidateProfileDto profile) {
    _selected = [...profile.skills];
    _selectedCustom = [...profile.customSkills];
  }
}
