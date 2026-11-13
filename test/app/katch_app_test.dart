import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/app/home_shell.dart';
import 'package:katch_mobile/screens/account/account_screen.dart';
import 'package:katch_mobile/screens/auth/login_screen.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_status.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('mostra a espera enquanto restaura a sessão', (tester) async {
    final app = TestApp();

    await pumpKatchApp(tester, app);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('sem sessão guardada, mostra o início de sessão (M01)', (
    tester,
  ) async {
    final app = TestApp();
    await app.session.restore();

    await pumpKatchApp(tester, app);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('início de sessão abre a área do Candidato', (tester) async {
    final app = TestApp();
    await app.session.restore();
    await pumpKatchApp(tester, app);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana.ferreira@exemplo.pt',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'katch2026',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Explorar'), findsWidgets);
  });

  testWidgets(
    'terminar sessão volta ao início de sessão e fecha as áreas (RF105)',
    (tester) async {
      final app = TestApp(
        storage: MemorySessionStorage(
          Session.fromLoginResponse(candidateLogin()),
        ),
      );
      await app.session.restore();
      await pumpKatchApp(tester, app);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(app.dependencies.profile.profile, isNotNull);
      final account = find.byKey(const Key('profile-open-account'));
      await tester.ensureVisible(account);
      await tester.tap(account);
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('account-sign-out')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
      expect(find.byType(HomeShell), findsNothing);
      expect(app.session.accessToken, isNull);
      expect(app.dependencies.profile.profile, isNull);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    },
  );

  testWidgets('a sessão expirada volta ao início de sessão com o aviso', (
    tester,
  ) async {
    final app = TestApp();
    await app.session.start(candidateLogin());
    await pumpKatchApp(tester, app);
    expect(find.byType(HomeShell), findsOneWidget);

    await app.session.expire();
    await tester.pumpAndSettle();

    expect(app.session.status, SessionStatus.expired);
    expect(find.text(LoginScreen.expiredMessage), findsOneWidget);
  });

  testWidgets('os separadores ainda sem ecrã indicam a área por fazer', (
    tester,
  ) async {
    final app = TestApp();
    await app.session.start(candidateLogin());
    await pumpKatchApp(tester, app);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();

    expect(
      find.text('Esta área fica disponível numa próxima versão da aplicação.'),
      findsOneWidget,
    );
  });

  test('as dependências reais usam a API indicada na configuração', () async {
    final requests = <http.Request>[];
    final dependencies = AppDependencies.create(
      const AppConfig(
        apiBaseUrl: 'https://api.test',
        requestTimeout: Duration(seconds: 9),
      ),
      storage: MemorySessionStorage(),
      clock: FakeClock(),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '[{"id":"loc-1","name":"Braga (Braga)"}]',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await dependencies.referenceData.loadLocations();

    expect(
      requests.single.url.toString(),
      'https://api.test/api/reference-lists/locations',
    );
    expect(dependencies.referenceData.locations.single.name, 'Braga (Braga)');
    expect(dependencies.session.status, SessionStatus.restoring);
    expect(dependencies.config.apiBaseUrl, 'https://api.test');
  });
}
