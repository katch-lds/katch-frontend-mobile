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

  test('o correio e a chamada usam mailto: e tel: (RF025)', () async {
    expect(
      PlatformExternalLauncher.emailUri(' recrutamento@lumen-exemplo.pt ')
          .toString(),
      'mailto:recrutamento@lumen-exemplo.pt',
    );
    expect(
      PlatformExternalLauncher.phoneUri('253 000 222').toString(),
      'tel:253000222',
    );
    // Nos testes não há plataforma: a aplicação externa não abre.
    expect(await launcher.openEmail('recrutamento@lumen-exemplo.pt'), isFalse);
    expect(await launcher.openPhone('253000222'), isFalse);
  });
}
