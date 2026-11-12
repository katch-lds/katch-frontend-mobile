import '../core/api_exception.dart';

/// Mensagem a apresentar para uma falha de um pedido (modelo de classes, 8).
///
/// `ApiRejection` mostra o motivo devolvido pela API, sem o alterar; a falha
/// de ligação mostra a indicação do RNF014; os restantes erros mostram uma
/// mensagem genérica e permitem repetir a operação.
String failureMessage(ApiException failure) {
  return switch (failure) {
    ApiRejection(:final error) => error.message,
    AuthenticationFailure(:final message) => message,
    ConnectionFailure() => connectionFailureMessage,
    UnexpectedFailure() => unexpectedFailureMessage,
  };
}

/// Indicação de falha de ligação (RNF014).
const connectionFailureMessage =
    'Sem ligação ao servidor. Verifique a ligação e tente novamente.';

/// Mensagem dos erros que o modelo de erros não prevê.
const unexpectedFailureMessage = 'Ocorreu um erro inesperado. Tente novamente.';
