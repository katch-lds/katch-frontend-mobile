import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/clock.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/quota_dto.dart';
import 'package:katch_mobile/polling/app_lifecycle_monitor.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/state/exploration_controller.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/preferences_controller.dart';
import 'package:katch_mobile/state/profile_store.dart';

import '../support/exploration_fakes.dart';
import '../support/fakes.dart';

/// Relógio que acompanha o tempo simulado do `fakeAsync`, a partir do instante
/// fixo dos testes.
class _ElapsedClock implements Clock {
  _ElapsedClock(this._async);

  final FakeAsync _async;

  @override
  DateTime now() => testNow.add(_async.elapsed);
}

int _count(FakeJobExplorationService service, String operation) {
  return service.calls.where((call) => call.startsWith(operation)).length;
}

void main() {
  final deck = sampleDeck();
  const day = Duration(hours: 24);

  late FakeClock clock;
  late FakeCandidateProfileService profileService;
  late ProfileStore store;
  late AppLifecycleMonitor lifecycle;
  late FakeJobExplorationService service;
  late ExplorationController controller;

  setUp(() async {
    clock = FakeClock();
    profileService = FakeCandidateProfileService();
    final session = SessionManager(
      storage: MemorySessionStorage(),
      clock: clock,
    );
    await session.start(candidateLogin());
    store = ProfileStore(service: profileService, session: session);
    lifecycle = AppLifecycleMonitor();
    service = FakeJobExplorationService(
      clock: clock,
      preferences: () => profileService.profile.preferences,
    );
    controller = ExplorationController(
      service: service,
      profile: store,
      lifecycle: lifecycle,
      clock: clock,
    );
  });

  tearDown(() => controller.dispose());

  group('cartões (M09, M11)', () {
    test('carrega a quota e o cartão seguinte (RF013, RF022)', () async {
      await controller.load();

      expect(controller.status, ExplorationStatus.card);
      expect(controller.currentCard?.jobId, deck[0].jobId);
      expect(controller.quota?.available, 10);
      expect(controller.quota?.total, 10);
      expect(controller.remainingBlock, isNull);
      expect(service.calls, containsAll(['getQuota', 'getNextCard']));
    });

    test('sem vagas compatíveis passa ao estado vazio (UC05, A6)', () async {
      service.cards = [];

      await controller.load();

      expect(controller.status, ExplorationStatus.empty);
      expect(controller.currentCard, isNull);
    });

    test('a falha de ligação é indicada e pode repetir-se (RNF014)', () async {
      service.failures['getNextCard'] = () => const ConnectionFailure();

      await controller.load();

      expect(controller.status, ExplorationStatus.failed);
      expect(controller.message, connectionFailureMessage);

      service.failures.clear();
      await controller.load();

      expect(controller.status, ExplorationStatus.card);
      expect(controller.message, isNull);
    });

    test('durante o pedido, o estado é de carregamento', () async {
      final hold = service.holds['getNextCard'] = Completer<void>();

      final request = controller.load();

      expect(controller.status, ExplorationStatus.loading);
      hold.complete();
      await request;
      expect(controller.status, ExplorationStatus.card);
    });

    test('ignora a resposta de um pedido anterior', () async {
      final hold = service.holds['getNextCard'] = Completer<void>();
      final first = controller.load();
      service.holds.clear();
      await controller.load();
      service.cards = [deck[2]];

      hold.complete();
      await first;

      expect(controller.currentCard?.jobId, deck[0].jobId);
    });
  });

  group('recusar e manifestar interesse (RF018, RF019, RF022)', () {
    setUp(() => controller.load());

    test('recusar passa ao cartão seguinte sem consumir a quota', () async {
      await controller.decline();

      expect(service.calls, contains('decline:${deck[0].jobId}'));
      expect(_count(service, 'expressInterest'), 0);
      expect(controller.currentCard?.jobId, deck[1].jobId);
      expect(controller.quota?.available, 10);
    });

    test('a vaga recusada não volta a aparecer', () async {
      await controller.decline();
      await controller.load();

      expect(controller.currentCard?.jobId, deck[1].jobId);
    });

    test('o interesse diminui a quota e passa ao cartão seguinte', () async {
      await controller.expressInterest();

      expect(service.calls, contains('expressInterest:${deck[0].jobId}'));
      expect(controller.quota?.available, 9);
      expect(controller.currentCard?.jobId, deck[1].jobId);

      await controller.load();
      expect(controller.currentCard?.jobId, deck[1].jobId);
      expect(controller.quota?.available, 9);
    });

    test('cada interesse diminui a quota apresentada em 1', () async {
      service.cards = [
        for (var i = 0; i < 4; i++) sampleCard(jobId: 'vaga-$i'),
      ];
      await controller.load();

      for (var expected = 9; expected >= 7; expected--) {
        await controller.expressInterest();
        expect(controller.quota?.available, expected);
      }
    });

    test('com o pedido em curso, o cartão não é respondido duas vezes '
        '(RNF010)', () async {
      final hold = service.holds['decline'] = Completer<void>();

      final request = controller.decline();
      await controller.decline();
      await controller.expressInterest();

      expect(controller.status, ExplorationStatus.loading);
      expect(controller.currentCard, isNull);
      hold.complete();
      await request;
      expect(_count(service, 'decline'), 1);
      expect(_count(service, 'expressInterest'), 0);
    });

    test('a falha de ligação ao recusar volta a mostrar o cartão', () async {
      service.failures['decline'] = () => const ConnectionFailure();

      await controller.decline();

      expect(controller.status, ExplorationStatus.card);
      expect(controller.currentCard?.jobId, deck[0].jobId);
      expect(controller.message, connectionFailureMessage);
    });

    test('vaga indisponível (ERR-33): mostra o motivo, atualiza a quota e '
        'passa ao cartão seguinte', () async {
      service.failures['expressInterest'] = () {
        service.cards.removeAt(0);
        return rejection('ERR-33', unavailableMessage);
      };
      final quotaRequests = _count(service, 'getQuota');

      await controller.expressInterest();

      expect(controller.message, unavailableMessage);
      expect(controller.quota?.available, 10);
      expect(_count(service, 'getQuota'), quotaRequests + 1);
      expect(controller.currentCard?.jobId, deck[1].jobId);
    });
  });

  group('quota esgotada (M10; RF020)', () {
    setUp(() async {
      service.cards = [
        for (var i = 0; i < 5; i++) sampleCard(jobId: 'vaga-$i'),
      ];
      service.quota = const QuotaDto(available: 1, total: 10);
      await controller.load();
      await controller.expressInterest();
    });

    test('o 10.º interesse bloqueia novos interesses durante 24 horas', () {
      expect(controller.status, ExplorationStatus.quotaExhausted);
      expect(controller.interestBlocked, isTrue);
      expect(controller.quota?.available, 0);
      expect(controller.quota?.blockedUntil, testNow.add(day));
      expect(controller.remainingBlock, day);
      expect(controller.currentCard?.jobId, 'vaga-1');
    });

    test('com a quota esgotada, o interesse não faz nenhum pedido', () async {
      final requests = service.calls.length;

      await controller.expressInterest();

      expect(service.calls, hasLength(requests));
      expect(controller.currentCard?.jobId, 'vaga-1');
    });

    test('a recusa continua disponível', () async {
      await controller.decline();

      expect(service.calls, contains('decline:vaga-1'));
      expect(controller.status, ExplorationStatus.quotaExhausted);
      expect(controller.currentCard?.jobId, 'vaga-2');
    });

    test('o tempo em falta acompanha o relógio', () {
      clock.current = testNow.add(const Duration(minutes: 13));
      expect(controller.remainingBlock, const Duration(hours: 23, minutes: 47));

      clock.current = testNow.add(const Duration(hours: 25));
      expect(controller.remainingBlock, Duration.zero);
    });
  });

  test('quota esgotada entretanto (ERR-31): mantém o cartão e passa a M10 '
      'sem novo pedido', () async {
    await controller.load();
    final until = testNow.add(const Duration(hours: 3));
    service.quota = QuotaDto(available: 0, total: 10, blockedUntil: until);
    final requests = service.calls.length;

    await controller.expressInterest();

    expect(service.calls, hasLength(requests + 1));
    expect(controller.status, ExplorationStatus.quotaExhausted);
    expect(controller.currentCard?.jobId, deck[0].jobId);
    expect(controller.quota?.blockedUntil, until);
    expect(controller.message, quotaExhaustedMessage);
  });

  test('RF021: ao fim de 24 horas a quota é reposta (relógio fixo)', () {
    fakeAsync((async) {
      final fixed = _ElapsedClock(async);
      final session = SessionManager(
        storage: MemorySessionStorage(),
        clock: fixed,
      );
      final exploration = FakeJobExplorationService(
        clock: fixed,
        cards: [for (var i = 0; i < 3; i++) sampleCard(jobId: 'vaga-$i')],
      )..quota = const QuotaDto(available: 1, total: 10);
      final timed = ExplorationController(
        service: exploration,
        profile: ProfileStore(service: profileService, session: session),
        lifecycle: AppLifecycleMonitor(),
        clock: fixed,
      );

      unawaited(timed.load());
      async.flushMicrotasks();
      unawaited(timed.expressInterest());
      async.flushMicrotasks();

      expect(timed.status, ExplorationStatus.quotaExhausted);
      expect(timed.quota?.blockedUntil, testNow.add(day));
      expect(_count(exploration, 'getQuota'), 1);

      async.elapse(const Duration(hours: 23, minutes: 47));
      expect(timed.remainingBlock, const Duration(minutes: 13));
      expect(timed.status, ExplorationStatus.quotaExhausted);

      async.elapse(const Duration(minutes: 12, seconds: 59));
      expect(timed.status, ExplorationStatus.quotaExhausted);
      expect(_count(exploration, 'getQuota'), 1);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(_count(exploration, 'getQuota'), 2);
      expect(timed.status, ExplorationStatus.card);
      expect(timed.quota?.available, 10);
      expect(timed.quota?.blockedUntil, isNull);
      expect(timed.remainingBlock, isNull);
      expect(async.pendingTimers, isEmpty);

      timed.dispose();
    });
  });

  test('RF021: se o servidor ainda indicar o bloqueio, volta a pedir a quota '
      'só um minuto depois', () {
    fakeAsync((async) {
      final fixed = _ElapsedClock(async);
      // Relógio do dispositivo adiantado: o bloqueio já terminou no
      // dispositivo, mas o servidor ainda não repôs a quota.
      final exploration = FakeJobExplorationService(clock: fixed)
        ..restores = false
        ..quota = QuotaDto(
          available: 0,
          total: 10,
          blockedUntil: testNow.subtract(const Duration(minutes: 1)),
        );
      final timed = ExplorationController(
        service: exploration,
        profile: store,
        lifecycle: AppLifecycleMonitor(),
        clock: fixed,
      );

      unawaited(timed.load());
      async.flushMicrotasks();
      expect(timed.remainingBlock, Duration.zero);

      async.elapse(const Duration(seconds: 59));
      expect(_count(exploration, 'getQuota'), 1);
      async.elapse(const Duration(seconds: 1));
      expect(_count(exploration, 'getQuota'), 2);
      async.elapse(const Duration(minutes: 1));
      expect(_count(exploration, 'getQuota'), 3);
      expect(timed.status, ExplorationStatus.quotaExhausted);

      exploration.restores = true;
      async.elapse(const Duration(minutes: 1));
      expect(timed.status, ExplorationStatus.card);
      expect(async.pendingTimers, isEmpty);

      timed.dispose();
    });
  });

  group('preferências e primeiro plano', () {
    test(
      'gravar novas preferências altera os cartões seguintes (RF023)',
      () async {
        await store.load();
        await controller.load();
        expect(controller.currentCard?.jobId, deck[0].jobId);
        final preferences = PreferencesController(
          service: profileService,
          profile: store,
        )..load();
        preferences.toggleWorkMode(WorkMode.remote);

        await preferences.save();
        await pumpEventQueue();

        expect(controller.currentCard?.jobId, deck[2].jobId);
        expect(controller.currentCard?.workMode, WorkMode.remote);
        preferences.dispose();
      },
    );

    test('outras alterações do perfil não voltam a pedir os cartões', () async {
      await store.load();
      await controller.load();
      final requests = _count(service, 'getNextCard');

      store.update(sampleProfile(desiredRole: 'Analista de dados'));
      await pumpEventQueue();

      expect(_count(service, 'getNextCard'), requests);
    });

    test(
      'ao voltar ao primeiro plano, pede a quota e o cartão (DFM-15)',
      () async {
        await controller.load();
        final requests = _count(service, 'getQuota');

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
        await pumpEventQueue();
        expect(_count(service, 'getQuota'), requests);

        lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();
        expect(_count(service, 'getQuota'), requests + 1);
        expect(controller.status, ExplorationStatus.card);
      },
    );
  });
}
