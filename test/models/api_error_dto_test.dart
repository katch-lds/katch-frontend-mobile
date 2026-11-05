import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/models/api_error_dto.dart';

void main() {
  test('converte o ApiErrorDto com campos e fim do bloqueio', () {
    final dto = ApiErrorDto.tryParse({
      'code': 'ERR-31',
      'message': 'Quota esgotada.',
      'fields': [{'field': 'email', 'reason': 'Já registado.'}, 'inválido'],
      'blockedUntil': '2026-11-05T12:00:00Z',
    });

    expect(dto, isNotNull);
    expect(dto!.code, 'ERR-31');
    expect(dto.fields, hasLength(1));
    expect(dto.reasonFor('email'), 'Já registado.');
    expect(dto.reasonFor('name'), isNull);
    expect(dto.blockedUntil, DateTime.utc(2026, 11, 5, 12));
  });

  test('devolve null quando o corpo não é um ApiErrorDto', () {
    expect(ApiErrorDto.tryParse('texto'), isNull);
    expect(ApiErrorDto.tryParse({'message': 'sem code'}), isNull);
  });
}
