import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/conversation_summary_dto.dart';
import 'package:katch_mobile/models/match_dto.dart';
import 'package:katch_mobile/models/message_dto.dart';
import 'package:katch_mobile/services/http_conversation_service.dart';
import 'package:katch_mobile/services/http_match_service.dart';

import '../support/fakes.dart';

const _matchId = '11111111-1111-4111-8111-111111111111';

Map<String, Object?> _matchJson({String jobStatus = 'PUBLISHED'}) => {
  'matchId': _matchId,
  'jobTitle': 'Programador Flutter',
  'jobStatus': jobStatus,
  'locationName': 'Leiria',
  'companyName': 'Atlântico Digital',
  'logoUrl': '/api/files/logo.png',
  'counterpartName': 'Rita Lopes',
  'contactEmail': 'rita.lopes@atlantico.pt',
  'contactPhone': '912345678',
  'matchedAt': '2026-11-10T09:00:00Z',
};

Map<String, Object?> _conversationJson({
  String status = 'OPEN',
  String? closeReason,
  String? closedBy,
  String? lastMessageAt = '2026-11-12T09:30:00Z',
}) => {
  'matchId': _matchId,
  'counterpartName': 'Rita Lopes',
  'jobTitle': 'Programador Flutter',
  'companyName': 'Atlântico Digital',
  'status': status,
  'closeReason': closeReason,
  'closedBy': closedBy,
  'lastMessageAt': lastMessageAt,
  'unreadCount': 2,
};

Map<String, Object?> _messageJson({String? readAt}) => {
  'messageId': 'm-1',
  'senderId': 'u-1',
  'content': 'Olá',
  'sentAt': '2026-11-12T09:30:00.123Z',
  'readAt': readAt,
};

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  group('HttpMatchService', () {
    test('list pede os matches do Candidato (6.7.1; RF024, RF025)', () async {
      api.response = [_matchJson(), _matchJson(jobStatus: 'CLOSED')];

      final matches = await HttpMatchService(api).list();

      expect(api.calls, ['GET /api/matches']);
      expect(matches, hasLength(2));
      final first = matches.first;
      expect(first.matchId, _matchId);
      expect(first.jobStatus, JobStatus.published);
      expect(first.isJobClosed, isFalse);
      expect(first.logoUrl, '/api/files/logo.png');
      expect(first.contactEmail, 'rita.lopes@atlantico.pt');
      expect(first.contactPhone, '912345678');
      expect(first.matchedAt, DateTime.utc(2026, 11, 10, 9));
      expect(matches.last.isJobClosed, isTrue);
    });

    test('os estados da vaga seguem a API v02', () {
      expect(JobStatus.fromWire('UNPUBLISHED'), JobStatus.unpublished);
      expect(JobStatus.fromWire('SUSPENDED'), JobStatus.suspended);
      expect(JobStatus.fromWire('CLOSED').wire, 'CLOSED');
      for (final status in JobStatus.values) {
        expect(status.label, isNotEmpty);
      }
      expect(() => JobStatus.fromWire('OUTRO'), throwsA(anything));
    });

    test('a falha do pedido chega ao chamador', () async {
      api.failure = const ConnectionFailure();

      await expectLater(
        HttpMatchService(api).list(),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });

  group('HttpConversationService', () {
    late HttpConversationService service;

    setUp(() => service = HttpConversationService(api));

    test('list pede as conversas (6.8.1; RF027)', () async {
      api.response = [
        _conversationJson(),
        _conversationJson(
          status: 'CLOSED',
          closeReason: 'COMPANY_SUSPENDED',
          closedBy: 'u-2',
          lastMessageAt: null,
        ),
      ];

      final conversations = await service.list();

      expect(api.calls, ['GET /api/conversations']);
      final open = conversations.first;
      expect(open.status, ConversationStatus.open);
      expect(open.isReadOnly, isFalse);
      expect(open.unreadCount, 2);
      expect(open.lastMessageAt, DateTime.utc(2026, 11, 12, 9, 30));
      final closed = conversations.last;
      expect(closed.isReadOnly, isTrue);
      expect(closed.closeReason, ConversationCloseReason.companySuspended);
      expect(closed.closedBy, 'u-2');
      expect(closed.lastMessageAt, isNull);
    });

    test('os motivos de encerramento seguem a API v02', () {
      expect(
        ConversationCloseReason.fromWire('CLOSED_BY_PARTY'),
        ConversationCloseReason.closedByParty,
      );
      expect(
        ConversationCloseReason.fromWire('ACCOUNT_BLOCKED_OR_SUSPENDED'),
        ConversationCloseReason.accountBlockedOrSuspended,
      );
      expect(ConversationStatus.fromWire('CLOSED'), ConversationStatus.closed);
      expect(() => ConversationStatus.fromWire('X'), throwsA(anything));
      expect(() => ConversationCloseReason.fromWire('X'), throwsA(anything));
    });

    test('open pede o histórico e, com after, só as mensagens seguintes '
        '(6.8.2; RF028, RF029)', () async {
      api.response = [_messageJson(readAt: '2026-11-12T09:31:00Z')];

      final all = await service.open(_matchId);
      await service.open(
        _matchId,
        after: DateTime.utc(2026, 11, 12, 9, 30, 0, 123),
      );

      expect(api.calls, [
        'GET /api/conversations/$_matchId/messages',
        'GET /api/conversations/$_matchId/messages'
            '?after=2026-11-12T09%3A30%3A00.123Z',
      ]);
      expect(all.single.messageId, 'm-1');
      expect(all.single.readAt, DateTime.utc(2026, 11, 12, 9, 31));
      expect(all.single.sentAt, DateTime.utc(2026, 11, 12, 9, 30, 0, 123));
    });

    test(
      'send envia o texto e devolve a mensagem gravada (6.8.3; RF026)',
      () async {
        api.response = _messageJson();

        final message = await service.send(
          _matchId,
          const SendMessageRequest('Bom dia'),
        );

        expect(api.calls, ['POST /api/conversations/$_matchId/messages']);
        expect(api.bodies.single, {'content': 'Bom dia'});
        expect(message.readAt, isNull);
      },
    );

    test('close encerra a conversa (6.8.4; RF030)', () async {
      api.response = null;

      await service.close(_matchId);

      expect(api.calls, ['POST /api/conversations/$_matchId/close']);
    });
  });
}
