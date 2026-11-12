import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/state/change_password_controller.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late ChangePasswordController controller;

  setUp(() {
    auth = FakeAuthService();
    controller = ChangePasswordController(auth: auth);
  });

  void fill({String current = 'katch2026', String next = 'katch2027'}) {
    controller
      ..currentPassword = current
      ..newPassword = next
      ..confirmation = next;
  }

  test('altera a palavra-passe (RF002)', () async {
    fill();

    final ok = await controller.submit();

    expect(ok, isTrue);
    expect(controller.status, LoadStatus.loaded);
    expect(auth.passwordRequests.single.newPassword, 'katch2027');
    expect(controller.currentPassword, 'katch2026');
    expect(controller.newPassword, 'katch2027');
    expect(controller.confirmation, 'katch2027');
  });

  test('rejeita a nova palavra-passe fora do P05 sem enviar', () async {
    fill(next: 'katch');

    final ok = await controller.submit();

    expect(ok, isFalse);
    expect(
      controller.errors.reasonFor(ChangePasswordController.newPasswordField),
      InputRules.passwordReason,
    );
    expect(auth.passwordRequests, isEmpty);
  });

  test('exige os campos, uma nova diferente da atual e a confirmação', () {
    expect(controller.validate(), isFalse);
    expect(
      controller.errors.reasonFor(
        ChangePasswordController.currentPasswordField,
      ),
      InputRules.requiredReason,
    );

    fill(next: 'katch2026');
    expect(controller.validate(), isFalse);
    expect(
      controller.errors.reasonFor(ChangePasswordController.newPasswordField),
      ChangePasswordController.sameAsCurrentReason,
    );

    fill();
    controller.confirmation = 'katch2028';
    expect(controller.validate(), isFalse);
    expect(
      controller.errors.reasonFor(ChangePasswordController.confirmationField),
      ChangePasswordController.confirmationReason,
    );
  });

  test('a palavra-passe atual errada é indicada no campo (RF002)', () async {
    auth.onChangePassword = () => throw rejection('ERR-10', validationMessage, {
      'currentPassword': 'A palavra-passe atual está errada.',
    });
    fill(current: 'errada2026');

    final ok = await controller.submit();

    expect(ok, isFalse);
    expect(controller.status, LoadStatus.failed);
    expect(
      controller.errors.reasonFor(
        ChangePasswordController.currentPasswordField,
      ),
      'A palavra-passe atual está errada.',
    );
  });

  test('a falha de ligação é indicada (RNF014)', () async {
    auth.onChangePassword = () => throw const ConnectionFailure();
    fill();

    await controller.submit();

    expect(controller.errorMessage, connectionFailureMessage);
  });
}
