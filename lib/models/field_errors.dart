import 'api_error_dto.dart';

/// Motivo de rejeição por campo de um formulário (modelo de classes, 3.4).
///
/// Junta os motivos da validação local e os devolvidos pela API
/// (`ApiErrorDto.fields`), para cada ecrã os mostrar junto do campo.
class FieldErrors {
  FieldErrors([Map<String, String>? reasons]) : _reasons = {...?reasons};

  /// Motivos devolvidos pela API, um por campo (RF004).
  factory FieldErrors.fromApi(ApiErrorDto error) {
    final errors = FieldErrors();
    for (final field in error.fields) {
      errors.add(field.field, field.reason);
    }
    return errors;
  }

  final Map<String, String> _reasons;

  bool get isEmpty => _reasons.isEmpty;

  /// Campos com motivo, pela ordem em que foram indicados.
  Iterable<String> get fields => _reasons.keys;

  /// Motivo do campo, ou `null` quando o campo está conforme.
  String? reasonFor(String field) => _reasons[field];

  /// Regista o motivo do campo; o primeiro motivo indicado prevalece.
  void add(String field, String reason) {
    _reasons.putIfAbsent(field, () => reason);
  }

  void remove(String field) => _reasons.remove(field);
}
