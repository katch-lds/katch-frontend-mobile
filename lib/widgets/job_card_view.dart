import 'package:material_ui/material_ui.dart';

import '../models/job_card_dto.dart';
import 'job_formats.dart';
import 'photo_grid.dart';
import 'remote_image.dart';

/// Cartão de vaga de M09 e M10 (RF013, RNF010).
///
/// Recusar, manifestar interesse e ver o detalhe são botões do cartão; recusar
/// e manifestar interesse também se fazem deslizando o cartão para a esquerda
/// ou para a direita. Cada ação exige uma só interação. Com o interesse
/// bloqueado (RF020), o botão fica desativado e o cartão só desliza para a
/// esquerda.
class JobCardView extends StatelessWidget {
  const JobCardView({
    super.key,
    required this.card,
    required this.interestEnabled,
    required this.onDecline,
    required this.onInterest,
    required this.onDetail,
  });

  final JobCardDto card;
  final bool interestEnabled;
  final VoidCallback onDecline;
  final VoidCallback onInterest;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('job-card-${card.jobId}'),
      direction: interestEnabled
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      resizeDuration: null,
      onDismissed: (direction) =>
          direction == DismissDirection.startToEnd ? onInterest() : onDecline(),
      background: _SwipeHint(
        color: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
        icon: Icons.favorite,
        label: 'Tenho interesse',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeHint(
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        icon: Icons.close,
        label: 'Recusar',
        alignment: Alignment.centerRight,
      ),
      child: Card(
        key: const Key('job-card'),
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: JobSummary(card: card),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    key: const Key('job-detail'),
                    onPressed: onDetail,
                    child: const Text('Ver detalhe'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('job-decline'),
                          onPressed: onDecline,
                          icon: const Icon(Icons.close),
                          label: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('job-interest'),
                          onPressed: interestEnabled ? onInterest : null,
                          icon: const Icon(Icons.favorite),
                          label: const Text('Tenho interesse'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dados de um cartão de vaga, partilhados pelo cartão (M09) e pelo detalhe
/// (M12): logótipo e designação da Empresa, função, urgência, fotografias,
/// intervalo salarial, localidade e distância, tipo de contrato e regime.
class JobSummary extends StatelessWidget {
  const JobSummary({super.key, required this.card});

  final JobCardDto card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (card.logoUrl != null) ...[
              RemoteImage(url: card.logoUrl, size: 56),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: textTheme.titleLarge),
                  Text(card.companyName, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        if (card.isUrgent) ...[
          const SizedBox(height: 8),
          const Chip(
            key: Key('job-urgent'),
            avatar: Icon(Icons.bolt),
            label: Text('Urgente'),
          ),
        ],
        if (card.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          PhotoGrid(urls: card.photoUrls),
        ],
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.euro,
          text: salaryRange(card.minSalary, card.maxSalary),
        ),
        _InfoRow(
          icon: Icons.place_outlined,
          text: locationAndDistance(card.locationName, card.distanceKm),
        ),
        _InfoRow(
          icon: Icons.description_outlined,
          text: card.contractType.label,
        ),
        _InfoRow(icon: Icons.home_work_outlined, text: card.workMode.label),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 40),
              Text(label, style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
