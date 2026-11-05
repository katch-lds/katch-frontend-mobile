/// Motivo de rejeição de um campo (`FieldErrorDto` da API v02, secção 4.1).
class FieldErrorDto {
  const FieldErrorDto({required this.field, required this.reason});

  factory FieldErrorDto.fromJson(Map<String, Object?> json) {
    return FieldErrorDto(
      field: json['field'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }

  final String field;
  final String reason;
}

/// Corpo de todas as respostas de erro da API v02 (secção 4.1).
class ApiErrorDto {
  const ApiErrorDto({
    required this.code,
    required this.message,
    this.fields = const [],
    this.blockedUntil,
  });

  /// Converte o JSON; devolve `null` quando o corpo não é um `ApiErrorDto`.
  static ApiErrorDto? tryParse(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }
    final code = json['code'];
    final message = json['message'];
    if (code is! String || message is! String) {
      return null;
    }
    final until = json['blockedUntil'];
    return ApiErrorDto(
      code: code,
      message: message,
      fields: _parseFields(json['fields']),
      blockedUntil: until is String ? DateTime.tryParse(until) : null,
    );
  }

  static List<FieldErrorDto> _parseFields(Object? json) {
    final fields = <FieldErrorDto>[];
    if (json is List<Object?>) {
      for (final item in json) {
        if (item is Map<String, Object?>) {
          fields.add(FieldErrorDto.fromJson(item));
        }
      }
    }
    return fields;
  }

  final String code;
  final String message;
  final List<FieldErrorDto> fields;
  final DateTime? blockedUntil;

  /// Motivo indicado para o campo, ou `null`.
  String? reasonFor(String field) {
    for (final error in fields) {
      if (error.field == field) {
        return error.reason;
      }
    }
    return null;
  }
}
