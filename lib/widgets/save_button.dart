import 'package:material_ui/material_ui.dart';

/// Botão de gravação, com o indicador de progresso durante o pedido.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.loading,
    required this.onPressed,
    this.label = 'Guardar',
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
