import 'json.dart';

/// Interesses disponíveis na quota (`QuotaDto`, API v02, 6.3.6 e 8.2).
///
/// `blockedUntil` só vem com `available = 0` e é o fim do período de bloqueio
/// (RF020); depois desse instante, o servidor repõe a quota (RF021).
final class QuotaDto {
  const QuotaDto({
    required this.available,
    required this.total,
    this.blockedUntil,
  });

  factory QuotaDto.fromJson(Json json) {
    final until = json['blockedUntil'] as String?;
    return QuotaDto(
      available: json['available'] as int,
      total: json['total'] as int,
      blockedUntil: until == null ? null : DateTime.parse(until),
    );
  }

  final int available;

  /// Total da quota de interesses (P11): 10.
  final int total;

  final DateTime? blockedUntil;

  /// A quota não tem interesses disponíveis (RF020).
  bool get isExhausted => available <= 0;
}
