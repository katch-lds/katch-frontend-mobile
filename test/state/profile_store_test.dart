import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/profile_store.dart';

import '../support/fakes.dart';

void main() {
  late FakeCandidateProfileService service;
  late SessionManager session;
  late ProfileStore store;

  setUp(() async {
    service = FakeCandidateProfileService();
    session = SessionManager(
      storage: MemorySessionStorage(),
      clock: FakeClock(),
    );
    await session.start(candidateLogin());
    store = ProfileStore(service: service, session: session);
  });

  tearDown(() => store.dispose());

  test('pede o perfil uma vez', () async {
    await store.load();
    await store.load();

    expect(store.status, LoadStatus.loaded);
    expect(store.profile?.fullName, 'Rita Fictícia Moreira');
    expect(service.calls, ['getProfile']);
  });

  test('depois de uma falha, volta a pedir', () async {
    service.failures['getProfile'] = () => const ConnectionFailure();
    await store.load();

    expect(store.status, LoadStatus.failed);
    expect(store.error, isA<ConnectionFailure>());

    service.failures.clear();
    await store.load();

    expect(store.status, LoadStatus.loaded);
    expect(store.error, isNull);
  });

  test('refresh com falha mantém o perfil já carregado', () async {
    await store.load();
    service.failures['getProfile'] = () => const ConnectionFailure();

    await store.refresh();

    expect(store.status, LoadStatus.loaded);
    expect(store.profile, isNotNull);
    expect(store.error, isA<ConnectionFailure>());
  });

  test('update e updatePreferences substituem os dados', () async {
    store.updatePreferences(const SearchPreferencesDto(maxDistanceKm: 9));
    expect(store.preferences, isNull);

    store.update(sampleProfile(photoUrl: '/api/files/profile-photo/a.jpg'));
    store.updatePreferences(const SearchPreferencesDto(maxDistanceKm: 9));

    expect(store.photoUrl, '/api/files/profile-photo/a.jpg');
    expect(store.preferences?.maxDistanceKm, 9);
  });

  test('o fim de sessão esvazia o perfil (RF105)', () async {
    await store.load();

    await session.end();

    expect(store.profile, isNull);
    expect(store.status, LoadStatus.idle);
  });

  test('ignora a resposta pedida antes do fim de sessão', () async {
    final pending = store.load();
    await session.end();
    await pending;

    expect(store.profile, isNull);
    expect(store.status, LoadStatus.idle);
  });

  test('ignora a falha pedida antes do fim de sessão', () async {
    service.failures['getProfile'] = () => const ConnectionFailure();
    final pending = store.load();
    await session.end();
    await pending;

    expect(store.error, isNull);
    expect(store.status, LoadStatus.idle);
  });
}
