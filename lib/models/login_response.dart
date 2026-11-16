import 'json.dart';
import 'user_type.dart';

/// Resposta do início de sessão e do registo (`LoginResponse`, API v02 6.1).
final class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.userType,
    required this.userId,
  });

  factory LoginResponse.fromJson(Json json) {
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userType: UserType.fromWire(json['userType'] as String),
      userId: json['userId'] as String,
    );
  }

  final String token;
  final DateTime expiresAt;
  final UserType userType;
  final String userId;
}
