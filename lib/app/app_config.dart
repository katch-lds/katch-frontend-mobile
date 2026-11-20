import '../core/url.dart';

/// Configuração por ambiente da aplicação, sem segredos.
///
/// Recebe o endereço da API por `--dart-define=API_BASE_URL=<url>` no build e
/// no `flutter run`; sem valor, usa a API local vista a partir do emulador
/// Android (10.0.2.2). Devolve, em [AppConfig.fromEnvironment], o endereço sem
/// a barra final e os tempos limite dos pedidos.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.requestTimeout = defaultRequestTimeout,
    this.uploadTimeout = defaultUploadTimeout,
  });

  /// Configuração lida das definições de compilação.
  factory AppConfig.fromEnvironment() {
    return AppConfig(apiBaseUrl: _baseUrl(_url));
  }

  static const _fallback = 'http://10.0.2.2:5180';
  static const _url = String.fromEnvironment('API_BASE_URL');

  /// Tempo limite de cada pedido: 9 segundos, abaixo dos 10 do RNF014.
  static const defaultRequestTimeout = Duration(seconds: 9);

  /// Tempo limite do envio de um ficheiro (fotografia ou curriculum vitae,
  /// até 5 MiB): o envio inteiro numa ligação móvel lenta pode passar os 9 s
  /// dos restantes pedidos (RNF014). Uma ligação recusada falha logo.
  static const defaultUploadTimeout = Duration(seconds: 60);

  /// Endereço base da API REST, sem a barra final.
  final String apiBaseUrl;

  final Duration requestTimeout;

  final Duration uploadTimeout;

  /// Retira as barras finais; sem valor, usa a API local do emulador.
  static String _baseUrl(String url) {
    return trimTrailingSlashes(url.isEmpty ? _fallback : url);
  }
}
