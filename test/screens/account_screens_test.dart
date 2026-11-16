import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/screens/account/account_screen.dart';
import 'package:katch_mobile/screens/account/change_password_screen.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/state/change_password_controller.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late TestApp app;

  setUp(() async {
    app = TestApp();
    await app.session.start(candidateLogin());
  });

  Future<void> fillPasswords(
    WidgetTester tester, {
    String current = 'katch2026',
    String next = 'katch2027',
    String? confirmation,
  }) async {
    await tester.enterText(find.byKey(const Key('password-current')), current);
    await tester.enterText(find.byKey(const Key('password-new')), next);
    await tester.enterText(
      find.byKey(const Key('password-confirmation')),
      confirmation ?? next,
    );
  }

  testWidgets('«Terminar sessão» termina a sessão (RF105)', (tester) async {
    await pumpScreen(tester, app, const AccountScreen());

    await tester.tap(find.byKey(const Key('account-sign-out')));
    await tester.pumpAndSettle();

    expect(app.auth.logouts, 1);
    expect(app.session.status, SessionStatus.signedOut);
  });

  testWidgets('«Alterar palavra-passe» abre o ecrã M21', (tester) async {
    await pumpScreen(tester, app, const AccountScreen());

    await tester.tap(find.byKey(const Key('account-change-password')));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('altera a palavra-passe e confirma (RF002)', (tester) async {
    await pumpScreen(tester, app, const AccountScreen());
    await tester.tap(find.byKey(const Key('account-change-password')));
    await tester.pumpAndSettle();
    await fillPasswords(tester);

    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pumpAndSettle();

    expect(app.auth.passwordRequests.single.newPassword, 'katch2027');
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text(ChangePasswordScreen.successMessage), findsOneWidget);
  });

  testWidgets('rejeita a nova palavra-passe fora do P05', (tester) async {
    await pumpScreen(tester, app, const ChangePasswordScreen());
    await fillPasswords(tester, next: 'katch');

    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pump();

    expect(find.text(InputRules.passwordReason), findsOneWidget);
    expect(app.auth.passwordRequests, isEmpty);
  });

  testWidgets('mostra a palavra-passe atual errada no campo (RF002)', (
    tester,
  ) async {
    const wrong = 'A palavra-passe atual está errada.';
    app.auth.onChangePassword = () => throw rejection(
      'ERR-10',
      validationMessage,
      {'currentPassword': wrong},
    );
    await pumpScreen(tester, app, const ChangePasswordScreen());
    await fillPasswords(tester, current: 'errada2026');

    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pump();

    expect(find.text(wrong), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('indica a confirmação diferente da palavra-passe nova', (
    tester,
  ) async {
    await pumpScreen(tester, app, const ChangePasswordScreen());
    await fillPasswords(tester, confirmation: 'katch2028');

    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pump();

    expect(
      find.text(ChangePasswordController.confirmationReason),
      findsOneWidget,
    );
  });
}
