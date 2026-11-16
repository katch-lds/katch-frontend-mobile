import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/screens/auth/register_screen.dart';
import 'package:katch_mobile/screens/auth/register_success_screen.dart';
import 'package:katch_mobile/session/session_status.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late TestApp app;

  setUp(() async {
    app = TestApp();
    await app.session.restore();
  });

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('register-full-name')),
      'Ana Ferreira',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'ana.ferreira@exemplo.pt',
    );
    await tester.enterText(
      find.byKey(const Key('register-phone')),
      '912345678',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'katch2026',
    );
    await tester.tap(find.byKey(const Key('register-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(felgueiras.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-accept-terms')));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byKey(const Key('register-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('apresenta a lista de localidades obtida da API', (tester) async {
    await pumpScreen(tester, app, const RegisterScreen());

    await tester.tap(find.byKey(const Key('register-location')));
    await tester.pumpAndSettle();

    expect(find.text(braga.name), findsWidgets);
    expect(find.text(felgueiras.name), findsWidgets);
    expect(app.referenceLists.locationCalls, 1);
  });

  testWidgets('indica cada campo em falta antes de enviar (RF004)', (
    tester,
  ) async {
    await pumpScreen(tester, app, const RegisterScreen());

    await submit(tester);

    expect(find.text(InputRules.requiredReason), findsNWidgets(5));
    expect(find.text(InputRules.acceptTermsReason), findsOneWidget);
    expect(app.auth.registerRequests, isEmpty);
  });

  testWidgets('o registo válido confirma a ativação da conta (RF005)', (
    tester,
  ) async {
    await pumpScreen(tester, app, const RegisterScreen());
    await fillValid(tester);

    await submit(tester);

    expect(app.auth.registerRequests.single.locationId, felgueiras.id);
    expect(find.byType(RegisterSuccessScreen), findsOneWidget);
    expect(find.text('A sua conta está ativa'), findsOneWidget);
    expect(app.session.status, SessionStatus.signedIn);
  });

  testWidgets('mostra o campo e o motivo devolvidos pela API (RF004)', (
    tester,
  ) async {
    const taken = 'O endereço de correio eletrónico já está registado.';
    app.auth.onRegister = () =>
        throw rejection('ERR-10', validationMessage, {'email': taken});
    await pumpScreen(tester, app, const RegisterScreen());
    await fillValid(tester);

    await submit(tester);

    expect(find.text(taken), findsOneWidget);
    expect(find.text(validationMessage), findsOneWidget);
    expect(find.byType(RegisterSuccessScreen), findsNothing);
  });

  testWidgets('sem localidades, permite voltar a pedir a lista', (
    tester,
  ) async {
    app.referenceLists.locationAnswers.add(
      () => throw const ConnectionFailure(),
    );
    await pumpScreen(tester, app, const RegisterScreen());
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível obter as localidades.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('register-locations-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-location')), findsOneWidget);
    expect(app.referenceLists.locationCalls, 2);
  });
}
