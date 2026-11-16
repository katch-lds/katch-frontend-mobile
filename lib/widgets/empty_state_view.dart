import 'package:material_ui/material_ui.dart';

/// Estado sem conteúdo, com a ação sugerida (modelo de classes, 9.4).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String hint;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(hint, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('empty-action'),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
