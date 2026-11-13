import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/connection_monitor.dart';
import 'package:katch_mobile/core/http_api_client.dart';
import 'package:katch_mobile/models/file_selection.dart';
import 'package:katch_mobile/session/session_manager.dart';

import '../support/fakes.dart';

http.Response jsonResponse(int status, Object? body) {
  final headers = {'content-type': 'application/json; charset=utf-8'};
  return http.Response(jsonEncode(body), status, headers: headers);
}

Map<String, Object?> apiError(String code) {
  return {'code': code, 'message': 'Motivo', 'fields': <Object?>[]};
}

void main() {
  late SessionManager session;
  late ConnectionMonitor monitor;
  late List<http.Request> requests;

  HttpApiClient clientFor(http.Response Function(http.Request) handler) {
    return HttpApiClient(
      baseUrl: 'https://api.test/',
      requestTimeout: const Duration(milliseconds: 100),
      credentials: session,
      monitor: monitor,
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  setUp(() {
    session = SessionManager(
      storage: MemorySessionStorage(),
      clock: FakeClock(),
    );
    monitor = ConnectionMonitor();
    requests = [];
  });

  test('envia X-Client-App e a credencial e devolve o JSON', () async {
    await session.start(candidateLogin(token: 'abc'));
    final client = clientFor((_) => jsonResponse(200, {'id': 1}));

    final result = await client.get('/api/candidate/profile');

    expect(result, {'id': 1});
    final request = requests.single;
    expect(request.url.toString(), 'https://api.test/api/candidate/profile');
    expect(request.headers['X-Client-App'], 'mobile');
    expect(request.headers['Authorization'], 'Bearer abc');
  });

  test('envia o corpo em JSON sem credencial e aceita 204', () async {
    final client = clientFor((_) => http.Response('', 204));

    final result = await client.post('/api/auth/login', {'email': 'a@b.pt'});
    await client.put('/api/x', {'a': 1});
    await client.delete('/api/x');

    expect(result, isNull);
    expect(requests.first.body, '{"email":"a@b.pt"}');
    expect(requests.first.headers['Authorization'], isNull);
    final methods = requests.map((r) => r.method).toList();
    expect(methods, ['POST', 'PUT', 'DELETE']);
  });

  test('converte uma rejeição em ApiRejection com o code', () async {
    await session.start(candidateLogin(token: 'abc'));
    final client = clientFor((_) => jsonResponse(409, apiError('ERR-30')));

    ApiRejection? rejection;
    try {
      await client.post('/api/candidate/interests');
    } on ApiRejection catch (e) {
      rejection = e;
    }

    expect(rejection?.error.code, 'ERR-30');
    expect(session.isAuthenticated, isTrue);
  });

  test('termina a sessão quando a credencial é recusada', () async {
    await session.start(candidateLogin(token: 'abc'));
    final client = clientFor((_) => jsonResponse(403, apiError('ERR-04')));

    final call = client.get('/api/candidate/profile');

    await expectLater(call, throwsA(isA<AuthenticationFailure>()));
    expect(session.isAuthenticated, isFalse);
  });

  test('no início de sessão, a recusa chega como ApiRejection', () async {
    final client = clientFor((_) => jsonResponse(401, apiError('ERR-02')));

    final call = client.post(HttpApiClient.loginPath, {'email': 'a@b.pt'});

    await expectLater(call, throwsA(isA<ApiRejection>()));
  });

  test('erro do servidor ou sem ApiErrorDto é UnexpectedFailure', () async {
    final client = clientFor((_) => http.Response('<html></html>', 502));

    final call = client.get('/api/x');

    await expectLater(call, throwsA(isA<UnexpectedFailure>()));
  });

  test('sem resposta no tempo limite, regista a falha de ligação', () async {
    final client = HttpApiClient(
      baseUrl: 'https://api.test',
      requestTimeout: const Duration(milliseconds: 10),
      credentials: session,
      monitor: monitor,
      client: MockClient((_) => Completer<http.Response>().future),
    );

    final call = client.get('/api/x');

    await expectLater(call, throwsA(isA<ConnectionFailure>()));
    expect(monitor.hasFailure, isTrue);
  });

  test('regista o método, a rota e o código, sem a credencial', () async {
    await session.start(candidateLogin(token: 'segredo'));
    final messages = <String>[];
    final client = HttpApiClient(
      baseUrl: 'https://api.test',
      requestTimeout: const Duration(milliseconds: 10),
      credentials: session,
      monitor: monitor,
      log: messages.add,
      client: MockClient((request) async {
        if (request.url.path == '/api/x') {
          return jsonResponse(200, {'ok': true});
        }
        if (request.url.path == '/api/lenta') {
          return Completer<http.Response>().future;
        }
        return jsonResponse(409, apiError('ERR-30'));
      }),
    );

    await client.get('/api/x');
    await expectLater(client.post('/api/y'), throwsA(isA<ApiRejection>()));
    await expectLater(
      client.get('/api/lenta'),
      throwsA(isA<ConnectionFailure>()),
    );

    expect(messages, [
      'GET /api/x -> 200',
      'POST /api/y -> 409 ERR-30',
      'GET /api/lenta -> sem resposta (falha de ligação)',
    ]);
    expect(messages.join(), isNot(contains('segredo')));
  });

  group('upload (API v02, 2.6)', () {
    late List<http.BaseRequest> sent;
    late List<String> bodies;

    HttpApiClient uploadClient(int status, [Object? body]) {
      return HttpApiClient(
        baseUrl: 'https://api.test',
        requestTimeout: const Duration(seconds: 1),
        credentials: session,
        monitor: monitor,
        client: _RecordingClient((request, body0) {
          sent.add(request);
          bodies.add(body0);
          final text = body == null ? '' : jsonEncode(body);
          return http.StreamedResponse(
            Stream.value(utf8.encode(text)),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    }

    setUp(() {
      sent = [];
      bodies = [];
    });

    test('envia o ficheiro em memória no campo file, com PUT', () async {
      await session.start(candidateLogin(token: 'abc'));
      final client = uploadClient(204);

      await client.upload(
        '/api/candidate/profile/cv',
        FileSelection.fromBytes('cv.pdf', '%PDF-1.4'.codeUnits),
      );

      final request = sent.single;
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/candidate/profile/cv');
      expect(request.headers['Authorization'], 'Bearer abc');
      expect(request.headers['X-Client-App'], 'mobile');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(bodies.single, contains('name="file"; filename="cv.pdf"'));
      expect(bodies.single, contains('%PDF-1.4'));
    });

    test('envia o ficheiro a partir do caminho local', () async {
      final dir = await Directory.systemTemp.createTemp('katch-upload');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/foto.png');
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);
      final client = uploadClient(204);

      await client.upload(
        '/api/candidate/profile/photo',
        FileSelection(name: 'foto.png', sizeBytes: 4, path: file.path),
      );

      expect(bodies.single, contains('filename="foto.png"'));
    });

    test('um ficheiro local que deixou de existir é erro inesperado', () async {
      final client = uploadClient(204);

      final call = client.upload(
        '/api/candidate/profile/photo',
        const FileSelection(
          name: 'x.png',
          sizeBytes: 1,
          path: '/nao/existe/x.png',
        ),
      );

      await expectLater(call, throwsA(isA<UnexpectedFailure>()));
      expect(sent, isEmpty);
    });

    test('a rejeição do ficheiro chega como ApiRejection (ERR-11)', () async {
      await session.start(candidateLogin(token: 'abc'));
      final client = uploadClient(400, {
        'code': 'ERR-11',
        'message': 'O ficheiro não é aceite.',
        'fields': [
          {'field': 'file', 'reason': 'O ficheiro excede 5 MB.'},
        ],
      });

      final call = client.upload(
        '/api/candidate/profile/photo',
        FileSelection.fromBytes('a.jpg', [0xFF, 0xD8, 0xFF]),
      );

      await expectLater(
        call,
        throwsA(
          isA<ApiRejection>().having(
            (e) => e.error.reasonFor('file'),
            'reason',
            'O ficheiro excede 5 MB.',
          ),
        ),
      );
    });
  });
}

/// Cliente HTTP que regista o pedido e o corpo enviado (incluindo os pedidos
/// `multipart`, que o `MockClient` não expõe como texto).
class _RecordingClient extends http.BaseClient {
  _RecordingClient(this._handler);

  final http.StreamedResponse Function(http.BaseRequest request, String body)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    return _handler(request, latin1.decode(bytes));
  }
}
