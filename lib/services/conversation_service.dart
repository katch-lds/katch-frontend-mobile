import '../models/conversation_summary_dto.dart';
import '../models/message_dto.dart';

/// Conversas do Candidato (API v02, 6.8).
abstract interface class ConversationService {
  /// Todas as conversas do Candidato, com as mensagens por ler e o estado de
  /// cada uma (RF027, RF075).
  Future<List<ConversationSummaryDto>> list();

  /// Mensagens da conversa, da mais antiga para a mais recente. Sem `after`,
  /// o histórico completo; com `after`, só as enviadas depois desse instante.
  /// O servidor marca como lidas as mensagens da outra parte (RF108).
  Future<List<MessageDto>> open(String matchId, {DateTime? after});

  /// Envia uma mensagem e devolve-a gravada (RF026).
  Future<MessageDto> send(String matchId, SendMessageRequest request);

  /// Encerra a conversa: passa a modo apenas de consulta (RF030).
  Future<void> close(String matchId);
}
