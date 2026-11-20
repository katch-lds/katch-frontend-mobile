import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../models/company_page_dto.dart';
import '../../state/company_page_controller.dart';
import '../../state/load_status.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_state_view.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/remote_image.dart';

/// Página de apresentação da Empresa, M13 (RF017).
///
/// Designação, logótipo, descrição, sítio na Internet e galeria. Os contactos
/// da Empresa só são dados depois do match (RF025).
class CompanyPageScreen extends StatefulWidget {
  const CompanyPageScreen({super.key, required this.companyId});

  final String companyId;

  static const failedFallback = 'Não foi possível obter a página da Empresa.';
  static const noDescription = 'A Empresa ainda não tem descrição.';

  @override
  State<CompanyPageScreen> createState() => _CompanyPageScreenState();
}

class _CompanyPageScreenState extends State<CompanyPageScreen> {
  late final CompanyPageController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = CompanyPageController(
      service: dependencies.jobExploration,
      launcher: dependencies.launcher,
    );
    unawaited(_controller.load(widget.companyId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context).monitor;
    return Scaffold(
      appBar: AppBar(title: const Text('Empresa')),
      body: Column(
        children: [
          ConnectionBanner(monitor: monitor),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final page = _controller.page;
                if (_controller.status == LoadStatus.failed) {
                  return LoadStateView.failed(
                    message: _controller.errorMessage,
                    onRetry: () =>
                        unawaited(_controller.load(widget.companyId)),
                    fallback: CompanyPageScreen.failedFallback,
                  );
                }
                if (page == null) {
                  return const LoadStateView.loading();
                }
                return _buildPage(context, page);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, CompanyPageDto page) {
    final dependencies = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final website = page.website;
    return SingleChildScrollView(
      key: const Key('company-page-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RemoteImage(
                url: page.logoUrl,
                baseUrl: dependencies.config.apiBaseUrl,
                credentials: dependencies.session,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(page.companyName, style: textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            page.description ?? CompanyPageScreen.noDescription,
            key: const Key('company-description'),
          ),
          if (website != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('company-website'),
                onPressed: () => unawaited(_controller.openWebsite()),
                icon: const Icon(Icons.open_in_new),
                label: Text(website),
              ),
            ),
          ],
          FormMessage(message: _controller.errorMessage),
          if (page.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Galeria', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            PhotoGrid(
              urls: page.photoUrls,
              baseUrl: dependencies.config.apiBaseUrl,
              credentials: dependencies.session,
            ),
          ],
        ],
      ),
    );
  }
}
