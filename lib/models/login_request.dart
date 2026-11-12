import 'json.dart';

/// Pedido de início de sessão (`LoginRequest`, API v02 6.1.3).
final class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Json toJson() => {'email': email, 'password': password};
}
