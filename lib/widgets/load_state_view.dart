import 'package:material_ui/material_ui.dart';

/// Indicador de carregamento e de erro, com a ação de repetir (RNF014).
class LoadStateView extends StatelessWidget {
  /// Pedido em curso.
  const LoadStateView.loading({super.key})
    : message = null,
      onRetry = null,
      fallback = '';

  /// Pedido falhado, com o motivo e a opção de o repetir.
  const LoadStateView.failed({
    super.key,
    required this.message,
    required VoidCallback this.onRetry,
    this.fallback = 'Não foi possível obter o perfil.',
  });

  /// Motivo da falha (por exemplo, a indicação de falha de ligação).
  final String? message;

  /// Repete o pedido; `null` enquanto o pedido está em curso.
  final VoidCallback? onRetry;

  /// Texto mostrado quando a falha não tem motivo.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    if (retry == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
              onPressed: retry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
