import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/login_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late SessionManager session;
  late LoginController controller;

  setUp(() async {
    auth = FakeAuthService();
    session = SessionManager(
      storage: MemorySessionStorage(),
      clock: FakeClock(),
    );
    await session.restore();
    controller = LoginController(auth: auth, session: session);
  });

  void fill() {
    controller
      ..email = ' ana.ferreira@exemplo.pt '
      ..password = 'katch2026';
  }

  test('só permite submeter com o correio e a palavra-passe', () async {
    expect(controller.canSubmit, isFalse);
    expect(await controller.submit(), isFalse);
    expect(auth.loginRequests, isEmpty);

    fill();

    expect(controller.canSubmit, isTrue);
  });

  test('credenciais corretas iniciam a sessão (RF001)', () async {
    fill();

    final ok = await controller.submit();

    expect(ok, isTrue);
    expect(controller.status, LoadStatus.loaded);
    expect(auth.loginRequests.single.email, 'ana.ferreira@exemplo.pt');
    expect(session.status, SessionStatus.signedIn);
  });

  test(
    'palavra-passe errada mostra o motivo uniforme da API (RNF009)',
    () async {
      auth.onLogin = () => throw rejection('ERR-02', credentialsMessage);
      fill();

      final ok = await controller.submit();

      expect(ok, isFalse);
      expect(controller.status, LoadStatus.failed);
      expect(controller.errorMessage, credentialsMessage);
      expect(session.status, SessionStatus.signedOut);
    },
  );

  test('conta bloqueada mostra o motivo da API (RF001)', () async {
    auth.onLogin = () => throw rejection('ERR-03', blockedMessage);
    fill();

    await controller.submit();

    expect(controller.errorMessage, blockedMessage);
  });

  test('a falha de ligação é indicada (RNF014)', () async {
    auth.onLogin = () => throw const ConnectionFailure();
    fill();

    await controller.submit();

    expect(controller.errorMessage, connectionFailureMessage);
  });

  test('um erro inesperado mostra a mensagem genérica', () async {
    auth.onLogin = () => throw const UnexpectedFailure(500);
    fill();

    await controller.submit();

    expect(controller.errorMessage, unexpectedFailureMessage);
  });

  test('uma conta que não é de Candidato não inicia sessão', () async {
    auth.onLogin = () => candidateLogin(userType: UserType.admin);
    fill();

    final ok = await controller.submit();

    expect(ok, isFalse);
    expect(
      controller.errorMessage,
      'Esta conta não tem acesso por este ponto de acesso.',
    );
    expect(session.status, SessionStatus.signedOut);
  });
}
