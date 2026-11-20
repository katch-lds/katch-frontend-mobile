import 'package:material_ui/material_ui.dart';

/// Campo de escolha numa lista, com o rótulo e o motivo de rejeição.
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
    this.error,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final List<DropdownMenuItem<T>> items;

  /// `null` desativa o campo.
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: error),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: fieldKey,
          isExpanded: true,
          isDense: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
