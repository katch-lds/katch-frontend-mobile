import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/reference_data_store.dart';

import '../support/fakes.dart';

void main() {
  test(
    'pede as localidades uma vez e volta a pedir depois de falhar',
    () async {
      final service = FakeReferenceListService();
      service.locationAnswers.add(() => throw const ConnectionFailure());
      final store = ReferenceDataStore(service);

      await store.loadLocations();

      expect(store.status, LoadStatus.failed);
      expect(store.error, isA<ConnectionFailure>());

      await store.loadLocations();
      await store.loadLocations();

      expect(store.status, LoadStatus.loaded);
      expect(store.locations, [braga, felgueiras]);
      expect(store.error, isNull);
      expect(service.locationCalls, 2);
    },
  );

  test(
    'pede as competências uma vez e volta a pedir depois de falhar',
    () async {
      final service = FakeReferenceListService();
      service.skillAnswers.add(() => throw const ConnectionFailure());
      final store = ReferenceDataStore(service);

      await store.loadSkills();

      expect(store.skillsStatus, LoadStatus.failed);
      expect(store.skillsError, isA<ConnectionFailure>());

      await store.loadSkills();
      await store.loadSkills();

      expect(store.skillsStatus, LoadStatus.loaded);
      expect(store.skills, [dotnet, flutterSkill, sql]);
      expect(store.skillsError, isNull);
      expect(service.skillCalls, 2);
    },
  );
}
