import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_status.dart';

import '../support/fakes.dart';

void main() {
  late MemorySessionStorage storage;
  late FakeClock clock;
  late SessionManager manager;

  setUp(() {
    storage = MemorySessionStorage();
    clock = FakeClock();
    manager = SessionManager(storage: storage, clock: clock);
  });

  test(
    'começa a restaurar e fica sem sessão quando nada está guardado',
    () async {
      expect(manager.status, SessionStatus.restoring);

      await manager.restore();

      expect(manager.status, SessionStatus.signedOut);
      expect(manager.accessToken, isNull);
    },
  );

  test('restaura a sessão guardada que ainda não expirou', () async {
    storage.saved = Session.fromLoginResponse(candidateLogin());

    await manager.restore();

    expect(manager.status, SessionStatus.signedIn);
    expect(manager.isAuthenticated, isTrue);
    expect(manager.accessToken, 'token-candidato');
    expect(manager.userId, isNotNull);
  });

  test('apaga a sessão guardada já expirada', () async {
    storage.saved = Session.fromLoginResponse(
      candidateLogin(expiresAt: testNow.subtract(const Duration(minutes: 1))),
    );

    await manager.restore();

    expect(manager.status, SessionStatus.signedOut);
    expect(storage.saved, isNull);
  });

  test('uma falha do armazenamento no arranque deixa sem sessão', () async {
    storage.failRead = true;

    await manager.restore();

    expect(manager.status, SessionStatus.signedOut);
  });

  test('start guarda a sessão no armazenamento seguro', () async {
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.start(candidateLogin());

    expect(manager.status, SessionStatus.signedIn);
    expect(storage.saved?.token, 'token-candidato');
    expect(manager.current?.userType, UserType.candidate);
    expect(notifications, 1);
  });

  test('rejeita outro tipo de conta sem guardar nada (RF001)', () async {
    await manager.restore();

    final call = manager.start(candidateLogin(userType: UserType.recruiter));

    await expectLater(call, throwsA(isA<AuthenticationFailure>()));
    expect(manager.status, SessionStatus.signedOut);
    expect(storage.saved, isNull);
  });

  test('end termina a sessão e apaga a credencial (RF105)', () async {
    await manager.start(candidateLogin());

    await manager.end();

    expect(manager.status, SessionStatus.signedOut);
    expect(manager.accessToken, isNull);
    expect(storage.saved, isNull);
  });

  test('a credencial recusada pelo servidor faz expirar a sessão', () async {
    await manager.start(candidateLogin());

    manager.rejectCredential();
    await Future<void>.delayed(Duration.zero);

    expect(manager.status, SessionStatus.expired);
    expect(storage.saved, isNull);
  });

  test(
    'ao fim de 8 horas a credencial deixa de ser enviada (RNF005)',
    () async {
      await manager.start(candidateLogin());
      clock.current = testNow.add(const Duration(hours: 8));

      expect(manager.accessToken, isNull);
      await Future<void>.delayed(Duration.zero);

      expect(manager.status, SessionStatus.expired);
    },
  );

  test('expire sem sessão não altera o estado', () async {
    await manager.restore();

    await manager.expire();

    expect(manager.status, SessionStatus.signedOut);
  });
}
