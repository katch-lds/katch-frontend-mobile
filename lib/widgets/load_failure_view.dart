import 'package:material_ui/material_ui.dart';

/// Falha ao obter os dados de um ecrã, com a opção de repetir o pedido.
class LoadFailureView extends StatelessWidget {
  const LoadFailureView({
    super.key,
    required this.message,
    required this.onRetry,
    this.fallback = 'Não foi possível obter o perfil.',
  });

  final String? message;
  final VoidCallback onRetry;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? fallback, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('load-retry'),
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
