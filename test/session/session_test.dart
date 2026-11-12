import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/session/session.dart';

import '../support/fakes.dart';

void main() {
  test('converte a resposta do início de sessão e volta a ler o JSON', () {
    final session = Session.fromLoginResponse(candidateLogin());

    final restored = Session.fromJson(session.toJson());

    expect(restored.token, 'token-candidato');
    expect(restored.userType, UserType.candidate);
    expect(restored.userId, session.userId);
    expect(restored.expiresAt, testNow.add(const Duration(hours: 8)));
  });

  test('expira no instante indicado em expiresAt (RNF005)', () {
    final session = Session.fromLoginResponse(candidateLogin());
    final expiresAt = testNow.add(const Duration(hours: 8));

    expect(session.isExpiredAt(testNow), isFalse);
    expect(
      session.isExpiredAt(expiresAt.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(session.isExpiredAt(expiresAt), isTrue);
  });

  test('a credencial não aparece na representação em texto', () {
    final session = Session.fromLoginResponse(candidateLogin());

    expect(session.toString(), isNot(contains('token-candidato')));
  });
}
