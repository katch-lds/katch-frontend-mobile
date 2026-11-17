import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/platform_external_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launcher = PlatformExternalLauncher();

  test('só abre endereços http e https (P10)', () async {
    expect(await launcher.openUrl('ftp://exemplo.pt/ficheiro'), isFalse);
    expect(await launcher.openUrl('javascript:alert(1)'), isFalse);
    expect(await launcher.openUrl('::'), isFalse);
  });

  test('sem navegador disponível devolve false, sem exceção', () async {
    // Nos testes não há plataforma: o pedido ao navegador falha.
    expect(await launcher.openUrl('https://www.lumen-exemplo.pt'), isFalse);
  });
}
