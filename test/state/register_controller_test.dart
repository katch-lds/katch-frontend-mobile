import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_status.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/reference_data_store.dart';
import 'package:katch_mobile/state/register_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeReferenceListService referenceLists;
  late SessionManager session;
  late RegisterController controller;

  setUp(() async {
    auth = FakeAuthService();
    referenceLists = FakeReferenceListService();
    session = SessionManager(
      storage: MemorySessionStorage(),
      clock: FakeClock(),
    );
    await session.restore();
    controller = RegisterController(
      auth: auth,
      session: session,
      reference: ReferenceDataStore(referenceLists),
    );
  });

  void fillValid() {
    controller
      ..fullName = 'Ana Ferreira'
      ..email = 'ana.ferreira@exemplo.pt'
      ..phoneNumber = '912345678'
      ..locationId = felgueiras.id
      ..password = 'katch2026'
      ..acceptTerms = true;
  }

  test('obtém as localidades da lista pré-definida (RF003)', () async {
    await controller.loadLocations();

    expect(controller.locationsStatus, LoadStatus.loaded);
    expect(controller.locations, [braga, felgueiras]);
  });

  test('indica cada campo obrigatório em falta (RF004)', () async {
    await controller.submit();

    for (final field in [
      RegisterController.fullNameField,
      RegisterController.emailField,
      RegisterController.phoneNumberField,
      RegisterController.locationIdField,
      RegisterController.passwordField,
    ]) {
      expect(controller.errors.reasonFor(field), InputRules.requiredReason);
    }
    expect(
      controller.errors.reasonFor(RegisterController.acceptTermsField),
      InputRules.acceptTermsReason,
    );
    expect(auth.registerRequests, isEmpty);
  });

  test('rejeita o telefone com 8 algarismos e a localidade por preencher', () {
    fillValid();
    controller
      ..phoneNumber = '91234567'
      ..locationId = null
      ..email = 'ana.exemplo.pt'
      ..password = 'katch';

    expect(controller.validate(), isFalse);
    expect(
      controller.errors.reasonFor(RegisterController.phoneNumberField),
      InputRules.phoneReason,
    );
    expect(
      controller.errors.reasonFor(RegisterController.locationIdField),
      InputRules.requiredReason,
    );
    expect(
      controller.errors.reasonFor(RegisterController.emailField),
      InputRules.emailReason,
    );
    expect(
      controller.errors.reasonFor(RegisterController.passwordField),
      InputRules.passwordReason,
    );
  });

  test('alterar um campo retira o motivo desse campo', () {
    controller.validate();

    controller.fullName = 'Ana';

    expect(
      controller.errors.reasonFor(RegisterController.fullNameField),
      isNull,
    );
    expect(
      controller.errors.reasonFor(RegisterController.emailField),
      isNotNull,
    );
  });

  test(
    'o registo válido ativa a conta e inicia a sessão (RF003, RF005)',
    () async {
      fillValid();

      await controller.submit();

      final request = auth.registerRequests.single;
      expect(request.locationId, felgueiras.id);
      expect(request.acceptTerms, isTrue);
      expect(controller.step, RegistrationStep.completed);
      expect(controller.status, LoadStatus.loaded);
      expect(session.status, SessionStatus.signedIn);
    },
  );

  test('mostra o campo e o motivo devolvidos pela API (RF004)', () async {
    auth.onRegister = () => throw rejection('ERR-10', validationMessage, {
      'email': 'O endereço de correio eletrónico já está registado.',
      'phoneNumber': InputRules.phoneReason,
    });
    fillValid();

    await controller.submit();

    expect(controller.step, RegistrationStep.editing);
    expect(controller.status, LoadStatus.failed);
    expect(controller.errorMessage, validationMessage);
    expect(
      controller.errors.reasonFor(RegisterController.emailField),
      'O endereço de correio eletrónico já está registado.',
    );
    expect(
      controller.errors.reasonFor(RegisterController.phoneNumberField),
      InputRules.phoneReason,
    );
    expect(controller.fullName, 'Ana Ferreira');
    expect(session.status, SessionStatus.signedOut);
  });

  test('a falha de ligação mantém o formulário (RNF014)', () async {
    auth.onRegister = () => throw const ConnectionFailure();
    fillValid();

    await controller.submit();

    expect(controller.errorMessage, connectionFailureMessage);
    expect(controller.email, 'ana.ferreira@exemplo.pt');
    expect(controller.phoneNumber, '912345678');
    expect(controller.password, 'katch2026');
    expect(controller.acceptTerms, isTrue);
  });
}
