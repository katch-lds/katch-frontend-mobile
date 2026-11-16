import '../core/api_exception.dart';
import '../models/json.dart';

/// Converte a resposta da API num objeto JSON.
///
/// Uma resposta noutro formato não está prevista no contrato da API v02 e é
/// tratada como `UnexpectedFailure`.
Json readObject(Object? value) {
  if (value is Json) {
    return value;
  }
  throw const UnexpectedFailure(null);
}

/// Converte a resposta da API numa lista de objetos JSON.
List<Json> readList(Object? value) {
  if (value is! List<Object?>) {
    throw const UnexpectedFailure(null);
  }
  return [for (final item in value) readObject(item)];
}

/// Converte uma resposta com campos em falta ou de outro tipo, que o contrato
/// da API v02 não prevê, em `UnexpectedFailure`.
T readModel<T>(T Function() convert) {
  try {
    return convert();
  } on TypeError {
    throw const UnexpectedFailure(null);
  } on FormatException {
    throw const UnexpectedFailure(null);
  }
}
