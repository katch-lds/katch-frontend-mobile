import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/load_status.dart';
import '../../state/register_controller.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';
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
    final monitor = AppScope.of(context).monitor;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.step == RegistrationStep.completed) {
          return RegisterSuccessScreen(onStart: _start);
        }
        final loading = _controller.status == LoadStatus.loading;
        final errors = _controller.errors;
        return Scaffold(
          appBar: AppBar(title: const Text('Criar conta')),
          body: Column(
            children: [
              ConnectionBanner(monitor: monitor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TextInput(
                        fieldKey: const Key('register-full-name'),
                        label: 'Nome completo',
                        enabled: !loading,
                        error: errors.reasonFor(
                          RegisterController.fullNameField,
                        ),
                        onChanged: (value) => _controller.fullName = value,
                      ),
                      _TextInput(
                        fieldKey: const Key('register-email'),
                        label: 'Correio eletrónico',
                        enabled: !loading,
                        keyboardType: TextInputType.emailAddress,
                        error: errors.reasonFor(RegisterController.emailField),
                        onChanged: (value) => _controller.email = value,
                      ),
                      _TextInput(
                        fieldKey: const Key('register-phone'),
                        label: 'Contacto telefónico',
                        enabled: !loading,
                        keyboardType: TextInputType.phone,
                        error: errors.reasonFor(
                          RegisterController.phoneNumberField,
                        ),
                        onChanged: (value) => _controller.phoneNumber = value,
                      ),
                      _LocationInput(
                        controller: _controller,
                        enabled: !loading,
                      ),
                      _TextInput(
                        fieldKey: const Key('register-password'),
                        label: 'Palavra-passe',
                        helper:
                            'Pelo menos 8 caracteres, uma letra e um algarismo.',
                        enabled: !loading,
                        obscure: true,
                        error: errors.reasonFor(
                          RegisterController.passwordField,
                        ),
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
                        subtitle: _FieldError(
                          errors.reasonFor(RegisterController.acceptTermsField),
                        ),
                      ),
                      FormMessage(message: _controller.errorMessage),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('register-submit'),
                        onPressed: loading ? null : _controller.submit,
                        child: loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Criar conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.fieldKey,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.error,
    this.helper,
    this.keyboardType,
    this.obscure = false,
  });

  final Key fieldKey;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? error;
  final String? helper;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: fieldKey,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
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
    final status = controller.locationsStatus;
    final Widget child;
    if (status == LoadStatus.failed) {
      child = Row(
        children: [
          const Expanded(child: Text('Não foi possível obter as localidades.')),
          TextButton(
            key: const Key('register-locations-retry'),
            onPressed: controller.loadLocations,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    } else if (status != LoadStatus.loaded) {
      child = const LinearProgressIndicator();
    } else {
      child = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('register-location'),
          isExpanded: true,
          isDense: true,
          value: controller.locationId,
          hint: const Text('Selecione a localidade'),
          items: [
            for (final location in controller.locations)
              DropdownMenuItem(value: location.id, child: Text(location.name)),
          ],
          onChanged: enabled ? (value) => controller.locationId = value : null,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Localidade',
          errorText: controller.errors.reasonFor(
            RegisterController.locationIdField,
          ),
          border: const OutlineInputBorder(),
        ),
        child: child,
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.reason);

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final text = reason;
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
