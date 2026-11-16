import '../core/api_client.dart';
import '../core/http_api_client.dart';
import '../models/change_password_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_candidate_request.dart';
import 'auth_service.dart';
import 'response_reader.dart';

/// `AuthService` sobre a API v02 (`/api/auth`, secção 6.1).
///
/// O cabeçalho `X-Client-App: mobile` é enviado pelo `HttpApiClient` em todos
/// os pedidos (API v02, 3.2).
class HttpAuthService implements AuthService {
  HttpAuthService(this._api);

  static const registerPath = '/api/auth/candidates';
  static const loginPath = HttpApiClient.loginPath;
  static const logoutPath = '/api/auth/logout';
  static const passwordPath = '/api/auth/password';

  final ApiClient _api;

  @override
  Future<LoginResponse> register(RegisterCandidateRequest request) async {
    final result = await _api.post(registerPath, request.toJson());
    return readModel(() => LoginResponse.fromJson(readObject(result)));
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final result = await _api.post(loginPath, request.toJson());
    return readModel(() => LoginResponse.fromJson(readObject(result)));
  }

  @override
  Future<void> logout() async {
    await _api.post(logoutPath);
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _api.put(passwordPath, request.toJson());
  }
}
