import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/change_password_controller.dart';
import '../../state/load_status.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';

/// Alteração da própria palavra-passe, M21 (RF002).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  /// Confirmação apresentada depois da alteração.
  static const successMessage = 'A palavra-passe foi alterada.';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChangePasswordController(auth: AppScope.of(context).auth);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final changed = await _controller.submit();
    if (!changed || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ChangePasswordScreen.successMessage)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context).monitor;
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar palavra-passe')),
      body: Column(
        children: [
          ConnectionBanner(monitor: monitor),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final loading = _controller.status == LoadStatus.loading;
                final errors = _controller.errors;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PasswordInput(
                        fieldKey: const Key('password-current'),
                        label: 'Palavra-passe atual',
                        enabled: !loading,
                        error: errors.reasonFor(
                          ChangePasswordController.currentPasswordField,
                        ),
                        onChanged: (value) =>
                            _controller.currentPassword = value,
                      ),
                      _PasswordInput(
                        fieldKey: const Key('password-new'),
                        label: 'Palavra-passe nova',
                        helper:
                            'Pelo menos 8 caracteres, uma letra e um algarismo.',
                        enabled: !loading,
                        error: errors.reasonFor(
                          ChangePasswordController.newPasswordField,
                        ),
                        onChanged: (value) => _controller.newPassword = value,
                      ),
                      _PasswordInput(
                        fieldKey: const Key('password-confirmation'),
                        label: 'Confirmar a palavra-passe nova',
                        enabled: !loading,
                        error: errors.reasonFor(
                          ChangePasswordController.confirmationField,
                        ),
                        onChanged: (value) => _controller.confirmation = value,
                      ),
                      FormMessage(message: _controller.errorMessage),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('password-submit'),
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Alterar palavra-passe'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.fieldKey,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.error,
    this.helper,
  });

  final Key fieldKey;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? error;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: fieldKey,
        enabled: enabled,
        obscureText: true,
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
