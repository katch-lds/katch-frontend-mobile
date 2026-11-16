import 'package:material_ui/material_ui.dart';

import 'job_formats.dart';

/// «Interesses disponíveis: n de 10» (modelo de classes, 9.4; RF022).
class QuotaIndicator extends StatelessWidget {
  const QuotaIndicator({
    super.key,
    required this.available,
    required this.total,
  });

  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Interesses disponíveis: $available de $total',
      key: const Key('quota-indicator'),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

/// Aviso da quota esgotada, com o tempo em falta e o instante da reposição
/// (modelo de classes, 9.4; RF020).
class QuotaBlockedNotice extends StatelessWidget {
  const QuotaBlockedNotice({
    super.key,
    required this.remaining,
    required this.total,
    required this.blockedUntil,
  });

  final Duration remaining;
  final int total;
  final DateTime blockedUntil;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        key: const Key('quota-blocked'),
        color: colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Esgotou os $total interesses. Poderá voltar a manifestar '
            'interesse dentro de ${remainingLabel(remaining)} '
            '(às ${instantLabel(blockedUntil)}).',
            style: TextStyle(color: colors.onTertiaryContainer),
          ),
        ),
      ),
    );
  }
}
