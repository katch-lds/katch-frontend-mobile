import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/screens/exploration/exploration_screen.dart';
import 'package:katch_mobile/screens/profile/preferences_screen.dart';
import 'package:katch_mobile/widgets/job_formats.dart';
import 'package:material_ui/material_ui.dart';

import '../support/api.dart';
import '../support/harness.dart';

Finder _inCard(Finder finder) =>
    find.descendant(of: find.byKey(const Key('job-card')), matching: finder);

Future<Map<String, Object?>> _quota(TestCandidate candidate) async =>
    await candidate.session.get('/api/candidate/jobs/quota', 'quota')
        as Map<String, Object?>;

String _quotaText(Map<String, Object?> quota) =>
    'Interesses disponíveis: ${quota['available']} de ${quota['total']}';

/// SM-07 a SM-11 e SM-16 — Exploração de vagas (RF013 a RF023, RNF002,
/// RNF010).
void exploracaoScenarios() {
  group('SM-07 Cartões de vaga segundo as preferências', () {
    testWidgets('SM-07a o cartão mostra os dados da vaga e só aparecem vagas '
        'dentro da distância máxima e da pretensão salarial', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm07');
      final eligible = await recruiter.createJob(minSalary: 1400);
      final far = await recruiter.createJob(locationId: Locations.vilaReal);
      final lowSalary = await recruiter.createJob(
        minSalary: 900,
        maxSalary: 1200,
      );
      final candidate = await KatchApi.createCandidate(prefix: 'sm07');
      await candidate.session.put('/api/candidate/profile/preferences', {
        'maxDistanceKm': 50,
        'minSalaryExpectation': 1500,
        'workModes': <String>[],
        'contractTypes': <String>[],
      }, 'preferências');

      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.showCard(tester, {eligible.jobId});

      // Dados do cartão (RF013).
      expect(_inCard(find.text(eligible.title)), findsOneWidget);
      expect(_inCard(find.text(recruiter.companyName)), findsOneWidget);
      await app.waitFor(tester, _inCard(find.byKey(const Key('remote-image'))));
      expect(_inCard(find.text(salaryRange(1400, 2000))), findsOneWidget);
      final shownCard = app.client.cards.lastWhere(
        (card) => card['jobId'] == eligible.jobId,
      );
      expect(
        shownCard['locationName'],
        Locations.bragancaName,
        reason: '$shownCard',
      );
      expect(shownCard['distanceKm'], 0, reason: '$shownCard');
      expect(
        _inCard(
          find.text(
            locationAndDistance(
              shownCard['locationName'] as String,
              shownCard['distanceKm'] as int,
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(_inCard(find.text('Sem termo')), findsOneWidget);
      expect(_inCard(find.text('Presencial')), findsOneWidget);
      expect(_inCard(find.byKey(const Key('job-urgent'))), findsOneWidget);

      // Percorre todos os cartões elegíveis, recusando-os, até não haver mais.
      for (var i = 0; i < 60; i++) {
        if (find.text(ExplorationScreen.emptyTitle).evaluate().isNotEmpty) {
          break;
        }
        final id = app.currentCardId(tester);
        if (id == null) {
          await tester.pump(const Duration(milliseconds: 100));
          continue;
        }
        await app.tapKey(tester, 'job-decline');
        await waitUntil(
          tester,
          () =>
              app.currentCardId(tester) != id ||
              find.text(ExplorationScreen.emptyTitle).evaluate().isNotEmpty,
          what: 'cartão seguinte a $id',
        );
      }
      await app.waitFor(tester, find.text(ExplorationScreen.emptyTitle));

      // Nenhum cartão fora das preferências (RF014, RF015).
      final shown = [for (final card in app.client.cards) card['jobId']];
      expect(shown, contains(eligible.jobId));
      expect(shown, isNot(contains(far.jobId)));
      expect(shown, isNot(contains(lowSalary.jobId)));
      for (final card in app.client.cards) {
        final remote = card['workMode'] == 'REMOTE';
        expect(
          remote || (card['distanceKm'] as int) <= 50,
          isTrue,
          reason: 'distância do cartão ${card['jobId']}',
        );
        expect(
          (card['maxSalary'] as num) >= 1500,
          isTrue,
          reason: 'salário do cartão ${card['jobId']}',
        );
      }
    });
  });

  group('SM-08 Detalhe da vaga e página da Empresa', () {
    testWidgets('SM-08a abre o detalhe com a descrição, as competências e os '
        'benefícios e, a partir dele, a página da Empresa', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm08');
      final job = await recruiter.createJob(
        locationId: Locations.guarda,
        withSkillsAndBenefits: true,
      );
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm08',
        locationId: Locations.guarda,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.showCard(tester, {job.jobId});

      await app.tapKey(tester, 'job-detail');
      await app.waitFor(tester, find.byKey(const Key('job-description')));
      expect(find.text(job.description), findsOneWidget);
      for (final name in [...job.skills, ...job.benefits]) {
        expect(find.text(name), findsWidgets, reason: name);
      }

      await app.tapKey(tester, 'job-company');
      await app.waitFor(tester, find.byKey(const Key('company-description')));
      expect(find.text(recruiter.companyName), findsWidgets);
      expect(find.text(recruiter.description), findsOneWidget);
    });
  });

  group('SM-09 Recusar e manifestar interesse', () {
    testWidgets('SM-09a cada ação exige uma interação, a vaga recusada não '
        'volta e o interesse diminui a quota', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm09');
      final first = await recruiter.createJob(locationId: Locations.viseu);
      final second = await recruiter.createJob(locationId: Locations.viseu);
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm09',
        locationId: Locations.viseu,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      final declined = await app.showCard(tester, {first.jobId, second.jobId});
      final before = await _quota(candidate);
      await app.waitFor(tester, find.text(_quotaText(before)));

      // Recusar: uma interação (RF018, RNF010).
      await app.tapKey(tester, 'job-decline');
      final next = await app.waitForNextCard(tester, declined);
      expect(app.interactions, 1);
      expect(next, isNot(declined));

      // A vaga recusada fica registada e não volta (RF018).
      final again = await candidate.session.rawPost(
        '/api/candidate/jobs/$declined/decline',
        null,
      );
      expect(again.status, 409);
      expect(again.code, 'ERR-32');
      final current =
          await candidate.session.get('/api/candidate/jobs/next', 'cartão')
              as Map<String, Object?>;
      expect(current['jobId'], isNot(declined));

      // Manifestar interesse: uma interação, e a quota baixa uma unidade
      // (RF019, RF022).
      app.interactions = 0;
      await app.tapKey(tester, 'job-interest');
      await app.waitForNextCard(tester, next);
      expect(app.interactions, 1);
      final after = await _quota(candidate);
      expect(after['available'], (before['available'] as int) - 1);
      await app.waitFor(tester, find.text(_quotaText(after)));
    });
  });

  group('SM-10 Quota esgotada', () {
    testWidgets('SM-10a ao 10.º interesse, novos interesses ficam bloqueados '
        'com o instante da reposição e a recusa continua disponível', (
      tester,
    ) async {
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm10',
        locationId: Locations.casteloBranco,
      );
      final total = (await _quota(candidate))['total'] as int;
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      for (var i = 0; i < total; i++) {
        await waitUntil(
          tester,
          () => app.currentCardId(tester) != null,
          what: 'cartão para o interesse ${i + 1}',
        );
        final id = app.currentCardId(tester);
        await app.tapKey(tester, 'job-interest');
        if (i < total - 1) {
          await app.waitForNextCard(tester, id);
        }
      }

      // Quota esgotada: aviso com a reposição e interesse bloqueado (RF020).
      await app.waitFor(tester, find.byKey(const Key('quota-blocked')));
      expect(
        find.textContaining('Esgotou os $total interesses'),
        findsOneWidget,
      );
      expect(find.text('Interesses disponíveis: 0 de $total'), findsOneWidget);
      await waitUntil(
        tester,
        () => app.currentCardId(tester) != null,
        what: 'cartão com o interesse bloqueado',
      );
      final interest = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('job-interest')),
      );
      expect(interest.onPressed, isNull);
      final quota = await _quota(candidate);
      expect(quota['available'], 0);
      expect(quota['blockedUntil'], isNotNull);
      final blocked = await candidate.session.rawPost(
        '/api/candidate/jobs/${app.currentCardId(tester)}/interest',
        null,
      );
      expect(blocked.status, greaterThanOrEqualTo(400));

      // A recusa continua disponível (RF022).
      final id = app.currentCardId(tester);
      await app.tapKey(tester, 'job-decline');
      await app.waitForNextCard(tester, id);
    });
  });

  group('SM-11 Ajuste das preferências na exploração', () {
    testWidgets('SM-11a alterar as preferências na exploração altera os '
        'cartões seguintes', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm11');
      final onSite = await recruiter.createJob(locationId: Locations.evora);
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm11',
        locationId: Locations.evora,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.showCard(tester, {onSite.jobId});
      expect(_inCard(find.text('Presencial')), findsOneWidget);

      await app.tapKey(tester, 'exploration-preferences');
      await app.tapKey(tester, 'preferences-mode-REMOTE');
      await app.tapKey(tester, 'preferences-save');
      await app.waitFor(tester, find.text(PreferencesScreen.successMessage));
      await app.back(tester);

      // Os cartões seguintes respeitam as preferências novas (RF023).
      final next = await app.waitForNextCard(tester, onSite.jobId);
      expect(next, isNot(onSite.jobId));
      expect(app.client.cards.last['jobId'], next);
      expect(app.client.cards.last['workMode'], 'REMOTE');
      expect(_inCard(find.text('Remoto')), findsOneWidget);
    });
  });

  group('SM-16 Cartão seguinte em 2 segundos', () {
    testWidgets('SM-16a depois de recusar e de manifestar interesse, o cartão '
        'seguinte aparece em 2 segundos, no máximo', (tester) async {
      final recruiter = await KatchApi.createRecruiter(prefix: 'sm16');
      final jobs = [
        for (var i = 0; i < 2; i++)
          await recruiter.createJob(locationId: Locations.aveiro),
      ];
      final candidate = await KatchApi.createCandidate(
        prefix: 'sm16',
        locationId: Locations.aveiro,
      );
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      var current = await app.showCard(tester, {
        for (final job in jobs) job.jobId,
      });

      for (final action in ['job-decline', 'job-interest']) {
        final stopwatch = Stopwatch()..start();
        await app.tapKey(tester, action);
        current = await app.waitForNextCard(tester, current);
        stopwatch.stop();
        expect(
          stopwatch.elapsed,
          lessThanOrEqualTo(const Duration(seconds: 2)),
          reason: '$action: ${stopwatch.elapsedMilliseconds} ms (RNF002)',
        );
      }
    });
  });
}
