import 'json.dart';

/// Competência indicada pela opção «Outro» (`CustomSkillDto`, API v02, 6.2).
final class CustomSkillDto {
  const CustomSkillDto({required this.customSkillId, required this.label});

  factory CustomSkillDto.fromJson(Json json) {
    return CustomSkillDto(
      customSkillId: json['customSkillId'] as String,
      label: json['label'] as String,
    );
  }

  final String customSkillId;
  final String label;
}
