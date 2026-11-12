import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/services/http_reference_list_service.dart';

import '../support/fakes.dart';

void main() {
  late FakeApiClient api;
  late HttpReferenceListService service;

  setUp(() {
    api = FakeApiClient();
    service = HttpReferenceListService(api);
  });

  test('listLocations pede as localidades sem credencial (6.13.1)', () async {
    api.response = [
      {'id': 'loc-1', 'name': 'Braga (Braga)'},
      {'id': 'loc-2', 'name': 'Guimarães (Braga)'},
    ];

    final locations = await service.listLocations();

    expect(api.calls, ['GET /api/reference-lists/locations']);
    expect(locations.map((item) => item.name), [
      'Braga (Braga)',
      'Guimarães (Braga)',
    ]);
  });

  test('listSkills pede as competências (6.13.2)', () async {
    api.response = <Object?>[];

    final skills = await service.listSkills();

    expect(api.calls, ['GET /api/reference-lists/skills']);
    expect(skills, isEmpty);
  });

  test('uma resposta que não é lista é UnexpectedFailure', () async {
    api.response = {'id': 'loc-1'};

    await expectLater(
      service.listLocations(),
      throwsA(isA<UnexpectedFailure>()),
    );
  });
}
