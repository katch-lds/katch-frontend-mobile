import 'package:material_ui/material_ui.dart';

/// Campo de texto de um formulário, com a ajuda e o motivo de rejeição por
/// baixo.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
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
        ),
        onChanged: onChanged,
      ),
    );
  }
}
