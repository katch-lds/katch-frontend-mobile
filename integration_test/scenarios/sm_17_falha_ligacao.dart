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

      final stopwatch = Stopwatch()..start();
      await app.login(tester, 'sem.resposta@teste.katch.pt', 'Teste123a');
      await app.waitFor(
        tester,
        find.text(connectionFailureMessage),
        timeout: const Duration(seconds: 15),
      );
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThanOrEqualTo(const Duration(seconds: 10)),
        reason: '${stopwatch.elapsedMilliseconds} ms (RNF014)',
      );
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
