import 'package:material_ui/material_ui.dart';

/// Motivo geral da rejeição de um formulário.
///
/// Sem motivo, ocupa um lugar vazio, para os campos do formulário não mudarem
/// de posição quando o motivo aparece.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.message, this.isError = true});

  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: isError ? colors.error : colors.onSurface),
      ),
    );
  }
}
