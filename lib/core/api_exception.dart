import '../models/api_error_dto.dart';

/// Falha de um pedido à API (modelo de classes do mobile v02, secção 4.1).
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;
}

/// O servidor rejeitou o pedido e indicou o motivo (`ApiErrorDto`).
class ApiRejection extends ApiException {
  ApiRejection(this.error) : super(error.message);

  final ApiErrorDto error;
}

/// Credencial recusada numa operação reservada (ERR-01, ERR-03, ERR-04).
class AuthenticationFailure extends ApiException {
  const AuthenticationFailure(super.message);
}

/// O pedido não obteve resposta dentro do tempo limite ou sem ligação.
class ConnectionFailure extends ApiException {
  const ConnectionFailure() : super('Sem ligação ao servidor.');
}

/// Resposta de erro que o modelo de erros não prevê (por exemplo, `5xx`).
class UnexpectedFailure extends ApiException {
  const UnexpectedFailure(this.statusCode) : super('Erro inesperado.');

  final int? statusCode;
}
