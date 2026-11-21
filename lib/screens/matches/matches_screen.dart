import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../models/match_dto.dart';
import '../../state/load_status.dart';
import '../../state/matches_controller.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_state_view.dart';
import '../../widgets/match_widgets.dart';
import '../conversations/chat_screen.dart';
import 'match_contact_screen.dart';

/// Lista de matches, M14 (modelo de classes, 8.5 e 9.1; UC13; RF024).
///
/// A lista é pedida ao montar o separador e sempre que o Candidato o volta a
/// escolher (`active` passa a verdadeiro). Daqui chega-se ao contacto da
/// Empresa (M15) e à conversa (M17) com um toque (RNF011).
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.active,
    required this.onExplore,
  });

  static const emptyTitle = 'Ainda não tem matches.';
  static const emptyHint =
      'Quando uma Empresa aceitar o seu interesse numa vaga, o match aparece '
      'aqui, com o contacto da Empresa.';
  static const failedFallback = 'Não foi possível obter os matches.';

  /// O separador «Matches» está escolhido.
  final bool active;

  /// Leva o Candidato ao separador «Explorar».
  final VoidCallback onExplore;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late final MatchesController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = MatchesController(
      service: dependencies.matches,
      launcher: dependencies.launcher,
    );
    if (widget.active) {
      unawaited(_controller.load());
    }
  }

  @override
  void didUpdateWidget(MatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openContact(MatchDto match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MatchContactScreen(controller: _controller, matchId: match.matchId),
      ),
    );
  }

  void _openConversation(MatchDto match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(matchId: match.matchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        if (status == LoadStatus.idle || status == LoadStatus.loading) {
          return const LoadStateView.loading();
        }
        if (status == LoadStatus.failed) {
          return LoadStateView.failed(
            message: _controller.message,
            onRetry: () => unawaited(_controller.load()),
            fallback: MatchesScreen.failedFallback,
          );
        }
        final matches = _controller.matches;
        if (matches.isEmpty) {
          return EmptyStateView(
            title: MatchesScreen.emptyTitle,
            hint: MatchesScreen.emptyHint,
            actionLabel: 'Explorar vagas',
            onAction: widget.onExplore,
          );
        }
        final dependencies = AppScope.of(context);
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              FormMessage(message: _controller.message),
              for (final match in matches)
                MatchTile(
                  match: match,
                  baseUrl: dependencies.config.apiBaseUrl,
                  credentials: dependencies.session,
                  onContact: () => _openContact(match),
                  onConversation: () => _openConversation(match),
                ),
            ],
          ),
        );
      },
    );
  }
}
