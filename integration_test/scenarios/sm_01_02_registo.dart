import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:material_ui/material_ui.dart';

import '../support/api.dart';
import '../support/harness.dart';

/// SM-01 e SM-02 — Registo do Candidato (RF003 a RF005).
void registoScenarios() {
  group('SM-01 Registo e ativação imediata', () {
    testWidgets(
      'SM-01a o registo válido ativa a conta e permite iniciar sessão '
      'de imediato',
      (tester) async {
        final app = await TestApp.start(tester);
        final email = '${KatchApi.unique('sm01')}@teste.katch.pt';
        final password = KatchApi.newPassword();

        await app.tapKey(tester, 'login-register');
        await app.enter(tester, 'register-full-name', 'Ana Ferreira Teste');
        await app.enter(tester, 'register-email', email);
        await app.enter(tester, 'register-phone', KatchApi.newPhone());
        await app.choose(tester, 'register-location', Locations.bragancaName);
        await app.enter(tester, 'register-password', password);
        await app.tapKey(tester, 'register-accept-terms');
        await app.tapKey(tester, 'register-submit');

        await app.waitFor(tester, find.text('A sua conta está ativa'));
        await app.tapKey(tester, 'register-start');
        await app.waitFor(tester, find.byType(NavigationBar));

        // A conta fica ativa: termina a sessão e volta a entrar com os dados do
        // registo.
        await app.openFromProfile(tester, 'profile-open-account');
        await app.tapKey(tester, 'account-sign-out');
        await app.signIn(tester, email, password);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );
  });

  group('SM-02 Registo rejeitado', () {
    testWidgets(
      'SM-02a telefone com 8 algarismos, localidade por preencher e '
      'correio eletrónico já registado são recusados com o campo e o motivo',
      (tester) async {
        final existing = await KatchApi.createCandidate(prefix: 'sm02');
        final app = await TestApp.start(tester);

        await app.tapKey(tester, 'login-register');
        await app.enter(tester, 'register-full-name', 'Rui Teixeira Teste');
        await app.enter(tester, 'register-email', existing.email);
        await app.enter(tester, 'register-phone', '91234567');
        await app.enter(tester, 'register-password', KatchApi.newPassword());
        await app.tapKey(tester, 'register-accept-terms');
        await app.tapKey(tester, 'register-submit');

        // Validação na aplicação, antes do pedido (RF004).
        await app.waitFor(tester, find.text(InputRules.phoneReason));
        expect(fieldError(tester, 'register-phone'), InputRules.phoneReason);
        expect(find.text(InputRules.requiredReason), findsOneWidget);

        // Corrigidos o telefone e a localidade, a API recusa o correio
        // eletrónico já registado, indicado no próprio campo.
        await app.enter(tester, 'register-phone', KatchApi.newPhone());
        await app.choose(tester, 'register-location', Locations.bragancaName);
        await app.tapKey(tester, 'register-submit');

        const taken = 'O endereço de correio eletrónico já está registado.';
        await app.waitFor(tester, find.text(taken));
        expect(fieldError(tester, 'register-email'), taken);
        expect(find.text('A sua conta está ativa'), findsNothing);
      },
    );
  });
}
