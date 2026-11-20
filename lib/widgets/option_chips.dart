import 'package:material_ui/material_ui.dart';

/// Seleção por etiquetas (RF007): cada etiqueta liga ou desliga uma opção, e
/// podem ficar várias escolhidas.
class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.keyOf,
    required this.onToggle,
    this.enabled = true,
  });

  final List<T> options;
  final Set<T> selected;

  /// Designação apresentada de cada opção.
  final String Function(T option) labelOf;

  /// Chave de cada etiqueta, para os testes.
  final Key Function(T option) keyOf;

  final ValueChanged<T> onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            key: keyOf(option),
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: enabled ? (_) => onToggle(option) : null,
          ),
      ],
    );
  }
}
