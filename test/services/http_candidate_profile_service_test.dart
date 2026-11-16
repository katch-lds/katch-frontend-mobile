import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/profile_requests.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/services/http_candidate_profile_service.dart';

import '../support/fakes.dart';
import '../support/profile_fixtures.dart';

void main() {
  late FakeApiClient api;
  late HttpCandidateProfileService service;

  setUp(() {
    api = FakeApiClient()..response = profileJson;
    service = HttpCandidateProfileService(api);
  });

  test('getProfile e updateProfile usam /api/candidate/profile', () async {
    final profile = await service.getProfile();
    await service.updateProfile(
      const UpdateCandidateProfileRequest(locationId: 'loc'),
    );

    expect(profile.fullName, 'Rita Fictícia Moreira');
    expect(api.calls, [
      'GET /api/candidate/profile',
      'PUT /api/candidate/profile',
    ]);
    expect((api.bodies.last! as Map<String, Object?>)['locationId'], 'loc');
  });

  test('updatePreferences devolve as preferências gravadas (6.2.3)', () async {
    api.response = {
      'maxDistanceKm': 25,
      'minSalaryExpectation': null,
      'workModes': ['REMOTE'],
      'contractTypes': <Object?>[],
    };

    final saved = await service.updatePreferences(
      const SearchPreferencesDto(maxDistanceKm: 25),
    );

    expect(saved.maxDistanceKm, 25);
    expect(saved.workModes, [WorkMode.remote]);
    expect(api.calls.single, 'PUT /api/candidate/profile/preferences');
  });

  test('competências da lista e «Outro» têm rotas próprias', () async {
    await service.addSkill(const AddSkillRequest('s1'));
    await service.removeSkill('s1');
    await service.addCustomSkill(const AddCustomSkillRequest('C#'));
    await service.removeCustomSkill('c1');

    expect(api.calls, [
      'POST /api/candidate/profile/skills',
      'DELETE /api/candidate/profile/skills/s1',
      'POST /api/candidate/profile/custom-skills',
      'DELETE /api/candidate/profile/custom-skills/c1',
    ]);
    expect(api.bodies[2], {'label': 'C#'});
  });

  test('hiperligações, fotografia e CV', () async {
    await service.setLinks(const SetLinksRequest(['https://a.pt']));
    await service.uploadPhoto(jpegFile());
    await service.uploadCv(pdfFile());

    expect(api.calls, [
      'PUT /api/candidate/profile/links',
      'UPLOAD /api/candidate/profile/photo',
      'UPLOAD /api/candidate/profile/cv',
    ]);
    expect(api.bodies.first, {
      'urls': ['https://a.pt'],
    });
  });

  test('uma resposta fora do contrato é UnexpectedFailure', () async {
    api.response = {'fullName': 1};

    await expectLater(service.getProfile(), throwsA(isA<UnexpectedFailure>()));
  });
}
