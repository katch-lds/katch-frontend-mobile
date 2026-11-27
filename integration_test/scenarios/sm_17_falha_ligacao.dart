import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

/// Endereço sem resposta: rede reservada que não encaminha pedidos, para o
/// pedido ficar sem resposta até ao limite de tempo do cliente (9 s, RNF014).
const _silentApi = 'http://10.255.255.1:5180';

/// SM-17 — Falha de ligação (RNF014).
void falhaLigacaoScenarios() {
  group('SM-17 Falha de ligação', () {
    testWidgets('SM-17a com a API sem resposta, a falha de ligação é indicada '
        'em 10 segundos, no máximo', (tester) async {
      final app = await TestApp.start(tester, apiBaseUrl: _silentApi);
      await app.waitFor(tester, find.byKey(const Key('login-email')));

      await app.enter(tester, 'login-email', 'sem.resposta@teste.katch.pt');
      await app.enter(tester, 'login-password', 'Teste123a');

      // O tempo conta a partir do toque em «Entrar» (RNF014).
      const limit = Duration(seconds: 10);
      final stopwatch = await app.tapKeyTimed(tester, 'login-submit');
      await app.waitFor(
        tester,
        find.text(connectionFailureMessage),
        timeout: const Duration(seconds: 15),
      );
      stopwatch.stop();
      reportTime('SM-17a', stopwatch.elapsed, limit);
      expect(
        stopwatch.elapsed,
        lessThanOrEqualTo(limit),
        reason: '${stopwatch.elapsedMilliseconds} ms (RNF014)',
      );
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
