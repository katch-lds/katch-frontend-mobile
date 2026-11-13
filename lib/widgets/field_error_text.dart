import 'package:material_ui/material_ui.dart';

/// Motivo de rejeição junto de um campo que não é de texto (modelo de
/// classes, 9.4; RF004).
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.reason, {super.key});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final text = reason;
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
