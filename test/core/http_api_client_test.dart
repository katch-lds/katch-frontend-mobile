import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/connection_monitor.dart';
import 'package:katch_mobile/core/http_api_client.dart';
import 'package:katch_mobile/session/session_manager.dart';

void main() {
  test('cria o cliente da API', () {
    final client = HttpApiClient(
      baseUrl: 'https://api.test',
      requestTimeout: const Duration(seconds: 9),
      credentials: SessionManager(),
      monitor: ConnectionMonitor(),
    );

    expect(client, isNotNull);
  });
}
