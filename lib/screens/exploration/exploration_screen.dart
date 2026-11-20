import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/exploration_controller.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/form_message.dart';
import '../../widgets/job_card_view.dart';
import '../../widgets/load_state_view.dart';
import '../../widgets/quota_indicator.dart';
import '../profile/preferences_screen.dart';
import 'job_detail_screen.dart';

/// Exploração de vagas, M09, com os estados M10 (quota esgotada) e M11 (sem
/// vagas), do UC05.
class ExplorationScreen extends StatefulWidget {
  const ExplorationScreen({super.key});

  static const emptyTitle =
      'Não há vagas compatíveis com as suas preferências.';
  static const emptyHint =
      'Ajuste as preferências de procura para ver outras vagas.';
  static const failedFallback = 'Não foi possível obter as vagas.';

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  late final ExplorationController _controller;

  /// Aumenta em cada resposta a um cartão: o cartão seguinte, ou o mesmo
  /// cartão depois de uma falha, é sempre um widget novo, já sem o deslize.
  int _answers = 0;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = ExplorationController(
      service: dependencies.jobExploration,
      profile: dependencies.profile,
      lifecycle: dependencies.lifecycle,
      clock: dependencies.clock,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decline() {
    setState(() => _answers++);
    unawaited(_controller.decline());
  }

  void _interest() {
    setState(() => _answers++);
    unawaited(_controller.expressInterest());
  }

  void _openDetail(String jobId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JobDetailScreen(jobId: jobId)),
    );
  }

  /// Ajuste das preferências na área de exploração (RF023): ao gravar, o
  /// `ProfileStore` avisa o controller, que volta a pedir os cartões.
  void _openPreferences() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PreferencesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            ..._buildQuotaNotice(),
            if (status != ExplorationStatus.failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormMessage(message: _controller.message),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildBody(status),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final quota = _controller.quota;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: quota == null
                ? const SizedBox.shrink()
                : QuotaIndicator(
                    available: quota.available,
                    total: quota.total,
                  ),
          ),
          TextButton.icon(
            key: const Key('exploration-preferences'),
            onPressed: _openPreferences,
            icon: const Icon(Icons.tune),
            label: const Text('Preferências'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuotaNotice() {
    final remaining = _controller.remainingBlock;
    final quota = _controller.quota;
    final until = quota?.blockedUntil;
    if (remaining == null || quota == null || until == null) {
      return const [];
    }
    return [
      const SizedBox(height: 8),
      QuotaBlockedNotice(
        remaining: remaining,
        total: quota.total,
        blockedUntil: until,
      ),
    ];
  }

  Widget _buildBody(ExplorationStatus status) {
    final card = _controller.currentCard;
    switch (status) {
      case ExplorationStatus.loading:
        return const LoadStateView.loading();
      case ExplorationStatus.failed:
        return LoadStateView.failed(
          message: _controller.message,
          onRetry: () => unawaited(_controller.load()),
          fallback: ExplorationScreen.failedFallback,
        );
      case ExplorationStatus.empty:
        return EmptyStateView(
          title: ExplorationScreen.emptyTitle,
          hint: ExplorationScreen.emptyHint,
          actionLabel: 'Ajustar preferências',
          onAction: _openPreferences,
        );
      case ExplorationStatus.card:
      case ExplorationStatus.quotaExhausted:
        final dependencies = AppScope.of(context);
        return JobCardView(
          key: ValueKey(_answers),
          card: card!,
          interestEnabled: status == ExplorationStatus.card,
          onDecline: _decline,
          onInterest: _interest,
          onDetail: () => _openDetail(card.jobId),
          baseUrl: dependencies.config.apiBaseUrl,
          credentials: dependencies.session,
        );
    }
  }
}
