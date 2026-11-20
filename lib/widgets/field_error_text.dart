import 'package:material_ui/material_ui.dart';

/// Motivo de rejeição junto de um campo que não é de texto (RF004).
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.reason, {super.key, this.spacing = 4});

  final String? reason;

  /// Espaço acima do motivo; 0 no `subtitle` de um `ListTile`, já espaçado.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final text = reason;
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: spacing),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
