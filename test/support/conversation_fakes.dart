import 'package:katch_mobile/models/conversation_summary_dto.dart';
import 'package:katch_mobile/models/match_dto.dart';
import 'package:katch_mobile/models/message_dto.dart';
import 'package:katch_mobile/services/conversation_service.dart';
import 'package:katch_mobile/services/match_service.dart';

/// Identificador do Candidato de `candidateLogin()`.
const candidateId = '3f2a9c1e-7b4d-4e8a-9c21-5d6e7f8a9b01';

/// Identificador do Recrutador das conversas de exemplo.
const recruiterId = '9b1d2c3e-4f5a-4b6c-8d7e-0f1a2b3c4d5e';

const matchA = '11111111-1111-4111-8111-111111111111';
const matchB = '22222222-2222-4222-8222-222222222222';

MatchDto sampleMatch({
  String matchId = matchA,
  String jobTitle = 'Programador Flutter',
  JobStatus jobStatus = JobStatus.published,
  String companyName = 'Atlântico Digital',
}) {
  return MatchDto(
    matchId: matchId,
    jobTitle: jobTitle,
    jobStatus: jobStatus,
    locationName: 'Leiria',
    companyName: companyName,
    counterpartName: 'Rita Lopes',
    contactEmail: 'rita.lopes@atlantico.pt',
    contactPhone: '912 345 678',
    matchedAt: DateTime.utc(2026, 11, 10, 9),
  );
}

ConversationSummaryDto sampleConversation({
  String matchId = matchA,
  ConversationStatus status = ConversationStatus.open,
  ConversationCloseReason? closeReason,
  String? closedBy,
  int unreadCount = 0,
  String companyName = 'Atlântico Digital',
}) {
  return ConversationSummaryDto(
    matchId: matchId,
    counterpartName: 'Rita Lopes',
    jobTitle: 'Programador Flutter',
    companyName: companyName,
    status: status,
    closeReason: closeReason,
    closedBy: closedBy,
    lastMessageAt: DateTime.utc(2026, 11, 12, 9, 30),
    unreadCount: unreadCount,
  );
}

MessageDto sampleMessage(
  String id, {
  String senderId = recruiterId,
  String content = 'Olá',
  required DateTime sentAt,
  DateTime? readAt,
}) {
  return MessageDto(
    messageId: id,
    senderId: senderId,
    content: content,
    sentAt: sentAt,
    readAt: readAt,
  );
}

class FakeMatchService implements MatchService {
  List<MatchDto> matches = [sampleMatch()];
  final calls = <String>[];
  Object Function()? failure;

  @override
  Future<List<MatchDto>> list() async {
    calls.add('list');
    final fail = failure;
    if (fail != null) {
      throw fail();
    }
    return matches;
  }
}

/// Servidor de conversas em memória: guarda as mensagens por match e devolve
/// as posteriores a `after`, como a API v02 (6.8.2).
class FakeConversationService implements ConversationService {
  List<ConversationSummaryDto> conversations = [sampleConversation()];
  final messages = <String, List<MessageDto>>{};
  final calls = <String>[];

  /// Falha a lançar pela operação com este nome (`list`, `open`, `send`,
  /// `close`).
  final failures = <String, Object Function()>{};

  int _next = 0;

  Future<void> _call(String name) async {
    calls.add(name);
    final failure = failures[name];
    if (failure != null) {
      throw failure();
    }
  }

  @override
  Future<List<ConversationSummaryDto>> list() async {
    await _call('list');
    return conversations;
  }

  @override
  Future<List<MessageDto>> open(String matchId, {DateTime? after}) async {
    await _call(after == null ? 'open' : 'poll');
    final all = messages[matchId] ?? const <MessageDto>[];
    return [
      for (final message in all)
        if (after == null || message.sentAt.isAfter(after)) message,
    ];
  }

  @override
  Future<MessageDto> send(String matchId, SendMessageRequest request) async {
    await _call('send');
    final list = messages.putIfAbsent(matchId, () => []);
    final sent = MessageDto(
      messageId: 'sent-${_next++}',
      senderId: candidateId,
      content: request.content,
      sentAt: DateTime.utc(2026, 11, 12, 10, 0, _next),
    );
    list.add(sent);
    return sent;
  }

  @override
  Future<void> close(String matchId) async {
    await _call('close');
    conversations = [
      for (final conversation in conversations)
        conversation.matchId == matchId
            ? sampleConversation(
                matchId: matchId,
                status: ConversationStatus.closed,
                closeReason: ConversationCloseReason.closedByParty,
                closedBy: candidateId,
              )
            : conversation,
    ];
  }

  /// Mensagem do Recrutador recebida «no servidor».
  void receive(String matchId, MessageDto message) {
    messages.putIfAbsent(matchId, () => []).add(message);
  }

  /// O Recrutador leu as mensagens do Candidato.
  void markOwnRead(String matchId, DateTime readAt) {
    final list = messages[matchId];
    if (list == null) {
      return;
    }
    for (var index = 0; index < list.length; index++) {
      final message = list[index];
      if (message.senderId == candidateId && message.readAt == null) {
        list[index] = MessageDto(
          messageId: message.messageId,
          senderId: message.senderId,
          content: message.content,
          sentAt: message.sentAt,
          readAt: readAt,
        );
      }
    }
  }
}
