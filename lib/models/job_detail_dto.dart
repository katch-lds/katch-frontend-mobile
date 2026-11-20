import 'job_card_dto.dart';
import 'json.dart';

/// Detalhe de uma vaga (`JobDetailDto`, API v02, 6.3.2 e 8.2; RF016).
final class JobDetailDto {
  const JobDetailDto({
    required this.card,
    required this.description,
    this.skills = const [],
    this.benefits = const [],
    required this.companyId,
  });

  factory JobDetailDto.fromJson(Json json) {
    return JobDetailDto(
      card: JobCardDto.fromJson(json['card'] as Json),
      description: json['description'] as String,
      skills: readStrings(json['skills']),
      benefits: readStrings(json['benefits']),
      companyId: json['companyId'] as String,
    );
  }

  final JobCardDto card;
  final String description;

  /// Designações das competências pedidas.
  final List<String> skills;

  /// Designações dos benefícios oferecidos.
  final List<String> benefits;

  /// Empresa da vaga, para a página de apresentação (6.3.3; RF017).
  final String companyId;
}
