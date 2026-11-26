import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/matches_controller.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';
import '../../widgets/job_formats.dart';
import '../../widgets/match_widgets.dart';
import '../conversations/chat_screen.dart';

/// Contacto da Empresa depois do match, M15 (RF025). Partilha o
/// `MatchesController` de M14: os contactos já vêm na lista, sem novo pedido.
class MatchContactScreen extends StatelessWidget {
  const MatchContactScreen({
    super.key,
    required this.controller,
    required this.matchId,
  });

  final MatchesController controller;
  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacto da Empresa')),
      body: Column(
        children: [
          ConnectionBanner(monitor: AppScope.of(context).monitor),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final match = controller.find(matchId);
                if (match == null) {
                  return const Center(
                    child: Text('O match já não está disponível.'),
                  );
                }
                final textTheme = Theme.of(context).textTheme;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(match.companyName, style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(match.jobTitle, style: textTheme.titleMedium),
                    Text(match.locationName),
                    if (match.isJobClosed)
                      Text(
                        MatchTile.closedJobLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Match desde ${instantLabel(match.matchedAt)}',
                      style: textTheme.bodySmall,
                    ),
                    const Divider(height: 32),
                    Text('Recrutador', style: textTheme.labelLarge),
                    Text(match.counterpartName),
                    const SizedBox(height: 8),
                    ContactRow(
                      key: const Key('contact-email'),
                      icon: Icons.email_outlined,
                      label: 'Correio eletrónico',
                      value: match.contactEmail,
                      onTap: () => unawaited(controller.openEmail(match)),
                    ),
                    ContactRow(
                      key: const Key('contact-phone'),
                      icon: Icons.phone_outlined,
                      label: 'Telefone',
                      value: match.contactPhone,
                      onTap: () => unawaited(controller.openPhone(match)),
                    ),
                    FormMessage(message: controller.message),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('contact-chat'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(matchId: matchId),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Abrir conversa'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
