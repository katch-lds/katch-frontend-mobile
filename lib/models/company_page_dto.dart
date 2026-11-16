import 'json.dart';

/// Página de apresentação da Empresa (`CompanyPageDto`, API v02, 6.3.3 e 8.2;
/// RF017).
///
/// Não inclui os contactos da Empresa, que só são dados depois do match
/// (RF025).
final class CompanyPageDto {
  const CompanyPageDto({
    required this.companyId,
    required this.companyName,
    this.description,
    this.website,
    this.logoUrl,
    this.photoUrls = const [],
  });

  factory CompanyPageDto.fromJson(Json json) {
    return CompanyPageDto(
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      description: json['description'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      photoUrls: [
        for (final url in json['photoUrls'] as List<Object?>? ?? const [])
          url as String,
      ],
    );
  }

  final String companyId;
  final String companyName;
  final String? description;
  final String? website;
  final String? logoUrl;

  /// Galeria, de 0 a 6 fotografias, pela ordem da galeria.
  final List<String> photoUrls;
}
