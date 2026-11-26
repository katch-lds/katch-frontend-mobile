import 'json.dart';
import 'profile_enums.dart';

/// Cartão de vaga (`JobCardDto`, API v02, 6.3.1 e 8.2; RF013).
///
/// `distanceKm` é a distância em linha reta entre as localidades do Candidato
/// e da vaga, arredondada às unidades (RF015); `logoUrl` só existe quando a
/// Empresa registou o logótipo.
final class JobCardDto {
  const JobCardDto({
    required this.jobId,
    required this.title,
    required this.companyName,
    this.logoUrl,
    required this.minSalary,
    required this.maxSalary,
    required this.locationName,
    required this.distanceKm,
    required this.contractType,
    required this.workMode,
    required this.isUrgent,
    this.photoUrls = const [],
  });

  factory JobCardDto.fromJson(Json json) {
    return JobCardDto(
      jobId: json['jobId'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      logoUrl: json['logoUrl'] as String?,
      minSalary: (json['minSalary'] as num).toDouble(),
      maxSalary: (json['maxSalary'] as num).toDouble(),
      locationName: json['locationName'] as String,
      distanceKm: json['distanceKm'] as int,
      contractType: ContractType.fromWire(json['contractType'] as String),
      workMode: WorkMode.fromWire(json['workMode'] as String),
      isUrgent: json['isUrgent'] as bool,
      photoUrls: readStrings(json['photoUrls']),
    );
  }

  final String jobId;
  final String title;
  final String companyName;
  final String? logoUrl;
  final double minSalary;
  final double maxSalary;
  final String locationName;
  final int distanceKm;
  final ContractType contractType;
  final WorkMode workMode;
  final bool isUrgent;

  /// Fotografias da vaga, de 0 a 5.
  final List<String> photoUrls;
}
