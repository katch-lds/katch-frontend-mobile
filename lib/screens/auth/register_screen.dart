import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/load_status.dart';
import '../../state/register_controller.dart';
import '../../widgets/dropdown_field.dart';
import '../../widgets/field_error_text.dart';
import '../../widgets/form_message.dart';
import '../../widgets/form_text_field.dart';
import '../../widgets/katch_scaffold.dart';
import '../../widgets/save_button.dart';
import 'register_success_screen.dart';

/// Registo do Candidato, M02 e M03 (RF003, RF004), e confirmação, M04 (RF005).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = RegisterController(
      auth: dependencies.auth,
      session: dependencies.session,
      reference: dependencies.referenceData,
    );
    unawaited(_controller.loadLocations());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.step == RegistrationStep.completed) {
          return RegisterSuccessScreen(onStart: _start);
        }
        final loading = _controller.status == LoadStatus.loading;
        final errors = _controller.errors;
        return KatchScaffold(
          title: 'Criar conta',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormTextField(
                  fieldKey: const Key('register-full-name'),
                  label: 'Nome completo',
                  enabled: !loading,
                  error: errors.reasonFor(RegisterController.fullNameField),
                  onChanged: (value) => _controller.fullName = value,
                ),
                FormTextField(
                  fieldKey: const Key('register-email'),
                  label: 'Correio eletrónico',
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  error: errors.reasonFor(RegisterController.emailField),
                  onChanged: (value) => _controller.email = value,
                ),
                FormTextField(
                  fieldKey: const Key('register-phone'),
                  label: 'Contacto telefónico',
                  enabled: !loading,
                  keyboardType: TextInputType.phone,
                  error: errors.reasonFor(RegisterController.phoneNumberField),
                  onChanged: (value) => _controller.phoneNumber = value,
                ),
                _LocationInput(controller: _controller, enabled: !loading),
                FormTextField(
                  fieldKey: const Key('register-password'),
                  label: 'Palavra-passe',
                  helper: 'Pelo menos 8 caracteres, uma letra e um algarismo.',
                  enabled: !loading,
                  obscure: true,
                  error: errors.reasonFor(RegisterController.passwordField),
                  onChanged: (value) => _controller.password = value,
                ),
                CheckboxListTile(
                  key: const Key('register-accept-terms'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _controller.acceptTerms,
                  onChanged: loading
                      ? null
                      : (bool? value) =>
                            _controller.acceptTerms = value ?? false,
                  title: const Text('Aceito as condições de utilização'),
                  subtitle: FieldErrorText(
                    errors.reasonFor(RegisterController.acceptTermsField),
                    spacing: 0,
                  ),
                ),
                FormMessage(message: _controller.errorMessage),
                const SizedBox(height: 16),
                SaveButton(
                  key: const Key('register-submit'),
                  loading: loading,
                  onPressed: _controller.submit,
                  label: 'Criar conta',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Localidade da lista pré-definida (RF003; API v02, 6.13.1).
class _LocationInput extends StatelessWidget {
  const _LocationInput({required this.controller, required this.enabled});

  final RegisterController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const label = 'Localidade';
    final status = controller.locationsStatus;
    final error = controller.errors.reasonFor(
      RegisterController.locationIdField,
    );
    final Widget field;
    if (status == LoadStatus.loaded) {
      field = DropdownField<String>(
        fieldKey: const Key('register-location'),
        label: label,
        error: error,
        value: controller.locationId,
        hint: 'Selecione a localidade',
        items: [
          for (final location in controller.locations)
            DropdownMenuItem(value: location.id, child: Text(location.name)),
        ],
        onChanged: enabled ? (value) => controller.locationId = value : null,
      );
    } else {
      field = InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: error),
        child: status == LoadStatus.failed
            ? Row(
                children: [
                  const Expanded(
                    child: Text('Não foi possível obter as localidades.'),
                  ),
                  TextButton(
                    key: const Key('register-locations-retry'),
                    onPressed: controller.loadLocations,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            : const LinearProgressIndicator(),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: field);
  }
}
