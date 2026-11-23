import 'package:material_ui/material_ui.dart';

import '../core/input_rules.dart';
import '../models/conversation_summary_dto.dart';
import '../models/message_dto.dart';
import 'job_formats.dart';

/// Linha de uma conversa da lista M16, com a Empresa, a vaga, o contador de
/// mensagens por ler e a indicação de conversa encerrada (modelo de classes,
/// 9.4; RF027, RF075).
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  /// Indicação da conversa em modo apenas de consulta.
  static const closedLabel = 'Encerrada';

  final ConversationSummaryDto conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    final last = conversation.lastMessageAt;
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('conversation-${conversation.matchId}'),
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
      title: Text(conversation.companyName),
      subtitle: Text(
        [
          conversation.jobTitle,
          if (last != null) 'Última mensagem: ${instantLabel(last)}',
          if (conversation.isReadOnly) closedLabel,
        ].join('\n'),
      ),
      isThreeLine: last != null || conversation.isReadOnly,
      trailing: unread == 0
          ? null
          : Badge(
              key: Key('unread-${conversation.matchId}'),
              label: Text('$unread'),
              backgroundColor: colors.primary,
              textColor: colors.onPrimary,
            ),
    );
  }
}

/// Mensagem do histórico, alinhada pelo remetente, com a data e a hora e, nas
/// mensagens do Candidato, a indicação de leitura (modelo de classes, 9.4;
/// RF028).
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isOwn});

  /// Indicações de leitura das mensagens enviadas pelo Candidato (RF028).
  static const readLabel = 'Lida';
  static const unreadLabel = 'Enviada';

  final MessageDto message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readAt = message.readAt;
    final details = [
      instantLabel(message.sentAt),
      if (isOwn)
        readAt == null ? unreadLabel : readDetail(message.sentAt, readAt),
    ].join(' · ');
    return Align(
      key: Key('message-${message.messageId}'),
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Card(
          color: isOwn ? colors.primaryContainer : colors.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(message.content),
                const SizedBox(height: 4),
                Text(details, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Indicação de leitura: só a hora quando a mensagem é lida no dia do
  /// envio; com a data quando é lida noutro dia (hora local do dispositivo).
  static String readDetail(DateTime sentAt, DateTime readAt) {
    final sent = sentAt.toLocal();
    final read = readAt.toLocal();
    final sameDay =
        sent.year == read.year &&
        sent.month == read.month &&
        sent.day == read.day;
    if (!sameDay) {
      return '$readLabel às ${instantLabel(readAt)}';
    }
    String two(int value) => value.toString().padLeft(2, '0');
    return '$readLabel às ${two(read.hour)}:${two(read.minute)}';
  }
}

/// Caixa de escrita com o contador «n/1000» e o botão «Enviar»; desativada
/// quando a conversa é só de consulta (modelo de classes, 9.4; RF026, RF075).
class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool canSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat-composer'),
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 4,
              maxLength: InputRules.maxMessageLength,
              decoration: const InputDecoration(
                hintText: 'Escreva uma mensagem',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FilledButton(
              key: const Key('chat-send'),
              onPressed: enabled && canSend ? onSend : null,
              child: const Text('Enviar'),
            ),
          ),
        ],
      ),
    );
  }
}
