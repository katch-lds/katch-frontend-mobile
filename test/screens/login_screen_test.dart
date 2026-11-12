import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/screens/auth/login_screen.dart';
import 'package:katch_mobile/screens/auth/register_screen.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/state/failure_messages.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late TestApp app;

  setUp(() async {
    app = TestApp();
    await app.session.restore();
  });

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana.ferreira@exemplo.pt',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'katch2026',
    );
    await tester.pump();
  }

  FilledButton submitButton(WidgetTester tester) {
    return tester.widget<FilledButton>(find.byKey(const Key('login-submit')));
  }

  testWidgets('o botão «Entrar» só fica ativo com os dois campos', (
    tester,
  ) async {
    await pumpScreen(tester, app, const LoginScreen());

    expect(find.text('Katch'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);

    await fill(tester);

    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('inicia a sessão com credenciais corretas (RF001)', (
    tester,
  ) async {
    await pumpScreen(tester, app, const LoginScreen());
    await fill(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(app.auth.loginRequests.single.password, 'katch2026');
    expect(app.session.status, SessionStatus.signedIn);
  });

  testWidgets('mostra o motivo da API quando a palavra-passe está errada', (
    tester,
  ) async {
    app.auth.onLogin = () => throw rejection('ERR-02', credentialsMessage);
    await pumpScreen(tester, app, const LoginScreen());
    await fill(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text(credentialsMessage), findsOneWidget);
    expect(app.session.status, SessionStatus.signedOut);
  });

  testWidgets('mostra a falha de ligação na faixa e no formulário (RNF014)', (
    tester,
  ) async {
    app.auth.onLogin = () {
      app.monitor.reportFailure();
      throw const ConnectionFailure();
    };
    await pumpScreen(tester, app, const LoginScreen());
    await fill(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text(connectionFailureMessage), findsNWidgets(2));
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('indica que a sessão expirou', (tester) async {
    await pumpScreen(tester, app, const LoginScreen(sessionExpired: true));

    expect(find.text(LoginScreen.expiredMessage), findsOneWidget);
  });

  testWidgets('«Criar conta» abre o registo', (tester) async {
    await pumpScreen(tester, app, const LoginScreen());

    await tester.tap(find.byKey(const Key('login-register')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
