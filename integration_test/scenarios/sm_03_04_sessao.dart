import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/screens/account/change_password_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/api.dart';
import '../support/harness.dart';

const _invalidCredentials =
    'O endereço de correio eletrónico ou a palavra-passe estão incorretos.';

/// SM-03 e SM-04 — Sessão e palavra-passe (RF001, RF002, RF105).
void sessaoScenarios() {
  group('SM-03 Início e fim de sessão', () {
    testWidgets('SM-03a credenciais corretas iniciam sessão e terminar sessão '
        'volta ao início de sessão', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm03');
      final app = await TestApp.start(tester);

      await app.signIn(tester, candidate.email, candidate.password);
      await app.openFromProfile(tester, 'profile-open-account');
      await app.tapKey(tester, 'account-sign-out');

      await app.waitFor(tester, find.byKey(const Key('login-email')));
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('SM-03b palavra-passe errada e conta bloqueada mostram o '
        'motivo', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm03');
      final app = await TestApp.start(tester);

      await app.waitFor(tester, find.byKey(const Key('login-email')));
      await app.login(tester, candidate.email, 'Errada${candidate.password}');
      await app.waitFor(tester, find.text(_invalidCredentials));
      expect(find.byType(NavigationBar), findsNothing);

      // Bloqueio da conta por pedido direto do Administrador.
      final admin = await KatchApi.admin();
      await admin.post(
        '/api/admin/accounts/${candidate.session.userId}/block',
        null,
        'bloquear conta',
      );
      await app.login(tester, candidate.email, candidate.password);
      await app.waitFor(tester, find.text('A conta está bloqueada.'));
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('SM-04 Alteração da própria palavra-passe', () {
    testWidgets('SM-04a a palavra-passe atual errada é recusada; a nova fica '
        'válida para iniciar sessão', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm04');
      final newPassword = KatchApi.newPassword();
      final app = await TestApp.start(tester);

      await app.signIn(tester, candidate.email, candidate.password);
      await app.openFromProfile(tester, 'profile-open-account');
      await app.tapKey(tester, 'account-change-password');

      await app.enter(
        tester,
        'password-current',
        'Errada1${candidate.password}',
      );
      await app.enter(tester, 'password-new', newPassword);
      await app.enter(tester, 'password-confirmation', newPassword);
      await app.tapKey(tester, 'password-submit');
      const wrong = 'A palavra-passe atual está errada.';
      await app.waitFor(tester, find.text(wrong));
      expect(fieldError(tester, 'password-current'), wrong);

      await app.enter(tester, 'password-current', candidate.password);
      await app.tapKey(tester, 'password-submit');
      await app.waitFor(tester, find.text(ChangePasswordScreen.successMessage));

      // Com a palavra-passe nova, a sessão inicia; a antiga deixa de servir.
      await app.waitFor(tester, find.byKey(const Key('account-sign-out')));
      await app.tapKey(tester, 'account-sign-out');
      await app.waitFor(tester, find.byKey(const Key('login-email')));
      await app.login(tester, candidate.email, candidate.password);
      await app.waitFor(tester, find.text(_invalidCredentials));
      await app.login(tester, candidate.email, newPassword);
      await app.waitFor(tester, find.byType(NavigationBar));
    });
  });
}
