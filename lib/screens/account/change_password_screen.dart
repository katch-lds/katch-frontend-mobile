import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/change_password_controller.dart';
import '../../state/load_status.dart';
import '../../widgets/form_message.dart';
import '../../widgets/form_text_field.dart';
import '../../widgets/katch_scaffold.dart';
import '../../widgets/save_button.dart';

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
    showSuccess(context, ChangePasswordScreen.successMessage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KatchScaffold(
      title: 'Alterar palavra-passe',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final loading = _controller.status == LoadStatus.loading;
          final errors = _controller.errors;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormTextField(
                  obscure: true,
                  fieldKey: const Key('password-current'),
                  label: 'Palavra-passe atual',
                  enabled: !loading,
                  error: errors.reasonFor(
                    ChangePasswordController.currentPasswordField,
                  ),
                  onChanged: (value) => _controller.currentPassword = value,
                ),
                FormTextField(
                  obscure: true,
                  fieldKey: const Key('password-new'),
                  label: 'Palavra-passe nova',
                  helper: 'Pelo menos 8 caracteres, uma letra e um algarismo.',
                  enabled: !loading,
                  error: errors.reasonFor(
                    ChangePasswordController.newPasswordField,
                  ),
                  onChanged: (value) => _controller.newPassword = value,
                ),
                FormTextField(
                  obscure: true,
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
                SaveButton(
                  key: const Key('password-submit'),
                  loading: loading,
                  onPressed: _submit,
                  label: 'Alterar palavra-passe',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
