import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_config.dart';

void main() {
  test('retira a barra final e usa a API local sem valor', () {
    expect(AppConfig.trimSlash('https://api.test//'), 'https://api.test');
    expect(AppConfig.trimSlash(''), 'http://10.0.2.2:5180');
  });

  test('a configuração por omissão tem o tempo limite de 9 segundos', () {
    final config = AppConfig.fromEnvironment();

    expect(config.requestTimeout, const Duration(seconds: 9));
    expect(config.apiBaseUrl, 'http://10.0.2.2:5180');
  });
}
