import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/external_launcher.dart';
import '../models/company_page_dto.dart';
import '../services/job_exploration_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';

/// Estado de M13, página de apresentação da Empresa (modelo de classes, 8.4;
/// RF017).
class CompanyPageController extends ChangeNotifier {
  CompanyPageController({
    required JobExplorationService service,
    required ExternalLauncher launcher,
  }) : _service = service,
       _launcher = launcher;

  /// Indicação quando o navegador do dispositivo não abre o endereço.
  static const websiteFailureMessage =
      'Não foi possível abrir o sítio na Internet.';

  final JobExplorationService _service;
  final ExternalLauncher _launcher;

  CompanyPageDto? _page;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _disposed = false;

  CompanyPageDto? get page => _page;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  /// Pede a designação, a descrição, o sítio, o logótipo e a galeria.
  Future<void> load(String companyId) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      _page = await _service.getCompanyPage(companyId);
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    _notify();
  }

  /// Abre o sítio na Internet da Empresa no navegador do dispositivo.
  Future<void> openWebsite() async {
    final website = _page?.website;
    if (website == null) {
      return;
    }
    final opened = await _launcher.openUrl(website);
    _errorMessage = opened ? null : websiteFailureMessage;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
