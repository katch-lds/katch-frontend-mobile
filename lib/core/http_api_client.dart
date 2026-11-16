import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_error_dto.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'connection_monitor.dart';
import 'credential_provider.dart';
import 'url.dart';

/// Cliente da API v02 sobre HTTPS e JSON (modelo de classes, secção 4.1).
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required String baseUrl,
    required Duration requestTimeout,
    required CredentialProvider credentials,
    required ConnectionMonitor monitor,
    http.Client? client,
    void Function(String message)? log,
  }) : _baseUrl = trimTrailingSlashes(baseUrl),
       _requestTimeout = requestTimeout,
       _credentials = credentials,
       _monitor = monitor,
       _client = client ?? http.Client(),
       _log = log;

  /// Valor do cabeçalho `X-Client-App` da aplicação móvel (API v02, 3.2).
  static const clientApp = 'mobile';

  /// Pedido de início de sessão, cujos erros chegam como `ApiRejection`.
  static const loginPath = '/api/auth/login';

  final String _baseUrl;
  final Duration _requestTimeout;
  final CredentialProvider _credentials;
  final ConnectionMonitor _monitor;
  final http.Client _client;

  /// Registo de cada pedido (método, rota, código e `code` do erro), só na
  /// variante de depuração. Nunca inclui a credencial nem o corpo do pedido.
  final void Function(String message)? _log;

  @override
  Future<Object?> get(String path) => _send('GET', path);

  @override
  Future<Object?> post(String path, [Object? body]) {
    return _send('POST', path, body);
  }

  @override
  Future<Object?> put(String path, [Object? body]) {
    return _send('PUT', path, body);
  }

  @override
  Future<void> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers.addAll(_headers());
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on Exception {
      _monitor.reportFailure();
      _log?.call('$method $path -> sem resposta (falha de ligação)');
      throw const ConnectionFailure();
    }
    _monitor.reportSuccess();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _log?.call('$method $path -> ${response.statusCode}');
      return response.body.isEmpty ? null : jsonDecode(response.body);
    }
    final failure = _toException(path, response);
    final code = failure is ApiRejection ? ' ${failure.error.code}' : '';
    _log?.call('$method $path -> ${response.statusCode}$code');
    throw failure;
  }

  Map<String, String> _headers() {
    final headers = {'Accept': 'application/json', 'X-Client-App': clientApp};
    final token = _credentials.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  ApiException _toException(String path, http.Response response) {
    final status = response.statusCode;
    final error = ApiErrorDto.tryParse(_decode(response.body));
    if (status >= 500 || error == null) {
      return UnexpectedFailure(status);
    }
    final reserved = path != loginPath && _credentials.accessToken != null;
    final blocked = error.code == 'ERR-03' || error.code == 'ERR-04';
    if (reserved && (status == 401 || blocked)) {
      _credentials.rejectCredential();
      return AuthenticationFailure(error.message);
    }
    return ApiRejection(error);
  }

  static Object? _decode(String body) {
    try {
      return body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
