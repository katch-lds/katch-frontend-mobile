import 'json.dart';

/// Estado de uma conversa (`ConversationStatus`, API v02, secção 2.4).
enum ConversationStatus with WireValue {
  open('OPEN'),

  /// Modo apenas de consulta (RF030, RF075).
  closed('CLOSED');

  const ConversationStatus(this.wire);

  @override
  final String wire;

  static ConversationStatus fromWire(String value) =>
      values.byWire(value, 'Estado de conversa desconhecido');
}

/// Motivo do encerramento (`ConversationCloseReason`, API v02, secção 2.4).
enum ConversationCloseReason with WireValue {
  /// Encerrada pelo Candidato ou pelo Recrutador (RF030, RF074).
  closedByParty('CLOSED_BY_PARTY'),

  /// Conta de uma das partes bloqueada ou suspensa (RF075).
  accountBlockedOrSuspended('ACCOUNT_BLOCKED_OR_SUSPENDED'),

  /// Empresa suspensa pelo Administrador (RF075).
  companySuspended('COMPANY_SUSPENDED');

  const ConversationCloseReason(this.wire);

  @override
  final String wire;

  static ConversationCloseReason fromWire(String value) =>
      values.byWire(value, 'Motivo de encerramento desconhecido');
}

/// Resumo de uma conversa (`ConversationSummaryDto`, API v02, 6.8.1 e 8.4).
///
/// `unreadCount` é o número de mensagens da outra parte por ler (RF027);
/// `closedBy` é o `userId` de quem encerrou a conversa, `null` com a conversa
/// aberta e no encerramento automático.
final class ConversationSummaryDto {
  const ConversationSummaryDto({
    required this.matchId,
    required this.counterpartName,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    this.closeReason,
    this.closedBy,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummaryDto.fromJson(Json json) {
    final reason = json['closeReason'] as String?;
    final last = json['lastMessageAt'] as String?;
    return ConversationSummaryDto(
      matchId: json['matchId'] as String,
      counterpartName: json['counterpartName'] as String,
      jobTitle: json['jobTitle'] as String,
      companyName: json['companyName'] as String,
      status: ConversationStatus.fromWire(json['status'] as String),
      closeReason: reason == null
          ? null
          : ConversationCloseReason.fromWire(reason),
      closedBy: json['closedBy'] as String?,
      lastMessageAt: last == null ? null : DateTime.parse(last),
      unreadCount: json['unreadCount'] as int,
    );
  }

  final String matchId;

  /// Responsável da Empresa.
  final String counterpartName;
  final String jobTitle;
  final String companyName;
  final ConversationStatus status;
  final ConversationCloseReason? closeReason;
  final String? closedBy;

  /// `null` sem mensagens.
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Conversa em modo apenas de consulta (RF030, RF075).
  bool get isReadOnly => status == ConversationStatus.closed;
}
