import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/app/app_scope.dart';
import 'package:katch_mobile/app/home_shell.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/http_api_client.dart';
import 'package:katch_mobile/models/company_page_dto.dart';
import 'package:katch_mobile/models/quota_dto.dart';
import 'package:katch_mobile/screens/exploration/company_page_screen.dart';
import 'package:katch_mobile/screens/exploration/exploration_screen.dart';
import 'package:katch_mobile/screens/exploration/job_detail_screen.dart';
import 'package:katch_mobile/screens/profile/preferences_screen.dart';
import 'package:katch_mobile/services/http_job_exploration_service.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/widgets/job_formats.dart';
import 'package:katch_mobile/widgets/remote_image.dart';
import 'package:material_ui/material_ui.dart';

import '../support/exploration_fakes.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  final deck = sampleDeck();
  late TestApp app;

  setUp(() async {
    app = TestApp();
    await app.session.start(candidateLogin());
  });

  Future<void> pumpExploration(WidgetTester tester) async {
    await pumpScreen(tester, app, const Scaffold(body: ExplorationScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder inCard(Finder matching) {
    return find.descendant(
      of: find.byKey(const Key('job-card')),
      matching: matching,
    );
  }

  ButtonStyleButton interestButton(WidgetTester tester) {
    return tester.widget<ButtonStyleButton>(
      find.byKey(const Key('job-interest')),
    );
  }

  int calls(String operation) {
    return app.jobExploration.calls
        .where((call) => call.startsWith(operation))
        .length;
  }

  group('M09 · cartões de vaga (RF013 a RF015)', () {
    testWidgets('o cartão mostra logótipo, função, salário, localização e '
        'distância, contrato, regime, urgência e fotografias', (tester) async {
      await pumpExploration(tester);

      expect(inCard(find.text('Programador Backend .NET')), findsOneWidget);
      expect(inCard(find.text('Lumen Software, Lda.')), findsOneWidget);
      expect(inCard(find.text('1600 € – 2100 €')), findsOneWidget);
      expect(inCard(find.text('Braga (Braga) · 22 km')), findsOneWidget);
      expect(inCard(find.text('Sem termo')), findsOneWidget);
      expect(inCard(find.text('Híbrido')), findsOneWidget);
      expect(inCard(find.byKey(const Key('job-urgent'))), findsOneWidget);
      // Logótipo e uma fotografia.
      expect(inCard(find.byType(RemoteImage)), findsNWidgets(2));
      expect(find.text('Interesses disponíveis: 10 de 10'), findsOneWidget);
    });

    testWidgets('sem logótipo nem fotografias, o cartão não os mostra', (
      tester,
    ) async {
      app.jobExploration.cards = [deck[1]];
      await pumpExploration(tester);

      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
      expect(inCard(find.text('1200 € – 1500,50 €')), findsOneWidget);
      expect(inCard(find.text('Presencial')), findsOneWidget);
      expect(inCard(find.text('A termo')), findsOneWidget);
      expect(inCard(find.byType(RemoteImage)), findsNothing);
      expect(inCard(find.byKey(const Key('job-urgent'))), findsNothing);
    });

    testWidgets('o carregamento mostra o indicador de espera', (tester) async {
      final hold = app.jobExploration.holds['getNextCard'] = Completer<void>();
      await pumpScreen(tester, app, const Scaffold(body: ExplorationScreen()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      hold.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('job-card')), findsOneWidget);
    });
  });

  group('M09 · recusar e manifestar interesse (RF018, RF019, RNF010)', () {
    testWidgets('um toque em «Recusar» passa ao cartão seguinte', (
      tester,
    ) async {
      await pumpExploration(tester);

      await tapVisible(tester, find.byKey(const Key('job-decline')));

      expect(app.jobExploration.calls, contains('decline:${deck[0].jobId}'));
      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
      expect(find.text('Programador Backend .NET'), findsNothing);
      expect(find.text('Interesses disponíveis: 10 de 10'), findsOneWidget);
    });

    testWidgets('um toque em «Tenho interesse» diminui a quota (RF022)', (
      tester,
    ) async {
      await pumpExploration(tester);

      await tapVisible(tester, find.byKey(const Key('job-interest')));

      expect(calls('expressInterest'), 1);
      expect(find.text('Interesses disponíveis: 9 de 10'), findsOneWidget);
      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
    });

    testWidgets('deslizar para a esquerda recusa e para a direita manifesta '
        'interesse, com um só gesto cada', (tester) async {
      await pumpExploration(tester);

      await tester.fling(
        find.byKey(const Key('job-card')),
        const Offset(-500, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(app.jobExploration.calls, contains('decline:${deck[0].jobId}'));
      expect(inCard(find.text('Analista de Dados')), findsOneWidget);

      await tester.fling(
        find.byKey(const Key('job-card')),
        const Offset(500, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(
        app.jobExploration.calls,
        contains('expressInterest:${deck[1].jobId}'),
      );
      expect(find.text('Interesses disponíveis: 9 de 10'), findsOneWidget);
      expect(inCard(find.text('Programador Flutter')), findsOneWidget);
    });

    testWidgets('a vaga recusada não volta a aparecer', (tester) async {
      app.jobExploration.cards = [deck[0]];
      await pumpExploration(tester);

      await tapVisible(tester, find.byKey(const Key('job-decline')));

      expect(find.text(ExplorationScreen.emptyTitle), findsOneWidget);
      expect(find.text('Programador Backend .NET'), findsNothing);
    });

    testWidgets('RNF002: o cartão seguinte aparece no primeiro frame depois '
        'da resposta da API, sem atraso acrescentado', (tester) async {
      await pumpExploration(tester);
      final hold = app.jobExploration.holds['getNextCard'] = Completer<void>();

      await tester.tap(find.byKey(const Key('job-decline')));
      await tester.pump();
      expect(find.byKey(const Key('job-card')), findsNothing);

      hold.complete();
      await tester.pump();

      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
    });

    testWidgets('RNF002: com a API a responder em 1,5 s, o cartão seguinte '
        'aparece antes dos 2 segundos', (tester) async {
      await pumpExploration(tester);
      final hold = app.jobExploration.holds['decline'] = Completer<void>();

      await tester.tap(find.byKey(const Key('job-decline')));
      await tester.pump(const Duration(milliseconds: 1500));
      hold.complete();
      await tester.pump();

      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
    });

    testWidgets('a rejeição do servidor é indicada no ecrã', (tester) async {
      app.jobExploration.failures['decline'] = () {
        app.jobExploration.cards.removeAt(0);
        return rejection('ERR-33', unavailableMessage);
      };
      await pumpExploration(tester);

      await tapVisible(tester, find.byKey(const Key('job-decline')));

      expect(find.text(unavailableMessage), findsOneWidget);
      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
    });
  });

  group('M10 · quota esgotada (RF020 a RF022)', () {
    final until = testNow.add(const Duration(hours: 23, minutes: 47));

    setUp(() {
      app.jobExploration.quota = QuotaDto(
        available: 0,
        total: 10,
        blockedUntil: until,
      );
    });

    testWidgets('indica o tempo em falta e o instante da reposição, bloqueia o '
        'interesse e mantém a recusa', (tester) async {
      await pumpExploration(tester);

      expect(find.text('Interesses disponíveis: 0 de 10'), findsOneWidget);
      expect(
        find.text(
          'Esgotou os 10 interesses. Poderá voltar a manifestar interesse '
          'dentro de 23 h 47 min (às ${instantLabel(until)}).',
        ),
        findsOneWidget,
      );
      expect(interestButton(tester).enabled, isFalse);
      expect(
        tester.widget<Dismissible>(find.byType(Dismissible)).direction,
        DismissDirection.endToStart,
      );

      await tester.fling(
        find.byKey(const Key('job-card')),
        const Offset(500, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(calls('expressInterest'), 0);
      expect(inCard(find.text('Programador Backend .NET')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('job-decline')));
      expect(app.jobExploration.calls, contains('decline:${deck[0].jobId}'));
      expect(inCard(find.text('Analista de Dados')), findsOneWidget);
      expect(interestButton(tester).enabled, isFalse);
    });

    testWidgets('o tempo em falta é atualizado a cada minuto', (tester) async {
      await pumpExploration(tester);

      app.clock.current = testNow.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 1));

      expect(find.textContaining('dentro de 23 h 45 min'), findsOneWidget);
    });

    testWidgets('no fim do bloqueio, a quota reposta volta a permitir o '
        'interesse (RF021)', (tester) async {
      app.jobExploration.quota = QuotaDto(
        available: 0,
        total: 10,
        blockedUntil: testNow.add(const Duration(seconds: 30)),
      );
      await pumpExploration(tester);
      expect(interestButton(tester).enabled, isFalse);

      app.clock.current = testNow.add(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(find.text('Interesses disponíveis: 10 de 10'), findsOneWidget);
      expect(find.byKey(const Key('quota-blocked')), findsNothing);
      expect(interestButton(tester).enabled, isTrue);
    });
  });

  group('M11 e preferências na exploração (RF023)', () {
    testWidgets('sem vagas mostra o estado vazio e abre as preferências', (
      tester,
    ) async {
      app.jobExploration.cards = [];
      await pumpExploration(tester);

      expect(find.text(ExplorationScreen.emptyTitle), findsOneWidget);
      expect(find.text(ExplorationScreen.emptyHint), findsOneWidget);

      await tester.tap(find.byKey(const Key('empty-action')));
      await tester.pumpAndSettle();

      expect(find.byType(PreferencesScreen), findsOneWidget);
    });

    testWidgets('gravar as preferências a partir da exploração altera os '
        'cartões seguintes', (tester) async {
      await pumpExploration(tester);
      expect(inCard(find.text('Programador Backend .NET')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exploration-preferences')));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('preferences-mode-REMOTE')),
      );
      await tapVisible(tester, find.byKey(const Key('preferences-save')));
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(inCard(find.text('Programador Flutter')), findsOneWidget);
      expect(find.text('Programador Backend .NET'), findsNothing);
    });
  });

  group('falha de ligação (RNF014)', () {
    testWidgets('indica a falha e permite repetir', (tester) async {
      app.jobExploration.failures['getNextCard'] = () =>
          const ConnectionFailure();
      await pumpExploration(tester);

      expect(find.text(connectionFailureMessage), findsOneWidget);

      app.jobExploration.failures.clear();
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('job-card')), findsOneWidget);
    });

    testWidgets('sem resposta da API, a falha é indicada antes dos 10 '
        'segundos', (tester) async {
      final api = HttpApiClient(
        baseUrl: 'https://api.test',
        requestTimeout: app.dependencies.config.requestTimeout,
        credentials: app.session,
        monitor: app.monitor,
        client: MockClient((_) => Completer<http.Response>().future),
      );
      final dependencies = AppDependencies(
        config: app.dependencies.config,
        monitor: app.monitor,
        session: app.session,
        auth: app.auth,
        referenceData: app.dependencies.referenceData,
        profileService: app.profileService,
        profile: app.dependencies.profile,
        filePicker: app.filePicker,
        clock: app.clock,
        lifecycle: app.lifecycle,
        jobExploration: HttpJobExplorationService(api),
        launcher: app.launcher,
      );
      await tester.pumpWidget(
        AppScope(
          dependencies: dependencies,
          child: const MaterialApp(home: Scaffold(body: ExplorationScreen())),
        ),
      );

      await tester.pump(const Duration(seconds: 8));
      expect(find.text(connectionFailureMessage), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text(connectionFailureMessage), findsOneWidget);
      expect(app.monitor.hasFailure, isTrue);
    });
  });

  group('M12 · detalhe e M13 · página da Empresa (RF016, RF017)', () {
    Future<void> openDetail(WidgetTester tester) async {
      await pumpExploration(tester);
      await tapVisible(tester, find.byKey(const Key('job-detail')));
    }

    testWidgets('o detalhe mostra a descrição, as competências e os '
        'benefícios e abre a página da Empresa', (tester) async {
      await openDetail(tester);

      expect(find.byType(JobDetailScreen), findsOneWidget);
      expect(app.jobExploration.calls, contains('getDetail:${deck[0].jobId}'));
      expect(find.text('Programador Backend .NET'), findsOneWidget);
      expect(find.textContaining('APIs REST em ASP.NET Core'), findsOneWidget);
      for (final skill in ['C#', 'SQL', 'Docker', 'Seguro de saúde']) {
        expect(find.text(skill), findsOneWidget);
      }

      await tapVisible(tester, find.byKey(const Key('job-company')));

      expect(find.byType(CompanyPageScreen), findsOneWidget);
      expect(find.text(sampleCompany.companyName), findsOneWidget);
      expect(find.text(sampleCompany.description!), findsOneWidget);
      expect(find.text('Galeria'), findsOneWidget);
      // Logótipo e duas fotografias da galeria.
      expect(find.byType(RemoteImage), findsNWidgets(3));

      await tapVisible(tester, find.byKey(const Key('company-website')));
      expect(app.launcher.urls, [sampleCompany.website]);
    });

    testWidgets('o detalhe indica a vaga sem benefícios', (tester) async {
      app.jobExploration.benefits = const [];
      await openDetail(tester);

      expect(find.text(JobDetailScreen.noBenefits), findsOneWidget);
    });

    testWidgets('o detalhe indica a falha e permite repetir', (tester) async {
      app.jobExploration.failures['getDetail'] = () =>
          const ConnectionFailure();
      await openDetail(tester);

      expect(find.text(connectionFailureMessage), findsOneWidget);

      app.jobExploration.failures.clear();
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('job-description')), findsOneWidget);
    });

    testWidgets('a página da Empresa sem descrição, sítio nem galeria', (
      tester,
    ) async {
      app.jobExploration.company = const CompanyPageDto(
        companyId: lumenId,
        companyName: 'Lumen Software, Lda.',
      );
      await pumpScreen(
        tester,
        app,
        const CompanyPageScreen(companyId: lumenId),
      );
      await tester.pumpAndSettle();

      expect(find.text(CompanyPageScreen.noDescription), findsOneWidget);
      expect(find.byKey(const Key('company-website')), findsNothing);
      expect(find.text('Galeria'), findsNothing);
    });

    testWidgets('a página da Empresa indica a falha e permite repetir', (
      tester,
    ) async {
      app.jobExploration.failures['getCompanyPage'] = () =>
          rejection('ERR-20', 'O elemento pedido não existe.');
      await pumpScreen(
        tester,
        app,
        const CompanyPageScreen(companyId: lumenId),
      );
      await tester.pumpAndSettle();

      expect(find.text('O elemento pedido não existe.'), findsOneWidget);

      app.jobExploration.failures.clear();
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();
      expect(find.text(sampleCompany.companyName), findsOneWidget);
    });

    testWidgets('indica quando o sítio não abre no navegador', (tester) async {
      app.launcher.opens = false;
      await pumpScreen(
        tester,
        app,
        const CompanyPageScreen(companyId: lumenId),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('company-website')));

      expect(
        find.text('Não foi possível abrir o sítio na Internet.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('o separador «Explorar» da área do Candidato mostra os cartões', (
    tester,
  ) async {
    await pumpKatchApp(tester, app);
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(inCard(find.text('Programador Backend .NET')), findsOneWidget);
  });
}
