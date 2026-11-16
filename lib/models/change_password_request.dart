import 'json.dart';

/// Pedido de alteração da palavra-passe (`ChangePasswordRequest`, API 6.1.5).
final class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Json toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}
