import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../models/conversation_summary_dto.dart';
import '../../state/chat_controller.dart';
import '../../state/load_status.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/conversation_widgets.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_state_view.dart';

/// Conversa com o Recrutador, M17, e o estado só de consulta, M18 (modelo de
/// classes, 8.5 e 9.1; UC14; RF026, RF028 a RF030, RF070, RF075).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.matchId});

  static const failedFallback = 'Não foi possível obter a conversa.';

  /// Textos do estado só de consulta (M18).
  static const closedByMeText = 'Encerrou esta conversa.';
  static const closedByCompanyText = 'A Empresa encerrou esta conversa.';
  static const suspendedText =
      'A conversa foi encerrada porque a conta da Empresa foi suspensa.';
  static const readOnlyHint =
      'Pode consultar o histórico, mas não enviar '
      'mensagens.';

  static const closeConfirmation =
      'Depois de encerrada, a conversa fica só de consulta e nenhuma das '
      'partes pode enviar mensagens.';

  final String matchId;

  /// Texto do estado só de consulta, conforme o motivo e quem encerrou.
  static String readOnlyText(ChatController controller) {
    final reason = controller.summary?.closeReason;
    if (reason == ConversationCloseReason.companySuspended ||
        reason == ConversationCloseReason.accountBlockedOrSuspended) {
      return suspendedText;
    }
    return controller.closedByMe ? closedByMeText : closedByCompanyText;
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  int _shownMessages = 0;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = ChatController(
      service: dependencies.conversationService,
      store: dependencies.conversations,
      session: dependencies.session,
      lifecycle: dependencies.lifecycle,
    );
    _controller.addListener(_onChanged);
    unawaited(_controller.open(widget.matchId));
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Mantém a caixa de escrita igual ao rascunho (limpa depois de enviar) e
  /// desce até à última mensagem quando chegam mensagens novas.
  void _onChanged() {
    if (_draft.text != _controller.draft) {
      _draft.text = _controller.draft;
    }
    final count = _controller.messages.length;
    if (count != _shownMessages) {
      _shownMessages = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _confirmClose() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar conversa?'),
        content: const Text(ChatScreen.closeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('chat-close-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final loaded = _controller.status == LoadStatus.loaded;
        return Scaffold(
          appBar: AppBar(
            title: Text(summary?.companyName ?? 'Conversa'),
            bottom: summary == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(24),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${summary.jobTitle} · ${summary.counterpartName}',
                      ),
                    ),
                  ),
            actions: [
              if (loaded && !_controller.isReadOnly)
                IconButton(
                  key: const Key('chat-close'),
                  tooltip: 'Encerrar conversa',
                  onPressed: _controller.isClosing
                      ? null
                      : () => unawaited(_confirmClose()),
                  icon: const Icon(Icons.block),
                ),
            ],
          ),
          // Faixa de falha de ligação: as consultas periódicas sem resposta
          // ficam indicadas sem sair da conversa (RNF014).
          body: Column(
            children: [
              ConnectionBanner(monitor: AppScope.of(context).monitor),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_controller.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadStateView.loading();
      case LoadStatus.failed:
        return LoadStateView.failed(
          message: _controller.errorMessage,
          onRetry: () => unawaited(_controller.open(widget.matchId)),
          fallback: ChatScreen.failedFallback,
        );
      case LoadStatus.loaded:
        final messages = _controller.messages;
        final readOnly = _controller.isReadOnly;
        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Ainda não há mensagens nesta conversa.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => MessageBubble(
                        message: messages[index],
                        isOwn: _controller.isOwn(messages[index]),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FormMessage(message: _controller.errorMessage),
            ),
            if (readOnly)
              Container(
                key: const Key('chat-read-only'),
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${ChatScreen.readOnlyText(_controller)} '
                  '${ChatScreen.readOnlyHint}',
                  textAlign: TextAlign.center,
                ),
              ),
            MessageComposer(
              controller: _draft,
              enabled: !readOnly,
              canSend: _controller.canSend,
              onChanged: _controller.updateDraft,
              onSend: () => unawaited(_controller.send()),
            ),
          ],
        );
    }
  }
}
