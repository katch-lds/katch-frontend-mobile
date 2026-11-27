import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/app/katch_app.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_storage.dart';
import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'files.dart';

/// Tempo máximo de espera por um elemento que depende da API.
const apiWait = Duration(seconds: 20);

/// Aplicação completa arrancada no emulador, com as dependências reais e a API
/// real (plano de testes do frontend mobile, secção 4.3). Só o seletor de
/// ficheiros e o armazenamento da sessão são substituídos.
class TestApp {
  TestApp._(this.dependencies, this.picker, this.client);

  final AppDependencies dependencies;
  final QueuedFilePicker picker;
  final RecordingClient client;

  /// Toques e gestos feitos pelo teste (RNF010, RNF011).
  int interactions = 0;

  static Future<TestApp> start(
    WidgetTester tester, {
    String apiBaseUrl = KatchApi.baseUrl,
  }) async {
    final picker = QueuedFilePicker();
    final client = RecordingClient();
    final dependencies = AppDependencies.create(
      AppConfig(apiBaseUrl: apiBaseUrl),
      storage: MemorySessionStorage(),
      filePicker: picker,
      client: client,
    );
    WidgetsBinding.instance.addObserver(dependencies.lifecycle);
    addTearDown(
      () => WidgetsBinding.instance.removeObserver(dependencies.lifecycle),
    );
    await tester.pumpWidget(KatchApp(dependencies: dependencies));
    await dependencies.session.restore();
    await tester.pump();
    return TestApp._(dependencies, picker, client);
  }

  /// Espera que o elemento apareça, sem `pumpAndSettle` (os indicadores de
  /// carregamento animam enquanto a API responde).
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = apiWait,
  }) => waitForFinder(tester, finder, timeout: timeout);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await waitFor(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    interactions++;
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) =>
      tap(tester, find.byKey(Key(key)));

  Future<void> enter(WidgetTester tester, String key, String text) async {
    final finder = find.byKey(Key(key));
    await waitFor(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.enterText(finder.first, text);
    await tester.pump();
  }

  /// Escolhe uma opção de um `DropdownField`.
  Future<void> choose(WidgetTester tester, String key, String option) async {
    await tapKey(tester, key);
    await tester.pump(const Duration(milliseconds: 500));
    // O menu só constrói as opções visíveis: desloca-o até à opção pedida (por
    // exemplo, «Outro», a última da lista de competências).
    final options = find.text(option);
    if (options.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        options,
        300,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 100,
      );
    }
    // O menu aberto fica por cima: a opção é a última com o texto. Espera-se
    // primeiro por alguma, porque `.last` sem elementos lança uma exceção.
    await waitFor(tester, options);
    await tap(tester, options.last);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> login(WidgetTester tester, String email, String password) async {
    await enter(tester, 'login-email', email);
    await enter(tester, 'login-password', password);
    await tapKey(tester, 'login-submit');
  }

  /// Inicia sessão e espera pelo ecrã principal (barra de separadores).
  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await waitFor(tester, find.byKey(const Key('login-email')));
    await login(tester, email, password);
    await waitFor(tester, find.byType(NavigationBar));
    interactions = 0;
  }

  Future<void> openTab(WidgetTester tester, String label) => tap(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );

  /// Abre uma das entradas do separador «Perfil» (ficheiros, competências,
  /// preferências ou conta).
  Future<void> openFromProfile(WidgetTester tester, String key) async {
    await openTab(tester, 'Perfil');
    await waitFor(tester, find.byKey(const Key('profile-list')));
    await tapKey(tester, key);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.pageBack();
    interactions++;
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Identificador da vaga do cartão apresentado (chave `job-card-<jobId>`).
  String? currentCardId(WidgetTester tester) {
    final cards = find.byType(Dismissible).evaluate();
    for (final element in cards) {
      final key = element.widget.key;
      if (key is ValueKey<String> && key.value.startsWith('job-card-')) {
        return key.value.substring('job-card-'.length);
      }
    }
    return null;
  }

  /// Espera por um cartão diferente do indicado.
  Future<String> waitForNextCard(WidgetTester tester, String? previous) async {
    await waitUntil(tester, () {
      final id = currentCardId(tester);
      return id != null && id != previous;
    }, what: 'cartão seguinte');
    return currentCardId(tester)!;
  }
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = apiWait,
}) => waitUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  timeout: timeout,
  what: () => _describe(finder),
);

String _describe(Finder finder) {
  try {
    return finder.toString();
  } on StateError {
    // `find.…().last` sem elementos: a descrição também falha.
    return 'o último de ${finder.runtimeType}';
  }
}

/// Avança os fotogramas até a condição se verificar.
///
/// A descrição (`what`) só é calculada se o tempo se esgotar: a de um finder
/// como `find.text(…).last` falha enquanto não houver nenhum elemento.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = apiWait,
  required Object what,
}) async {
  final end = DateTime.now().add(timeout);
  while (true) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
    if (DateTime.now().isAfter(end)) {
      final description = what is String Function() ? what() : '$what';
      fail('Passaram ${timeout.inSeconds} s sem: $description');
    }
  }
}

/// Motivo de erro apresentado num campo de texto (`errorText`).
String? fieldError(WidgetTester tester, String key) {
  final field = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
    matchRoot: true,
  );
  return tester.widget<TextField>(field.first).decoration?.errorText;
}

/// Armazenamento da sessão em memória: cada teste começa sem sessão.
class MemorySessionStorage implements SessionStorage {
  Session? _saved;

  @override
  Future<Session?> read() async => _saved;

  @override
  Future<void> write(Session session) async => _saved = session;

  @override
  Future<void> clear() async => _saved = null;
}

/// Cliente HTTP da aplicação que guarda os cartões recebidos
/// (`GET /api/candidate/jobs/next`), para o teste confirmar os filtros das
/// preferências (RF014, RF015).
class RecordingClient extends http.BaseClient {
  final _inner = http.Client();

  final cards = <Map<String, Object?>>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final isCard =
        request.method == 'GET' &&
        request.url.path == '/api/candidate/jobs/next' &&
        response.statusCode == 200;
    if (!isCard) {
      return response;
    }
    final bytes = await response.stream.toBytes();
    final body = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    if (body is Map<String, Object?>) {
      cards.add(body);
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

extension CardNavigation on TestApp {
  /// Recusa os cartões que aparecem antes do de uma das vagas indicadas
  /// (vagas de outros cenários ou de execuções anteriores) e para nesse
  /// cartão, cujo identificador devolve.
  Future<String> showCard(WidgetTester tester, Set<String> jobIds) async {
    for (var i = 0; i < 40; i++) {
      await waitUntil(
        tester,
        () => currentCardId(tester) != null,
        what: 'cartão de uma das vagas $jobIds',
      );
      final id = currentCardId(tester)!;
      if (jobIds.contains(id)) {
        interactions = 0;
        return id;
      }
      await tapKey(tester, 'job-decline');
      await waitUntil(
        tester,
        () => currentCardId(tester) != id,
        what: 'cartão seguinte a $id',
      );
    }
    fail('Nenhuma das vagas $jobIds apareceu nos cartões.');
  }
}
