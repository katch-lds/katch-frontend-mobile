import 'package:material_ui/material_ui.dart';

import '../models/match_dto.dart';
import 'remote_image.dart';

/// Linha de um match da lista M14, com o logótipo da Empresa, a vaga, a
/// localidade, o estado da vaga e as ações «Ver contacto» e «Abrir conversa»
/// (modelo de classes, 9.4; RF024).
class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.onContact,
    required this.onConversation,
  });

  /// Indicação de vaga que deixou de estar publicada (RF024).
  static const closedJobLabel = 'Vaga encerrada';

  final MatchDto match;
  final VoidCallback onContact;
  final VoidCallback onConversation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: Key('match-${match.matchId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RemoteImage(url: match.logoUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.jobTitle, style: textTheme.titleMedium),
                      Text(match.companyName),
                      Text(match.locationName, style: textTheme.bodySmall),
                      if (match.isJobClosed)
                        Text(
                          closedJobLabel,
                          key: Key('match-closed-${match.matchId}'),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: Key('match-contact-${match.matchId}'),
                  onPressed: onContact,
                  icon: const Icon(Icons.contact_mail_outlined),
                  label: const Text('Ver contacto'),
                ),
                FilledButton.icon(
                  key: Key('match-chat-${match.matchId}'),
                  onPressed: onConversation,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Abrir conversa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de contacto que abre a aplicação externa (modelo de classes, 9.4;
/// RF025).
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value),
      subtitle: Text(label),
      trailing: const Icon(Icons.open_in_new),
      onTap: onTap,
    );
  }
}
