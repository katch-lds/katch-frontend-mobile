import '../core/url.dart';

/// Configuração por ambiente da aplicação, sem segredos.
///
/// Recebe o endereço da API por `--dart-define=API_BASE_URL=<url>` no build e
/// no `flutter run`; sem valor, usa a API local vista a partir do emulador
/// Android (10.0.2.2). Devolve, em [AppConfig.fromEnvironment], o endereço sem
/// a barra final e o tempo limite dos pedidos.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.requestTimeout});

  /// Configuração lida das definições de compilação.
  factory AppConfig.fromEnvironment() {
    return AppConfig(apiBaseUrl: trimSlash(_url), requestTimeout: _timeout);
  }

  static const _fallback = 'http://10.0.2.2:5180';
  static const _url = String.fromEnvironment('API_BASE_URL');
  static const _timeout = Duration(seconds: 9);

  /// Endereço base da API REST, sem a barra final.
  final String apiBaseUrl;

  /// Tempo limite de cada pedido: 9 segundos, abaixo dos 10 do RNF014.
  final Duration requestTimeout;

  /// Retira as barras finais; sem valor, usa a API local do emulador.
  static String trimSlash(String url) {
    final value = url.isEmpty ? _fallback : url;
    return trimTrailingSlashes(value);
  }
}
