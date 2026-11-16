import '../core/api_client.dart';
import '../models/candidate_profile_dto.dart';
import '../models/file_selection.dart';
import '../models/profile_requests.dart';
import '../models/search_preferences_dto.dart';
import 'candidate_profile_service.dart';
import 'response_reader.dart';

/// `CandidateProfileService` sobre a API v02 (`/api/candidate/profile`, 6.2).
class HttpCandidateProfileService implements CandidateProfileService {
  HttpCandidateProfileService(this._api);

  static const profilePath = '/api/candidate/profile';
  static const preferencesPath = '$profilePath/preferences';
  static const skillsPath = '$profilePath/skills';
  static const customSkillsPath = '$profilePath/custom-skills';
  static const linksPath = '$profilePath/links';
  static const photoPath = '$profilePath/photo';
  static const cvPath = '$profilePath/cv';

  final ApiClient _api;

  @override
  Future<CandidateProfileDto> getProfile() async {
    return _profile(await _api.get(profilePath));
  }

  @override
  Future<CandidateProfileDto> updateProfile(
    UpdateCandidateProfileRequest request,
  ) async {
    return _profile(await _api.put(profilePath, request.toJson()));
  }

  @override
  Future<SearchPreferencesDto> updatePreferences(
    SearchPreferencesDto request,
  ) async {
    final result = await _api.put(preferencesPath, request.toJson());
    return readModel(() => SearchPreferencesDto.fromJson(readObject(result)));
  }

  @override
  Future<CandidateProfileDto> addSkill(AddSkillRequest request) async {
    return _profile(await _api.post(skillsPath, request.toJson()));
  }

  @override
  Future<void> removeSkill(String skillId) {
    return _api.delete('$skillsPath/${Uri.encodeComponent(skillId)}');
  }

  @override
  Future<CandidateProfileDto> addCustomSkill(
    AddCustomSkillRequest request,
  ) async {
    return _profile(await _api.post(customSkillsPath, request.toJson()));
  }

  @override
  Future<void> removeCustomSkill(String customSkillId) {
    return _api.delete(
      '$customSkillsPath/${Uri.encodeComponent(customSkillId)}',
    );
  }

  @override
  Future<CandidateProfileDto> setLinks(SetLinksRequest request) async {
    return _profile(await _api.put(linksPath, request.toJson()));
  }

  @override
  Future<void> uploadPhoto(FileSelection file) => _api.upload(photoPath, file);

  @override
  Future<void> uploadCv(FileSelection file) => _api.upload(cvPath, file);

  static CandidateProfileDto _profile(Object? result) {
    return readModel(() => CandidateProfileDto.fromJson(readObject(result)));
  }
}
