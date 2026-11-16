import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/models/change_password_request.dart';
import 'package:katch_mobile/models/login_request.dart';
import 'package:katch_mobile/models/register_candidate_request.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/services/http_auth_service.dart';

import '../support/fakes.dart';

void main() {
  late FakeApiClient api;
  late HttpAuthService service;

  const loginJson = {
    'token': 'abc',
    'expiresAt': '2026-11-12T18:00:00Z',
    'userType': 'CANDIDATE',
    'userId': 'user-1',
  };

  setUp(() {
    api = FakeApiClient();
    service = HttpAuthService(api);
  });

  test('register envia o pedido para /api/auth/candidates (6.1.1)', () async {
    api.response = loginJson;

    final response = await service.register(
      const RegisterCandidateRequest(
        fullName: 'Ana Ferreira',
        email: 'ana@exemplo.pt',
        phoneNumber: '912345678',
        locationId: 'loc-1',
        password: 'katch2026',
        acceptTerms: true,
      ),
    );

    expect(api.calls, ['POST /api/auth/candidates']);
    expect((api.bodies.single as Map<String, Object?>)['locationId'], 'loc-1');
    expect(response.userType, UserType.candidate);
  });

  test('login envia o pedido para /api/auth/login (6.1.3)', () async {
    api.response = loginJson;

    final response = await service.login(
      const LoginRequest(email: 'ana@exemplo.pt', password: 'katch2026'),
    );

    expect(api.calls, ['POST /api/auth/login']);
    expect(response.token, 'abc');
  });

  test(
    'logout e changePassword usam as rotas da API (6.1.4 e 6.1.5)',
    () async {
      await service.logout();
      await service.changePassword(
        const ChangePasswordRequest(
          currentPassword: 'katch2026',
          newPassword: 'katch2027',
        ),
      );

      expect(api.calls, ['POST /api/auth/logout', 'PUT /api/auth/password']);
      expect(api.bodies.last, {
        'currentPassword': 'katch2026',
        'newPassword': 'katch2027',
      });
    },
  );

  test('uma resposta fora do contrato é UnexpectedFailure', () async {
    api.response = {'token': 1};

    final call = service.login(
      const LoginRequest(email: 'ana@exemplo.pt', password: 'katch2026'),
    );

    await expectLater(call, throwsA(isA<UnexpectedFailure>()));
  });

  test('uma resposta sem objeto JSON é UnexpectedFailure', () async {
    api.response = 'texto';

    final call = service.login(
      const LoginRequest(email: 'ana@exemplo.pt', password: 'katch2026'),
    );

    await expectLater(call, throwsA(isA<UnexpectedFailure>()));
  });
}
