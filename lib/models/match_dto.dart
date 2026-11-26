import 'json.dart';

/// Estado de uma vaga (`JobStatus`, API v02, secção 2.4).
enum JobStatus with WireValue {
  unpublished('UNPUBLISHED', 'Não publicada'),
  published('PUBLISHED', 'Publicada'),
  suspended('SUSPENDED', 'Suspensa'),
  closed('CLOSED', 'Encerrada');

  const JobStatus(this.wire, this.label);

  /// Valor usado no JSON da API.
  @override
  final String wire;

  /// Designação apresentada ao Candidato.
  final String label;

  /// Converte o valor do JSON; um valor desconhecido é rejeitado.
  static JobStatus fromWire(String value) =>
      values.byWire(value, 'Estado de vaga desconhecido');
}

/// Match confirmado do Candidato (`MatchDto`, API v02, 6.7.1 e 8.4).
///
/// `counterpartName`, `contactEmail` e `contactPhone` são o responsável e os
/// contactos de registo da Empresa, que só chegam ao Candidato depois do match
/// (RF025). `matchId` identifica também a conversa do match (RF068).
final class MatchDto {
  const MatchDto({
    required this.matchId,
    required this.jobTitle,
    required this.jobStatus,
    required this.locationName,
    required this.companyName,
    this.logoUrl,
    required this.counterpartName,
    required this.contactEmail,
    required this.contactPhone,
    required this.matchedAt,
  });

  factory MatchDto.fromJson(Json json) {
    return MatchDto(
      matchId: json['matchId'] as String,
      jobTitle: json['jobTitle'] as String,
      jobStatus: JobStatus.fromWire(json['jobStatus'] as String),
      locationName: json['locationName'] as String,
      companyName: json['companyName'] as String,
      logoUrl: json['logoUrl'] as String?,
      counterpartName: json['counterpartName'] as String,
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
      matchedAt: DateTime.parse(json['matchedAt'] as String),
    );
  }

  final String matchId;
  final String jobTitle;
  final JobStatus jobStatus;

  /// Localidade da vaga.
  final String locationName;
  final String companyName;

  /// Logótipo da Empresa; `null` sem logótipo.
  final String? logoUrl;

  /// Responsável da Empresa (RF025).
  final String counterpartName;
  final String contactEmail;
  final String contactPhone;
  final DateTime matchedAt;

  /// A vaga deixou de estar publicada; o match continua na lista (RF024).
  bool get isJobClosed => jobStatus != JobStatus.published;
}
