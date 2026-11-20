import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../models/job_detail_dto.dart';
import '../../state/job_detail_controller.dart';
import '../../state/load_status.dart';
import '../../widgets/job_card_view.dart';
import '../../widgets/katch_scaffold.dart';
import '../../widgets/load_state_view.dart';
import 'company_page_screen.dart';

/// Detalhe da vaga, M12 (RF016).
///
/// Mostra os dados do cartão, a descrição completa, as competências e os
/// benefícios, e abre a página de apresentação da Empresa (RF017).
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  static const failedFallback = 'Não foi possível obter a vaga.';
  static const noBenefits = 'A vaga não indica benefícios.';

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final JobDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JobDetailController(
      service: AppScope.of(context).jobExploration,
    );
    unawaited(_controller.load(widget.jobId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCompany(String companyId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyPageScreen(companyId: companyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KatchScaffold(
      title: 'Detalhe da vaga',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final detail = _controller.detail;
          return LoadStatusView(
            failed: _controller.status == LoadStatus.failed,
            message: _controller.errorMessage,
            fallback: JobDetailScreen.failedFallback,
            onRetry: () => unawaited(_controller.load(widget.jobId)),
            child: detail == null ? null : _buildDetail(context, detail),
          );
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, JobDetailDto detail) {
    final dependencies = AppScope.of(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return SingleChildScrollView(
      key: const Key('job-detail-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobSummary(
            card: detail.card,
            baseUrl: dependencies.config.apiBaseUrl,
            credentials: dependencies.session,
          ),
          const SizedBox(height: 16),
          Text('Descrição', style: titleStyle),
          const SizedBox(height: 4),
          Text(detail.description, key: const Key('job-description')),
          const SizedBox(height: 16),
          Text('Competências', style: titleStyle),
          const SizedBox(height: 4),
          _Labels(names: detail.skills),
          const SizedBox(height: 16),
          Text('Benefícios', style: titleStyle),
          const SizedBox(height: 4),
          detail.benefits.isEmpty
              ? const Text(JobDetailScreen.noBenefits)
              : _Labels(names: detail.benefits),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('job-company'),
            onPressed: () => _openCompany(detail.companyId),
            icon: const Icon(Icons.business),
            label: const Text('Ver página da Empresa'),
          ),
        ],
      ),
    );
  }
}

class _Labels extends StatelessWidget {
  const _Labels({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final name in names) Chip(label: Text(name))],
    );
  }
}
