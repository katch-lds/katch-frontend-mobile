import '../models/candidate_profile_dto.dart';
import '../models/file_selection.dart';
import '../models/profile_requests.dart';
import '../models/search_preferences_dto.dart';

/// Operações do `CandidateProfileController` (API v02, secção 6.2).
///
/// O servidor obtém o Candidato da credencial de sessão.
abstract interface class CandidateProfileService {
  /// Perfil profissional (6.2.1).
  Future<CandidateProfileDto> getProfile();

  /// Função, localidade, disponibilidade e resumo (6.2.2; RF006).
  Future<CandidateProfileDto> updateProfile(
    UpdateCandidateProfileRequest request,
  );

  /// Preferências de procura (6.2.3; RF007).
  Future<SearchPreferencesDto> updatePreferences(SearchPreferencesDto request);

  /// Competência da lista pré-definida (6.2.4; RF008).
  Future<CandidateProfileDto> addSkill(AddSkillRequest request);

  /// Retira uma competência da lista (6.2.5; RF008).
  Future<void> removeSkill(String skillId);

  /// Competência «Outro» (6.2.10; RF009).
  Future<CandidateProfileDto> addCustomSkill(AddCustomSkillRequest request);

  /// Retira uma competência «Outro» (6.2.11; RF009).
  Future<void> removeCustomSkill(String customSkillId);

  /// Hiperligações profissionais, de 0 a 3 (6.2.6; RF012).
  Future<CandidateProfileDto> setLinks(SetLinksRequest request);

  /// Fotografia de perfil, JPEG ou PNG até 5 MB (6.2.7; RF010).
  Future<void> uploadPhoto(FileSelection file);

  /// Curriculum vitae, PDF até 5 MB (6.2.8; RF011).
  Future<void> uploadCv(FileSelection file);
}
