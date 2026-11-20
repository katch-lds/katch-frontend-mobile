import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_config.dart';

void main() {
  test('sem API_BASE_URL, usa a API local do emulador', () {
    expect(AppConfig.fromEnvironment().apiBaseUrl, 'http://10.0.2.2:5180');
  });

  test('os tempos limite por omissão são 9 e 60 segundos', () {
    final config = AppConfig.fromEnvironment();

    expect(config.requestTimeout, const Duration(seconds: 9));
    expect(config.uploadTimeout, const Duration(seconds: 60));
  });
}
