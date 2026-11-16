import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/models/candidate_profile_dto.dart';
import 'package:katch_mobile/models/file_selection.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/profile_requests.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';

import '../support/profile_fixtures.dart';

void main() {
  test('CandidateProfileDto lê o perfil da API v02 (6.2.1)', () {
    final profile = CandidateProfileDto.fromJson(profileJson);

    expect(profile.fullName, 'Rita Fictícia Moreira');
    expect(profile.availability, Availability.fifteenDays);
    expect(profile.hasCv, isTrue);
    expect(profile.links, ['https://exemplo.pt/rita']);
    expect(profile.skills.single.name, 'Flutter');
    expect(profile.customSkills.single.label, 'C#');
    expect(profile.preferences.maxDistanceKm, 50);
    expect(profile.preferences.minSalaryExpectation, 1200.0);
    expect(profile.preferences.workModes, [WorkMode.hybrid, WorkMode.remote]);
    expect(profile.preferences.contractTypes, [ContractType.permanent]);
  });

  test('os campos opcionais em falta ficam vazios', () {
    final profile = CandidateProfileDto.fromJson({
      ...profileJson,
      'desiredRole': null,
      'availability': null,
      'photoUrl': null,
      'hasCv': null,
      'links': null,
      'skills': null,
      'customSkills': null,
      'preferences': null,
    });

    expect(profile.desiredRole, isNull);
    expect(profile.availability, isNull);
    expect(profile.hasCv, isFalse);
    expect(profile.links, isEmpty);
    expect(profile.skills, isEmpty);
    expect(profile.customSkills, isEmpty);
    expect(profile.preferences.workModes, isEmpty);
  });

  test('withPreferences só substitui as preferências', () {
    final profile = CandidateProfileDto.fromJson(profileJson);

    final updated = profile.withPreferences(
      const SearchPreferencesDto(maxDistanceKm: 10),
    );

    expect(updated.preferences.maxDistanceKm, 10);
    expect(updated.preferences.workModes, isEmpty);
    expect(updated.fullName, profile.fullName);
    expect(updated.links, profile.links);
    expect(updated.customSkills, profile.customSkills);
  });

  test('os pedidos usam os nomes e os valores da API v02', () {
    expect(
      const UpdateCandidateProfileRequest(
        locationId: 'loc',
        desiredRole: 'Analista',
        availability: Availability.toBeAgreed,
      ).toJson(),
      {
        'desiredRole': 'Analista',
        'locationId': 'loc',
        'availability': 'TO_BE_AGREED',
        'experienceSummary': null,
      },
    );
    expect(const AddSkillRequest('id').toJson(), {'skillId': 'id'});
    expect(const AddCustomSkillRequest('C#').toJson(), {'label': 'C#'});
    expect(const SetLinksRequest(['https://a.pt']).toJson(), {
      'urls': ['https://a.pt'],
    });
    expect(
      const SearchPreferencesDto(
        minSalaryExpectation: 950.5,
        workModes: [WorkMode.onSite],
        contractTypes: [ContractType.internship],
      ).toJson(),
      {
        'maxDistanceKm': null,
        'minSalaryExpectation': 950.5,
        'workModes': ['ON_SITE'],
        'contractTypes': ['INTERNSHIP'],
      },
    );
  });

  test('as enumerações rejeitam valores desconhecidos', () {
    for (final value in Availability.values) {
      expect(Availability.fromWire(value.toWire()), value);
    }
    for (final value in WorkMode.values) {
      expect(WorkMode.fromWire(value.toWire()), value);
    }
    for (final value in ContractType.values) {
      expect(ContractType.fromWire(value.toWire()), value);
    }
    expect(() => Availability.fromWire('X'), throwsFormatException);
    expect(() => WorkMode.fromWire('X'), throwsFormatException);
    expect(() => ContractType.fromWire('X'), throwsFormatException);
  });

  test('FileSelection indica a extensão, o tipo e o início do conteúdo', () {
    final file = FileSelection.fromBytes('Foto.JPG', List.filled(20, 1));

    expect(file.extension, '.jpg');
    expect(file.mimeType, 'image/jpeg');
    expect(file.sizeBytes, 20);
    expect(file.header, hasLength(FileSelection.headerLength));
    expect(FileSelection.fromBytes('a.png', []).mimeType, 'image/png');
    expect(FileSelection.fromBytes('a.pdf', []).mimeType, 'application/pdf');
    expect(FileSelection.fromBytes('sem', []).extension, '');
    expect(
      FileSelection.fromBytes('sem', []).mimeType,
      'application/octet-stream',
    );
  });
}
