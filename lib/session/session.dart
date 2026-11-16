import '../models/json.dart';
import '../models/login_response.dart';
import '../models/user_type.dart';

/// Sessão iniciada no dispositivo (modelo de classes do mobile v02, 6).
final class Session {
  const Session({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.userType,
  });

  factory Session.fromLoginResponse(LoginResponse response) {
    return Session(
      token: response.token,
      expiresAt: response.expiresAt,
      userId: response.userId,
      userType: response.userType,
    );
  }

  /// Sessão guardada no armazenamento seguro (`toJson`).
  factory Session.fromJson(Json json) {
    return Session(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userId: json['userId'] as String,
      userType: UserType.fromWire(json['userType'] as String),
    );
  }

  /// Credencial de sessão (JWT). Nunca é escrita nos registos.
  final String token;

  /// Fim da validade: 8 horas depois do início de sessão (RNF005, P20).
  final DateTime expiresAt;

  final String userId;
  final UserType userType;

  Json toJson() => {
    'token': token,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'userId': userId,
    'userType': userType.toWire(),
  };

  bool isExpiredAt(DateTime moment) => !moment.isBefore(expiresAt);

  @override
  String toString() => 'Session(userId: $userId, expiresAt: $expiresAt)';
}
