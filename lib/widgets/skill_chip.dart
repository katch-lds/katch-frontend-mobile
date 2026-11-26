import 'package:material_ui/material_ui.dart';

/// Etiqueta de competência, removível com um toque (RF008, RF009).
///
/// As competências da opção «Outro» têm um ícone que as distingue das da
/// lista pré-definida.
class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.custom = false,
  });

  final String label;

  /// Retira a etiqueta; `null` desativa a remoção (por exemplo, a gravar).
  final VoidCallback? onDeleted;

  /// Competência indicada pela opção «Outro».
  final bool custom;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: custom ? const Icon(Icons.edit_outlined, size: 16) : null,
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 18),
      deleteButtonTooltipMessage: 'Retirar',
    );
  }
}
