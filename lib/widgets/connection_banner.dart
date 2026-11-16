import 'package:material_ui/material_ui.dart';

import '../core/connection_monitor.dart';
import '../state/failure_messages.dart';

/// Faixa que indica a falha de ligação (RNF014; modelo de classes, 9.2).
///
/// Aparece quando o último pedido não obteve resposta no tempo limite de 9
/// segundos do `HttpApiClient`, abaixo dos 10 segundos do RNF014, e desaparece
/// no pedido seguinte com resposta.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.monitor});

  final ConnectionMonitor monitor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        if (!monitor.hasFailure) {
          return const SizedBox.shrink();
        }
        final colors = Theme.of(context).colorScheme;
        return Semantics(
          liveRegion: true,
          child: Material(
            color: colors.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: colors.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      connectionFailureMessage,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
