import 'json.dart';
import 'profile_enums.dart';

/// Pedido de gravação dos dados do perfil (`UpdateCandidateProfileRequest`,
/// API v02, 6.2.2). Substitui os quatro campos; `null` limpa os opcionais.
final class UpdateCandidateProfileRequest {
  const UpdateCandidateProfileRequest({
    required this.locationId,
    this.desiredRole,
    this.availability,
    this.experienceSummary,
  });

  final String? desiredRole;
  final String locationId;
  final Availability? availability;
  final String? experienceSummary;

  Json toJson() => {
    'desiredRole': desiredRole,
    'locationId': locationId,
    'availability': availability?.toWire(),
    'experienceSummary': experienceSummary,
  };
}

/// Pedido de uma competência da lista (`AddSkillRequest`, API v02, 6.2.4).
final class AddSkillRequest {
  const AddSkillRequest(this.skillId);

  final String skillId;

  Json toJson() => {'skillId': skillId};
}

/// Pedido de uma competência «Outro» (`AddCustomSkillRequest`, 6.2.10).
final class AddCustomSkillRequest {
  const AddCustomSkillRequest(this.label);

  final String label;

  Json toJson() => {'label': label};
}

/// Pedido das hiperligações profissionais (`SetLinksRequest`, 6.2.6).
final class SetLinksRequest {
  const SetLinksRequest(this.urls);

  final List<String> urls;

  Json toJson() => {'urls': urls};
}
