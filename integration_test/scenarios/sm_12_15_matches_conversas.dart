import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/screens/conversations/chat_screen.dart';
import 'package:katch_mobile/screens/conversations/conversations_screen.dart';
import 'package:katch_mobile/screens/matches/matches_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/api.dart';
import '../support/harness.dart';

/// Polling da conversa (P17): a mensagem nova aparece em 5 segundos, no
/// máximo, depois do envio.
const _pollingLimit = Duration(seconds: 5);

/// SM-12 a SM-15 — Matches, conversas e navegação (RF024 a RF030, RF068,
/// RF070, RF075, RF108, RNF011).
void matchesConversasScenarios() {
  group('SM-12 Matches e dados de contacto', () {
    testWidgets('SM-12a depois da aceitação pelo Recrutador, o match aparece '
        'com a vaga e os dados de contacto', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm12');
      final job = await recruiter.createJob(locationId: Locations.beja);
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm12',
        locationId: Locations.beja,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      // O Candidato manifesta interesse na aplicação; o Recrutador aceita-o
      // por pedido direto (RF068).
      await app.showCard(tester, {job.jobId});
      await app.tapKey(tester, 'job-interest');
      await app.waitForNextCard(tester, job.jobId);
      final matchId = await recruiter.accept(job, candidate);

      await app.openTab(tester, 'Matches');
      await app.waitFor(tester, find.byKey(Key('match-$matchId')));
      final tile = find.byKey(Key('match-$matchId'));
      expect(
        find.descendant(of: tile, matching: find.text(job.title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(recruiter.companyName)),
        findsOneWidget,
      );

      await app.tapKey(tester, 'match-contact-$matchId');
      await app.waitFor(tester, find.byKey(const Key('contact-email')));
      expect(
        find.descendant(
          of: find.byKey(const Key('contact-email')),
          matching: find.text(recruiter.email),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('contact-phone')),
          matching: find.text('910000000'),
        ),
        findsOneWidget,
      );
    });
  });

  group('SM-13 Conversas do Candidato', () {
    testWidgets('SM-13a mensagens por ler, histórico ordenado, envio, '
        'mensagem nova sem atualização manual e limite de 1000 caracteres', (
      tester,
    ) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm13');
      final job = await recruiter.createJob(locationId: Locations.faro);
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm13',
        locationId: Locations.faro,
      );
      final matchId = await createMatch(recruiter, job, candidate);
      const first = 'Bom dia, obrigado pelo interesse na vaga.';
      const second = 'Tem disponibilidade para uma entrevista?';
      await recruiter.send(matchId, first);
      await recruiter.send(matchId, second);

      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      // Lista com as mensagens por ler, também no separador (RF026, RF108).
      await app.openTab(tester, 'Conversas');
      final unread = find.byKey(Key('unread-$matchId'));
      await app.waitFor(tester, unread);
      expect(
        find.descendant(of: unread, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tab-unread')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Abrir marca como lidas e mostra o histórico por ordem (RF027).
      await app.tapKey(tester, 'conversation-$matchId');
      await app.waitFor(tester, find.text(second));
      expect(
        tester.getTopLeft(find.text(first)).dy,
        lessThan(tester.getTopLeft(find.text(second)).dy),
      );

      // Envio de uma mensagem (RF028).
      const reply = 'Bom dia. Sim, tenho disponibilidade esta semana.';
      await app.enter(tester, 'chat-composer', reply);
      await app.tapKey(tester, 'chat-send');
      await app.waitFor(tester, find.text(reply));

      // Mensagem do Recrutador recebida sem atualização manual (RF029, P17).
      const fromRecruiter = 'Combinado: quinta-feira às 10h.';
      final stopwatch = Stopwatch()..start();
      await recruiter.send(matchId, fromRecruiter);
      await app.waitFor(
        tester,
        find.text(fromRecruiter),
        timeout: const Duration(seconds: 10),
      );
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThanOrEqualTo(_pollingLimit),
        reason: '${stopwatch.elapsedMilliseconds} ms (P17)',
      );

      // 1001 caracteres: o campo fica nos 1000 e a API recusa o pedido.
      await app.enter(tester, 'chat-composer', 'x' * 1001);
      final composer = tester.widget<TextField>(
        find.byKey(const Key('chat-composer')),
      );
      expect(composer.controller!.text.length, InputRules.maxMessageLength);
      final tooLong = await candidate.session.rawPost(
        '/api/conversations/$matchId/messages',
        {'content': 'x' * 1001},
      );
      expect(tooLong.status, 400);
      expect(tooLong.code, 'ERR-10');

      // Depois de lida, a lista deixa de indicar mensagens por ler.
      await app.back(tester);
      await waitUntil(
        tester,
        () => find.byKey(Key('unread-$matchId')).evaluate().isEmpty,
        what: 'mensagens marcadas como lidas',
      );
    });
  });

  group('SM-14 Encerramento e modo apenas de consulta', () {
    testWidgets('SM-14a encerrar mantém o histórico e impede o envio; a '
        'suspensão da Empresa passa a conversa a modo apenas de consulta', (
      tester,
    ) async {
      final closing = await KatchApi.createRecruiter(prefix: 'sm14');
      final suspended = await KatchApi.createRecruiter(prefix: 'sm14');
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm14',
        locationId: Locations.portalegre,
      );
      final closingJob = await closing.createJob(
        locationId: Locations.portalegre,
      );
      final suspendedJob = await suspended.createJob(
        locationId: Locations.portalegre,
      );
      final closingMatch = await createMatch(closing, closingJob, candidate);
      final suspendedMatch = await createMatch(
        suspended,
        suspendedJob,
        candidate,
      );
      const history = 'Mensagem enviada antes do encerramento.';
      await closing.send(closingMatch, history);
      await suspended.send(suspendedMatch, 'Mensagem antes da suspensão.');

      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      // Encerramento pelo Candidato (RF030).
      await app.openTab(tester, 'Conversas');
      await app.tapKey(tester, 'conversation-$closingMatch');
      await app.waitFor(tester, find.text(history));
      await app.tapKey(tester, 'chat-close');
      await app.tapKey(tester, 'chat-close-confirm');
      await app.waitFor(tester, find.byKey(const Key('chat-read-only')));
      expect(find.textContaining(ChatScreen.closedByMeText), findsOneWidget);
      expect(find.text(history), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-composer')))
            .enabled,
        isFalse,
      );
      final afterClose = await candidate.session.rawPost(
        '/api/conversations/$closingMatch/messages',
        {'content': 'Depois de encerrada.'},
      );
      expect(afterClose.status, 409);
      expect(afterClose.code, 'ERR-36');
      await app.back(tester);

      // Suspensão da Empresa pelo Administrador (RF070, RF075).
      final admin = await KatchApi.admin();
      await admin.post(
        '/api/admin/companies/${suspended.companyId}/suspend',
        null,
        'suspender Empresa',
      );
      await app.tapKey(tester, 'conversation-$suspendedMatch');
      await app.waitFor(tester, find.byKey(const Key('chat-read-only')));
      expect(find.textContaining(ChatScreen.suspendedText), findsOneWidget);
      expect(find.text('Mensagem antes da suspensão.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-composer')))
            .enabled,
        isFalse,
      );
    });

    testWidgets('SM-14b sem match não há conversa', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm14');
      final job = await recruiter.createJob(locationId: Locations.portalegre);
      final other = await KatchApi.createCandidate(prefix: 'sm14');
      final matchId = await createMatch(recruiter, job, other);
      final candidate = await KatchApi.createCandidate(prefix: 'sm14');

      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.openTab(tester, 'Conversas');
      await app.waitFor(tester, find.text(ConversationsScreen.emptyTitle));

      // A conversa de outro match não é acessível ao Candidato.
      final outcome = await candidate.session.rawPost(
        '/api/conversations/$matchId/messages',
        {'content': 'Mensagem sem match.'},
      );
      expect(outcome.status, anyOf(403, 404, 409));
    });
  });

  group('SM-15 Navegação em 3 interações', () {
    testWidgets('SM-15a o perfil, a exploração, os matches e as conversas são '
        'alcançados em 3 interações, no máximo', (tester) async {
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm15',
        locationId: Locations.leiria,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      final areas = <String, Finder>{
        'Perfil': find.byKey(const Key('profile-list')),
        'Explorar': find.byKey(const Key('exploration-preferences')),
        'Matches': find.text(MatchesScreen.emptyTitle),
        'Conversas': find.text(ConversationsScreen.emptyTitle),
      };
      for (final MapEntry(key: label, value: area) in areas.entries) {
        app.interactions = 0;
        await app.openTab(tester, label);
        await app.waitFor(tester, area);
        expect(
          app.interactions,
          lessThanOrEqualTo(3),
          reason: '$label: ${app.interactions} interações (RNF011)',
        );
      }
    });
  });
}
