import '../core/api_client.dart';
import '../models/conversation_summary_dto.dart';
import '../models/message_dto.dart';
import 'conversation_service.dart';
import 'response_reader.dart';

/// `ConversationService` sobre a API v02 (`/api/conversations`, 6.8).
class HttpConversationService implements ConversationService {
  HttpConversationService(this._api);

  static const conversationsPath = '/api/conversations';

  final ApiClient _api;

  @override
  Future<List<ConversationSummaryDto>> list() async {
    final result = await _api.get(conversationsPath);
    return readModel(
      () => [
        for (final item in readList(result))
          ConversationSummaryDto.fromJson(item),
      ],
    );
  }

  @override
  Future<List<MessageDto>> open(String matchId, {DateTime? after}) async {
    final path = '${_messagesPath(matchId)}${_afterQuery(after)}';
    final result = await _api.get(path);
    return readModel(
      () => [for (final item in readList(result)) MessageDto.fromJson(item)],
    );
  }

  @override
  Future<MessageDto> send(String matchId, SendMessageRequest request) async {
    final result = await _api.post(_messagesPath(matchId), request.toJson());
    return readModel(() => MessageDto.fromJson(readObject(result)));
  }

  @override
  Future<void> close(String matchId) async {
    await _api.post('${_conversationPath(matchId)}/close');
  }

  static String _conversationPath(String matchId) {
    return '$conversationsPath/${Uri.encodeComponent(matchId)}';
  }

  static String _messagesPath(String matchId) {
    return '${_conversationPath(matchId)}/messages';
  }

  /// `after` é sempre o `sentAt` de uma mensagem recebida do servidor, em UTC
  /// e no formato ISO 8601 (API v02, 6.8.2).
  static String _afterQuery(DateTime? after) {
    if (after == null) {
      return '';
    }
    final value = after.toUtc().toIso8601String();
    return '?after=${Uri.encodeQueryComponent(value)}';
  }
}
