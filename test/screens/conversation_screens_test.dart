import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/conversation_summary_dto.dart';
import 'package:katch_mobile/models/match_dto.dart';
import 'package:katch_mobile/screens/conversations/chat_screen.dart';
import 'package:katch_mobile/screens/conversations/conversations_screen.dart';
import 'package:katch_mobile/screens/matches/match_contact_screen.dart';
import 'package:katch_mobile/screens/matches/matches_screen.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/matches_controller.dart';
import 'package:katch_mobile/widgets/conversation_widgets.dart';
import 'package:katch_mobile/widgets/match_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../support/conversation_fakes.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late TestApp app;
  final t0 = DateTime.utc(2026, 11, 12, 9);

  setUp(() async {
    app = TestApp();
    await app.session.start(candidateLogin());
  });

  Future<void> pumpMatches(WidgetTester tester, {VoidCallback? onExplore}) {
    return pumpScreen(
      tester,
      app,
      Scaffold(
        body: MatchesScreen(active: true, onExplore: onExplore ?? () {}),
      ),
    );
  }

  group('M14 e M15: matches e contacto da Empresa', () {
    testWidgets('mostra a vaga, a Empresa e a vaga encerrada (RF024)', (
      tester,
    ) async {
      app.matches.matches = [
        sampleMatch(),
        sampleMatch(
          matchId: matchB,
          jobTitle: 'Analista de dados',
          jobStatus: JobStatus.closed,
        ),
      ];

      await pumpMatches(tester);
      await tester.pump();

      expect(find.text('Programador Flutter'), findsOneWidget);
      expect(find.text('Analista de dados'), findsOneWidget);
      expect(find.byKey(const Key('match-closed-$matchB')), findsOneWidget);
      expect(find.byKey(const Key('match-closed-$matchA')), findsNothing);
      expect(find.text(MatchTile.closedJobLabel), findsOneWidget);
    });

    testWidgets('sem matches, sugere explorar vagas', (tester) async {
      app.matches.matches = [];
      var explored = false;

      await pumpMatches(tester, onExplore: () => explored = true);
      await tester.pump();

      expect(find.text(MatchesScreen.emptyTitle), findsOneWidget);
      await tester.tap(find.text('Explorar vagas'));
      expect(explored, isTrue);
    });

    testWidgets('sem ligação, indica a falha e permite repetir (RNF014)', (
      tester,
    ) async {
      app.matches.failure = () => const ConnectionFailure();

      await pumpMatches(tester);
      await tester.pump();

      expect(
        find.text(failureMessage(const ConnectionFailure())),
        findsOneWidget,
      );

      app.matches.failure = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('match-$matchA')), findsOneWidget);
    });

    testWidgets('o separador volta a pedir a lista quando é escolhido', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        app,
        const Scaffold(body: MatchesScreen(active: false, onExplore: _none)),
      );
      expect(app.matches.calls, isEmpty);

      await pumpScreen(
        tester,
        app,
        const Scaffold(body: MatchesScreen(active: true, onExplore: _none)),
      );
      await tester.pump();

      expect(app.matches.calls, ['list']);
    });

    testWidgets('o contacto abre o correio e a chamada (RF025) e leva à '
        'conversa', (tester) async {
      await pumpMatches(tester);
      await tester.pump();

      await tester.tap(find.byKey(const Key('match-contact-$matchA')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchContactScreen), findsOneWidget);
      expect(find.text('Rita Lopes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('contact-email')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('contact-phone')));
      await tester.pump();
      expect(app.launcher.emails, ['rita.lopes@atlantico.pt']);
      expect(app.launcher.phones, ['912 345 678']);

      app.launcher.opens = false;
      await tester.tap(find.byKey(const Key('contact-phone')));
      await tester.pump();
      expect(find.text(MatchesController.phoneFailedMessage), findsOneWidget);

      await tester.tap(find.byKey(const Key('contact-chat')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('«Abrir conversa» leva à conversa do match com um toque '
        '(RF068, RNF011)', (tester) async {
      await pumpMatches(tester);
      await tester.pump();

      await tester.tap(find.byKey(const Key('match-chat-$matchA')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Atlântico Digital'), findsOneWidget);
    });
  });

  group('M16: lista de conversas', () {
    Future<void> pumpList(WidgetTester tester, {bool active = true}) async {
      await app.conversations.load();
      await pumpScreen(
        tester,
        app,
        Scaffold(
          body: ConversationsScreen(active: active, onOpenMatches: _none),
        ),
      );
    }

    testWidgets('mostra o contador por ler e a conversa encerrada (RF027)', (
      tester,
    ) async {
      app.conversationService.conversations = [
        sampleConversation(unreadCount: 2),
        sampleConversation(
          matchId: matchB,
          status: ConversationStatus.closed,
          closeReason: ConversationCloseReason.closedByParty,
          companyName: 'Lumen Software',
        ),
      ];

      await pumpList(tester);

      expect(find.byKey(const Key('unread-$matchA')), findsOneWidget);
      expect(find.byKey(const Key('unread-$matchB')), findsNothing);
      expect(find.textContaining(ConversationTile.closedLabel), findsOneWidget);
      expect(app.conversations.isPolling, isTrue);
    });

    testWidgets('consulta só com o separador escolhido e sem conversa aberta '
        '(RF029)', (tester) async {
      await pumpList(tester, active: false);
      expect(app.conversations.isPolling, isFalse);

      await pumpList(tester);
      expect(app.conversations.isPolling, isTrue);

      await tester.tap(find.byKey(const Key('conversation-$matchA')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(app.conversations.isPolling, isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(app.conversations.isPolling, isTrue);

      await tester.pumpWidget(const SizedBox());
      expect(app.conversations.isPolling, isFalse);
    });

    testWidgets('sem conversas, leva aos matches', (tester) async {
      app.conversationService.conversations = [];
      var opened = false;
      await app.conversations.load();
      await pumpScreen(
        tester,
        app,
        Scaffold(
          body: ConversationsScreen(
            active: false,
            onOpenMatches: () => opened = true,
          ),
        ),
      );

      expect(find.text(ConversationsScreen.emptyTitle), findsOneWidget);
      await tester.tap(find.text('Ver matches'));
      expect(opened, isTrue);
    });

    testWidgets('sem ligação, indica a falha (RNF014)', (tester) async {
      app.conversationService.failures['list'] = () =>
          const ConnectionFailure();

      await pumpList(tester, active: false);

      expect(
        find.text(failureMessage(const ConnectionFailure())),
        findsOneWidget,
      );
      app.conversationService.failures.clear();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('conversation-$matchA')), findsOneWidget);
    });
  });

  group('M17 e M18: conversa', () {
    setUp(() {
      app.conversationService.receive(
        matchA,
        sampleMessage('r-1', content: 'Olá, João', sentAt: t0),
      );
      app.conversationService.messages[matchA]!.add(
        sampleMessage(
          'c-1',
          senderId: candidateId,
          content: 'Bom dia',
          sentAt: t0.add(const Duration(minutes: 1)),
          readAt: t0.add(const Duration(minutes: 2)),
        ),
      );
    });

    Future<void> pumpChat(WidgetTester tester) async {
      await pumpScreen(tester, app, const ChatScreen(matchId: matchA));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('mostra o histórico alinhado pelo remetente, com a '
        'indicação de leitura das mensagens próprias (RF028)', (tester) async {
      await pumpChat(tester);

      expect(find.text('Olá, João'), findsOneWidget);
      expect(find.text('Bom dia'), findsOneWidget);
      final own = tester.widget<Align>(find.byKey(const Key('message-c-1')));
      final other = tester.widget<Align>(find.byKey(const Key('message-r-1')));
      expect(own.alignment, Alignment.centerRight);
      expect(other.alignment, Alignment.centerLeft);
      expect(find.textContaining(MessageBubble.readLabel), findsOneWidget);
    });

    testWidgets('envia a mensagem e limpa a caixa (RF026)', (tester) async {
      await pumpChat(tester);

      final send = find.byKey(const Key('chat-send'));
      expect(tester.widget<FilledButton>(send).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('chat-composer')), 'Olá!');
      await tester.pump();
      expect(find.text('4/1000'), findsOneWidget);
      await tester.tap(send);
      await tester.pump();
      await tester.pump();

      expect(app.conversationService.calls, contains('send'));
      expect(find.text('Olá!'), findsOneWidget);
      expect(find.textContaining(MessageBubble.unreadLabel), findsOneWidget);
      expect(find.text('0/1000'), findsOneWidget);
    });

    testWidgets('encerrar pede confirmação e passa a M18 (RF030)', (
      tester,
    ) async {
      await pumpChat(tester);

      await tester.tap(find.byKey(const Key('chat-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(app.conversationService.calls, isNot(contains('close')));

      await tester.tap(find.byKey(const Key('chat-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-close-confirm')));
      await tester.pump();
      await tester.pump();

      expect(app.conversationService.calls, contains('close'));
      expect(find.byKey(const Key('chat-read-only')), findsOneWidget);
      expect(find.textContaining(ChatScreen.closedByMeText), findsOneWidget);
      expect(find.byKey(const Key('chat-close')), findsNothing);
      final composer = tester.widget<TextField>(
        find.byKey(const Key('chat-composer')),
      );
      expect(composer.enabled, isFalse);
    });

    testWidgets('com a Empresa suspensa, fica só de consulta (RF070, RF075)', (
      tester,
    ) async {
      app.conversationService.conversations = [
        sampleConversation(
          status: ConversationStatus.closed,
          closeReason: ConversationCloseReason.companySuspended,
        ),
      ];

      await pumpChat(tester);

      expect(find.textContaining(ChatScreen.suspendedText), findsOneWidget);
      expect(find.text('Olá, João'), findsOneWidget);
    });

    testWidgets('encerrada pela Empresa, indica-o (M18)', (tester) async {
      app.conversationService.conversations = [
        sampleConversation(
          status: ConversationStatus.closed,
          closeReason: ConversationCloseReason.closedByParty,
          closedBy: recruiterId,
        ),
      ];

      await pumpChat(tester);

      expect(
        find.textContaining(ChatScreen.closedByCompanyText),
        findsOneWidget,
      );
    });

    testWidgets('a mensagem do Recrutador chega pela consulta de 3 segundos '
        '(RF029)', (tester) async {
      await pumpChat(tester);

      app.conversationService.receive(
        matchA,
        sampleMessage(
          'r-2',
          content: 'Pode vir amanhã?',
          sentAt: t0.add(const Duration(minutes: 5)),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Pode vir amanhã?'), findsOneWidget);
    });

    testWidgets('sem ligação ao abrir, indica a falha e permite repetir '
        '(RNF014)', (tester) async {
      app.conversationService.failures['open'] = () =>
          const ConnectionFailure();

      await pumpChat(tester);
      expect(
        find.text(failureMessage(const ConnectionFailure())),
        findsOneWidget,
      );

      app.conversationService.failures.clear();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Olá, João'), findsOneWidget);
    });
  });

  group('Falha de ligação e indicação de leitura (melhorias M01 e M04)', () {
    testWidgets('a conversa aberta indica a falha de ligação das consultas '
        'periódicas e retira-a quando o servidor volta a responder (RNF014)', (
      tester,
    ) async {
      await pumpScreen(tester, app, const ChatScreen(matchId: matchA));
      await tester.pump();
      await tester.pump();
      expect(find.text(connectionFailureMessage), findsNothing);

      app.monitor.reportFailure();
      await tester.pump();
      expect(find.text(connectionFailureMessage), findsOneWidget);
      expect(find.byType(ChatScreen), findsOneWidget);

      app.monitor.reportSuccess();
      await tester.pump();
      expect(find.text(connectionFailureMessage), findsNothing);
    });

    testWidgets('o contacto da Empresa indica a falha de ligação (RNF014)', (
      tester,
    ) async {
      final controller = MatchesController(
        service: app.matches,
        launcher: app.launcher,
      );
      addTearDown(controller.dispose);
      await controller.load();
      await pumpScreen(
        tester,
        app,
        MatchContactScreen(controller: controller, matchId: matchA),
      );

      app.monitor.reportFailure();
      await tester.pump();

      expect(find.text(connectionFailureMessage), findsOneWidget);
      expect(find.text('rita.lopes@atlantico.pt'), findsOneWidget);
    });

    test('a leitura no dia do envio mostra só a hora', () {
      expect(
        MessageBubble.readDetail(
          DateTime(2026, 11, 12, 9, 30),
          DateTime(2026, 11, 12, 18, 5),
        ),
        'Lida às 18:05',
      );
    });

    test('a leitura noutro dia mostra também a data', () {
      expect(
        MessageBubble.readDetail(
          DateTime(2026, 11, 12, 23, 50),
          DateTime(2026, 11, 13, 0, 10),
        ),
        'Lida às 00:10 de 13/11/2026',
      );
    });

    testWidgets('a mensagem lida noutro dia mostra a data na conversa', (
      tester,
    ) async {
      app.conversationService.receive(
        matchA,
        sampleMessage(
          'c-9',
          senderId: candidateId,
          content: 'Ainda está disponível?',
          sentAt: DateTime(2026, 11, 12, 22),
          readAt: DateTime(2026, 11, 14, 8, 15),
        ),
      );

      await pumpScreen(tester, app, const ChatScreen(matchId: matchA));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('Lida às 08:15 de 14/11/2026'),
        findsOneWidget,
      );
    });
  });
}

void _none() {}
