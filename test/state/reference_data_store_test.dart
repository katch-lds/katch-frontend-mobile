import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/reference_item_dto.dart';
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

  test('quem pede durante o pedido em curso espera por ele', () async {
    final service = FakeReferenceListService();
    final locations = Completer<List<ReferenceItemDto>>();
    final skills = Completer<List<ReferenceItemDto>>();
    service.locationAnswers.add(() => locations.future);
    service.skillAnswers.add(() => skills.future);
    final store = ReferenceDataStore(service);

    final first = Future.wait([store.loadLocations(), store.loadSkills()]);
    final second = Future.wait([store.loadLocations(), store.loadSkills()]);
    locations.complete(const [braga]);
    skills.complete(const [sql]);
    await second;

    expect(store.locations, [braga]);
    expect(store.skills, [sql]);
    await first;
    expect(service.locationCalls, 1);
    expect(service.skillCalls, 1);
  });

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
