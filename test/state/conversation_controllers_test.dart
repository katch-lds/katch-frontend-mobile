import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/conversation_summary_dto.dart';
import 'package:katch_mobile/models/match_dto.dart';
import 'package:katch_mobile/polling/app_lifecycle_monitor.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/state/chat_controller.dart';
import 'package:katch_mobile/state/conversations_store.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/matches_controller.dart';

import '../support/conversation_fakes.dart';
import '../support/exploration_fakes.dart';
import '../support/fakes.dart';

int _count(FakeConversationService service, String name) =>
    service.calls.where((call) => call == name).length;

void main() {
  late SessionManager session;
  late AppLifecycleMonitor lifecycle;
  late FakeConversationService service;
  late ConversationsStore store;

  setUp(() async {
    session = SessionManager(storage: MemorySessionStorage(), clock: FakeClock());
    await session.start(candidateLogin());
    lifecycle = AppLifecycleMonitor();
    service = FakeConversationService();
    store = ConversationsStore(
      service: service,
      session: session,
      lifecycle: lifecycle,
    );
  });

  group('MatchesController', () {
    late FakeMatchService matches;
    late FakeLauncher launcher;
    late MatchesController controller;

    setUp(() {
      matches = FakeMatchService();
      launcher = FakeLauncher();
      controller = MatchesController(service: matches, launcher: launcher);
    });

    test('pede os matches com a vaga, a Empresa e os contactos (RF024)',
        () async {
      matches.matches = [
        sampleMatch(),
        sampleMatch(matchId: matchB, jobStatus: JobStatus.closed),
      ];

      await controller.load();

      expect(controller.status, LoadStatus.loaded);
      expect(controller.matches, hasLength(2));
      expect(controller.find(matchB)?.isJobClosed, isTrue);
      expect(controller.find('outro'), isNull);
      expect(controller.message, isNull);
    });

    test('sem ligação, a falha é indicada e a lista anterior mantém-se '
        '(RNF014)', () async {
      matches.failure = () => const ConnectionFailure();
      await controller.load();
      expect(controller.status, LoadStatus.failed);
      expect(controller.message, failureMessage(const ConnectionFailure()));

      matches.failure = null;
      await controller.load();
      matches.failure = () => const ConnectionFailure();
      await controller.load();
      expect(controller.status, LoadStatus.loaded);
      expect(controller.matches, hasLength(1));
      expect(controller.message, isNotNull);
    });

    test('o correio e a chamada abrem as aplicações do dispositivo (RF025)',
        () async {
      await controller.load();
      final match = controller.matches.single;

      await controller.openEmail(match);
      await controller.openPhone(match);
      expect(launcher.emails, ['rita.lopes@atlantico.pt']);
      expect(launcher.phones, ['912 345 678']);
      expect(controller.message, isNull);

      launcher.opens = false;
      await controller.openEmail(match);
      expect(controller.message, MatchesController.emailFailedMessage);
      await controller.openPhone(match);
      expect(controller.message, MatchesController.phoneFailedMessage);
    });

    test('depois de descartado, a resposta não notifica', () async {
      final pending = controller.load();
      controller.dispose();
      await pending;
    });
  });

  group('ConversationsStore', () {
    test('soma as mensagens por ler e encontra a conversa do match (RF027)',
        () async {
      service.conversations = [
        sampleConversation(unreadCount: 2),
        sampleConversation(matchId: matchB, unreadCount: 3),
      ];

      await store.load();

      expect(store.status, LoadStatus.loaded);
      expect(store.unreadMessages, 5);
      expect(store.find(matchB)?.unreadCount, 3);
      expect(store.find('outro'), isNull);
    });

    test('a falha sem lista mostra o erro; com lista, mantém-na', () async {
      service.failures['list'] = () => const ConnectionFailure();
      await store.load();
      expect(store.status, LoadStatus.failed);
      expect(store.message, isNotNull);

      service.failures.clear();
      await store.load();
      service.failures['list'] = () => const ConnectionFailure();
      await store.load();
      expect(store.status, LoadStatus.loaded);
      expect(store.conversations, hasLength(1));
      expect(store.message, isNotNull);
    });

    test('o fim de sessão esvazia a lista e para a consulta (RF105)',
        () async {
      await store.load();
      store.watchList(true);
      expect(store.isPolling, isTrue);

      await session.end();

      expect(store.conversations, isEmpty);
      expect(store.status, LoadStatus.idle);
      expect(store.isPolling, isFalse);
    });

    test('replace substitui a lista pela da conversa aberta', () {
      store.replace([sampleConversation(unreadCount: 4)]);

      expect(store.unreadMessages, 4);
      expect(store.status, LoadStatus.loaded);
    });

    test('com M16 apresentado, consulta de 3 em 3 segundos e só em primeiro '
        'plano (RF029)', () {
      fakeAsync((async) {
        store.watchList(true);
        async.elapse(Duration.zero);
        expect(_count(service, 'list'), 1);

        async.elapse(const Duration(seconds: 3));
        expect(_count(service, 'list'), 2);
        async.elapse(const Duration(seconds: 3));
        expect(_count(service, 'list'), 3);

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(store.isPolling, isFalse);
        async.elapse(const Duration(seconds: 9));
        expect(_count(service, 'list'), 3);

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(Duration.zero);
        expect(_count(service, 'list'), 4);

        store.watchList(false);
        async.elapse(const Duration(seconds: 9));
        expect(_count(service, 'list'), 4);
        store.dispose();
      });
    });

    test('fora de M16, pede a lista ao voltar ao primeiro plano (contador)',
        () async {
      await store.load();

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(_count(service, 'list'), 2);
      expect(store.isPolling, isFalse);
    });
  });

  group('ChatController', () {
    late ChatController controller;
    final t0 = DateTime.utc(2026, 11, 12, 9);

    setUp(() {
      controller = ChatController(
        service: service,
        store: store,
        session: session,
        lifecycle: lifecycle,
      );
      service.receive(
        matchA,
        sampleMessage('r-1', content: 'Olá, João', sentAt: t0),
      );
      service.messages[matchA]!.add(
        sampleMessage(
          'c-1',
          senderId: candidateId,
          content: 'Bom dia',
          sentAt: t0.add(const Duration(minutes: 1)),
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('abre a conversa com o histórico ordenado e o resumo (RF028, RF068)',
        () async {
      await controller.open(matchA);

      expect(controller.status, LoadStatus.loaded);
      expect(controller.matchId, matchA);
      expect(controller.summary?.companyName, 'Atlântico Digital');
      expect(controller.messages.map((m) => m.messageId), ['r-1', 'c-1']);
      expect(controller.isOwn(controller.messages.first), isFalse);
      expect(controller.isOwn(controller.messages.last), isTrue);
      expect(controller.isReadOnly, isFalse);
      expect(controller.isPolling, isTrue);
      expect(service.calls.take(2), ['list', 'open']);
    });

    test('a falha ao abrir é indicada (RNF014)', () async {
      service.failures['open'] = () => const ConnectionFailure();

      await controller.open(matchA);

      expect(controller.status, LoadStatus.failed);
      expect(controller.errorMessage, isNotNull);
      expect(controller.isPolling, isFalse);
    });

    test('só envia texto de 1 a 1000 caracteres, não só espaços (P03; RF026)',
        () async {
      await controller.open(matchA);

      controller.updateDraft('   ');
      expect(controller.canSend, isFalse);
      controller.updateDraft('x' * 1001);
      expect(controller.canSend, isFalse);
      controller.updateDraft('x' * 1000);
      expect(controller.canSend, isTrue);
      expect(controller.draftLength, 1000);

      controller.updateDraft('Quando posso ir à entrevista?');
      await controller.send();

      expect(_count(service, 'send'), 1);
      expect(controller.draft, isEmpty);
      expect(controller.messages.last.content, 'Quando posso ir à entrevista?');
      expect(controller.isSending, isFalse);

      await controller.send();
      expect(_count(service, 'send'), 1);
    });

    test('a rejeição ERR-36 mostra o motivo e lê de novo o estado (RF075)',
        () async {
      await controller.open(matchA);
      service.failures['send'] = () =>
          rejection('ERR-36', 'A conversa está em modo apenas de consulta.');
      service.conversations = [
        sampleConversation(
          status: ConversationStatus.closed,
          closeReason: ConversationCloseReason.companySuspended,
        ),
      ];
      controller.updateDraft('Olá');

      await controller.send();

      expect(
        controller.errorMessage,
        'A conversa está em modo apenas de consulta.',
      );
      expect(controller.isReadOnly, isTrue);
      expect(controller.canSend, isFalse);
      expect(controller.closedByMe, isFalse);
    });

    test('a falha de ligação no envio mantém o rascunho', () async {
      await controller.open(matchA);
      service.failures['send'] = () => const ConnectionFailure();
      controller.updateDraft('Olá');

      await controller.send();

      expect(controller.draft, 'Olá');
      expect(controller.errorMessage, isNotNull);
    });

    test('encerrar passa a conversa a só de consulta, encerrada pelo '
        'Candidato (RF030)', () async {
      await controller.open(matchA);

      await controller.close();

      expect(_count(service, 'close'), 1);
      expect(controller.isReadOnly, isTrue);
      expect(controller.closedByMe, isTrue);
      expect(controller.isClosing, isFalse);

      await controller.close();
      expect(_count(service, 'close'), 1);
    });

    test('a falha ao encerrar é indicada', () async {
      await controller.open(matchA);
      service.failures['close'] = () => const ConnectionFailure();

      await controller.close();
      expect(controller.errorMessage, isNotNull);
      expect(controller.isReadOnly, isFalse);

      service.failures['close'] = () => rejection('ERR-36', 'Só consulta.');
      await controller.close();
      expect(controller.errorMessage, 'Só consulta.');
    });

    test('a consulta junta as mensagens novas e a indicação de leitura, sem '
        'duplicados (RF028, RF029)', () async {
      await controller.open(matchA);

      service.receive(
        matchA,
        sampleMessage(
          'r-2',
          content: 'Pode vir amanhã?',
          sentAt: t0.add(const Duration(minutes: 2)),
        ),
      );
      service.markOwnRead(matchA, t0.add(const Duration(minutes: 3)));
      service.conversations = [sampleConversation(unreadCount: 0)];

      await controller.poll();
      await controller.poll();

      expect(controller.messages.map((m) => m.messageId), [
        'r-1',
        'c-1',
        'r-2',
      ]);
      expect(controller.messages[1].readAt, isNotNull);
      expect(store.unreadMessages, 0);
      expect(_count(service, 'poll'), greaterThanOrEqualTo(2));
    });

    test('consulta de 3 em 3 segundos só em primeiro plano e para ao sair '
        '(secção 7)', () {
      fakeAsync((async) {
        final local = ChatController(
          service: service,
          store: store,
          session: session,
          lifecycle: lifecycle,
        );
        unawaited(local.open(matchA));
        async.elapse(Duration.zero);
        final first = _count(service, 'poll');

        async.elapse(const Duration(seconds: 3));
        expect(_count(service, 'poll'), first + 1);

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 9));
        expect(_count(service, 'poll'), first + 1);

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(Duration.zero);
        expect(_count(service, 'poll'), first + 2);

        local.dispose();
        async.elapse(const Duration(seconds: 9));
        expect(_count(service, 'poll'), first + 2);
      });
    });

    test('sem resumo na lista nem match, a conversa abre só de consulta '
        'quando o servidor a indica encerrada (M18)', () async {
      service.conversations = [
        sampleConversation(
          status: ConversationStatus.closed,
          closeReason: ConversationCloseReason.closedByParty,
          closedBy: recruiterId,
        ),
      ];

      await controller.open(matchA);

      expect(controller.isReadOnly, isTrue);
      expect(controller.closedByMe, isFalse);
      controller.updateDraft('Olá');
      expect(controller.canSend, isFalse);
    });
  });
}
