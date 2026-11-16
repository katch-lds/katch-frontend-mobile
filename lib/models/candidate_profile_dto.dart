import 'custom_skill_dto.dart';
import 'json.dart';
import 'profile_enums.dart';
import 'reference_item_dto.dart';
import 'search_preferences_dto.dart';

/// Perfil profissional do Candidato (`CandidateProfileDto`, API v02, 6.2.1).
///
/// Nunca contém o caminho dos ficheiros: `photoUrl` é um URL da API que serve
/// a imagem depois de verificar a autorização e `hasCv` só indica se existe
/// curriculum vitae (API v02, 2.6).
final class CandidateProfileDto {
  const CandidateProfileDto({
    required this.candidateId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.locationId,
    required this.locationName,
    this.desiredRole,
    this.availability,
    this.experienceSummary,
    this.photoUrl,
    this.hasCv = false,
    this.links = const [],
    this.skills = const [],
    this.customSkills = const [],
    this.preferences = const SearchPreferencesDto(),
  });

  factory CandidateProfileDto.fromJson(Json json) {
    final availability = json['availability'] as String?;
    final preferences = json['preferences'];
    return CandidateProfileDto(
      candidateId: json['candidateId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      desiredRole: json['desiredRole'] as String?,
      availability: availability == null
          ? null
          : Availability.fromWire(availability),
      experienceSummary: json['experienceSummary'] as String?,
      photoUrl: json['photoUrl'] as String?,
      hasCv: json['hasCv'] as bool? ?? false,
      links: [
        for (final link in json['links'] as List<Object?>? ?? const [])
          link as String,
      ],
      skills: [
        for (final item in json['skills'] as List<Object?>? ?? const [])
          ReferenceItemDto.fromJson(item as Json),
      ],
      customSkills: [
        for (final item in json['customSkills'] as List<Object?>? ?? const [])
          CustomSkillDto.fromJson(item as Json),
      ],
      preferences: preferences is Json
          ? SearchPreferencesDto.fromJson(preferences)
          : const SearchPreferencesDto(),
    );
  }

  final String candidateId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String locationId;
  final String locationName;
  final String? desiredRole;
  final Availability? availability;
  final String? experienceSummary;
  final String? photoUrl;
  final bool hasCv;
  final List<String> links;
  final List<ReferenceItemDto> skills;
  final List<CustomSkillDto> customSkills;
  final SearchPreferencesDto preferences;

  /// Cópia com as preferências gravadas (API v02, 6.2.3).
  CandidateProfileDto withPreferences(SearchPreferencesDto value) {
    return CandidateProfileDto(
      candidateId: candidateId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      locationId: locationId,
      locationName: locationName,
      desiredRole: desiredRole,
      availability: availability,
      experienceSummary: experienceSummary,
      photoUrl: photoUrl,
      hasCv: hasCv,
      links: links,
      skills: skills,
      customSkills: customSkills,
      preferences: value,
    );
  }
}
