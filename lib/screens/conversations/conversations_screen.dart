import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/conversations_store.dart';
import '../../state/load_status.dart';
import '../../widgets/conversation_widgets.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_state_view.dart';
import 'chat_screen.dart';

/// Lista de conversas, M16, com o contador de mensagens por ler (UC14;
/// RF027).
///
/// Enquanto o separador está escolhido e nenhuma conversa está aberta por
/// cima, a lista é consultada de 3 em 3 segundos (RF029).
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({
    super.key,
    required this.active,
    required this.onOpenMatches,
  });

  static const emptyTitle = 'Ainda não tem conversas.';
  static const emptyHint =
      'Cada match abre uma conversa com o Recrutador da Empresa.';
  static const failedFallback = 'Não foi possível obter as conversas.';

  /// O separador «Conversas» está escolhido.
  final bool active;

  /// Leva o Candidato ao separador «Matches».
  final VoidCallback onOpenMatches;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationsStore _store;

  /// Uma conversa (M17) está aberta por cima da lista.
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    _store = AppScope.of(context).conversations;
    _syncWatch();
  }

  @override
  void didUpdateWidget(ConversationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _syncWatch();
    }
  }

  @override
  void dispose() {
    _store.watchList(false);
    super.dispose();
  }

  void _syncWatch() => _store.watchList(widget.active && !_chatOpen);

  Future<void> _openChat(String matchId) async {
    _chatOpen = true;
    _syncWatch();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(matchId: matchId)),
    );
    if (!mounted) {
      return;
    }
    _chatOpen = false;
    _syncWatch();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final status = _store.status;
        // Sem pedido feito (separador ainda não escolhido) não há indicador:
        // o separador fica montado no IndexedStack e uma animação contínua
        // manteria a aplicação a desenhar fora do ecrã.
        if (status == LoadStatus.idle) {
          return const SizedBox.shrink();
        }
        if (status == LoadStatus.loading) {
          return const LoadStateView.loading();
        }
        if (status == LoadStatus.failed) {
          return LoadStateView.failed(
            message: _store.message,
            onRetry: () => unawaited(_store.load()),
            fallback: ConversationsScreen.failedFallback,
          );
        }
        final conversations = _store.conversations;
        if (conversations.isEmpty) {
          return EmptyStateView(
            title: ConversationsScreen.emptyTitle,
            hint: ConversationsScreen.emptyHint,
            actionLabel: 'Ver matches',
            onAction: widget.onOpenMatches,
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FormMessage(message: _store.message),
            ),
            for (final conversation in conversations)
              ConversationTile(
                conversation: conversation,
                onTap: () => unawaited(_openChat(conversation.matchId)),
              ),
          ],
        );
      },
    );
  }
}
