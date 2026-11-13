import '../core/api_exception.dart';
import '../models/candidate_profile_dto.dart';
import '../models/search_preferences_dto.dart';
import '../services/candidate_profile_service.dart';
import '../session/session_manager.dart';
import 'load_status.dart';
import 'session_scoped_store.dart';

/// Perfil profissional do Candidato, partilhado por M05 a M08 (modelo de
/// classes, 8.1).
///
/// Cada controller que altera o perfil entrega-lhe o `CandidateProfileDto`
/// devolvido pelo serviço (`update`); depois do envio de um ficheiro, volta a
/// pedir o perfil (`refresh`) para obter `photoUrl` e `hasCv`.
class ProfileStore extends SessionScopedStore {
  ProfileStore({
    required CandidateProfileService service,
    required SessionManager session,
  }) : _service = service,
       super(session);

  final CandidateProfileService _service;

  CandidateProfileDto? _profile;
  LoadStatus _status = LoadStatus.idle;
  ApiException? _error;

  /// Aumenta em cada `reset()`, para ignorar respostas pedidas antes do fim
  /// de sessão.
  int _generation = 0;

  CandidateProfileDto? get profile => _profile;

  String? get photoUrl => _profile?.photoUrl;

  SearchPreferencesDto? get preferences => _profile?.preferences;

  LoadStatus get status => _status;

  ApiException? get error => _error;

  /// Pede o perfil, uma vez; depois de uma falha, volta a pedir.
  Future<void> load() async {
    if (_status == LoadStatus.loading || _status == LoadStatus.loaded) {
      return;
    }
    await refresh();
  }

  /// Volta a pedir o perfil ao servidor.
  Future<void> refresh() async {
    final generation = _generation;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final profile = await _service.getProfile();
      if (generation != _generation) {
        return;
      }
      _profile = profile;
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      if (generation != _generation) {
        return;
      }
      _error = failure;
      _status = _profile == null ? LoadStatus.failed : LoadStatus.loaded;
    }
    notifyListeners();
  }

  /// Perfil devolvido por uma operação que o alterou.
  void update(CandidateProfileDto updated) {
    _profile = updated;
    _status = LoadStatus.loaded;
    notifyListeners();
  }

  /// Preferências gravadas (RF007), que a área de exploração observa (RF023).
  void updatePreferences(SearchPreferencesDto updated) {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    update(profile.withPreferences(updated));
  }

  @override
  void reset() {
    _generation++;
    _profile = null;
    _error = null;
    _status = LoadStatus.idle;
    notifyListeners();
  }
}
