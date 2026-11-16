import 'json.dart';

/// Pedido de registo do Candidato (`RegisterCandidateRequest`, API v02 6.1.1).
final class RegisterCandidateRequest {
  const RegisterCandidateRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.locationId,
    required this.password,
    required this.acceptTerms,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String locationId;
  final String password;
  final bool acceptTerms;

  Json toJson() => {
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'locationId': locationId,
    'password': password,
    'acceptTerms': acceptTerms,
  };
}
