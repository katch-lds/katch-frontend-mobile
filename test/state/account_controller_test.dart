import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/state/account_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late MemorySessionStorage storage;
  late SessionManager session;
  late AccountController controller;

  setUp(() async {
    auth = FakeAuthService();
    storage = MemorySessionStorage();
    session = SessionManager(storage: storage, clock: FakeClock());
    await session.start(candidateLogin());
    controller = AccountController(auth: auth, session: session);
  });

  test(
    'terminar sessão avisa o servidor e apaga a credencial (RF105)',
    () async {
      await controller.signOut();

      expect(auth.logouts, 1);
      expect(session.status, SessionStatus.signedOut);
      expect(session.accessToken, isNull);
      expect(storage.saved, isNull);
      expect(controller.signingOut, isFalse);
    },
  );

  test('termina a sessão local mesmo sem resposta do servidor', () async {
    auth.onLogout = () => throw const ConnectionFailure();

    await controller.signOut();

    expect(session.status, SessionStatus.signedOut);
  });

  test('não falha quando o ecrã já foi fechado', () async {
    final pending = controller.signOut();
    controller.dispose();

    await pending;

    expect(session.status, SessionStatus.signedOut);
  });
}
