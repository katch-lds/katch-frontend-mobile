import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/models/api_error_dto.dart';
import 'package:katch_mobile/models/change_password_request.dart';
import 'package:katch_mobile/models/field_errors.dart';
import 'package:katch_mobile/models/login_request.dart';
import 'package:katch_mobile/models/login_response.dart';
import 'package:katch_mobile/models/reference_item_dto.dart';
import 'package:katch_mobile/models/register_candidate_request.dart';
import 'package:katch_mobile/models/user_type.dart';

void main() {
  test('RegisterCandidateRequest usa os nomes da API v02 (6.1.1)', () {
    const request = RegisterCandidateRequest(
      fullName: 'Ana Ferreira',
      email: 'ana.ferreira@exemplo.pt',
      phoneNumber: '912345678',
      locationId: 'loc-1',
      password: 'katch2026',
      acceptTerms: true,
    );

    expect(request.toJson(), {
      'fullName': 'Ana Ferreira',
      'email': 'ana.ferreira@exemplo.pt',
      'phoneNumber': '912345678',
      'locationId': 'loc-1',
      'password': 'katch2026',
      'acceptTerms': true,
    });
  });

  test('LoginRequest e ChangePasswordRequest convertem para JSON', () {
    const login = LoginRequest(email: 'ana@exemplo.pt', password: 'katch2026');
    const change = ChangePasswordRequest(
      currentPassword: 'katch2026',
      newPassword: 'katch2027',
    );

    expect(login.toJson(), {
      'email': 'ana@exemplo.pt',
      'password': 'katch2026',
    });
    expect(change.toJson(), {
      'currentPassword': 'katch2026',
      'newPassword': 'katch2027',
    });
  });

  test('LoginResponse lê a resposta do início de sessão (6.1.3)', () {
    final response = LoginResponse.fromJson({
      'token': 'abc',
      'expiresAt': '2026-10-09T22:45:00Z',
      'userType': 'CANDIDATE',
      'userId': 'user-1',
    });

    expect(response.token, 'abc');
    expect(response.expiresAt, DateTime.utc(2026, 10, 9, 22, 45));
    expect(response.userType, UserType.candidate);
    expect(response.userId, 'user-1');
  });

  test('UserType converte de e para o texto da API', () {
    expect(UserType.fromWire('RECRUITER'), UserType.recruiter);
    expect(UserType.admin.toWire(), 'ADMIN');
    expect(() => UserType.fromWire('OUTRO'), throwsFormatException);
  });

  test('ReferenceItemDto lê o identificador e a designação', () {
    final item = ReferenceItemDto.fromJson({
      'id': 'loc-1',
      'name': 'Braga (Braga)',
    });

    expect(item.id, 'loc-1');
    expect(item.name, 'Braga (Braga)');
  });

  test('FieldErrors guarda o primeiro motivo de cada campo', () {
    const error = ApiErrorDto(
      code: 'ERR-10',
      message: 'Os dados enviados não cumprem a validação automática.',
      fields: [
        FieldErrorDto(
          field: 'email',
          reason: 'O endereço de correio eletrónico já está registado.',
        ),
        FieldErrorDto(field: 'email', reason: 'Outro motivo.'),
        FieldErrorDto(
          field: 'phoneNumber',
          reason: 'O contacto telefónico tem de ter 9 algarismos.',
        ),
      ],
    );

    final errors = FieldErrors.fromApi(error);

    expect(errors.fields, ['email', 'phoneNumber']);
    expect(
      errors.reasonFor('email'),
      'O endereço de correio eletrónico já está registado.',
    );
    errors.remove('email');
    expect(errors.reasonFor('email'), isNull);
    expect(errors.isEmpty, isFalse);
    expect(FieldErrors().isEmpty, isTrue);
  });
}
