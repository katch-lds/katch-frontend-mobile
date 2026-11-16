import '../models/change_password_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_candidate_request.dart';

/// Operações do `AuthController` usadas pelo Candidato (API v02, 6.1).
abstract interface class AuthService {
  /// Regista o Candidato; a conta fica ativa e a sessão iniciada (RF003, RF005).
  Future<LoginResponse> register(RegisterCandidateRequest request);

  /// Inicia a sessão na aplicação móvel (RF001).
  Future<LoginResponse> login(LoginRequest request);

  /// Confirma o fim de sessão ao servidor (RF105).
  Future<void> logout();

  /// Altera a própria palavra-passe (RF002).
  Future<void> changePassword(ChangePasswordRequest request);
}
