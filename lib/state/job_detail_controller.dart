import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/job_detail_dto.dart';
import '../services/job_exploration_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';

/// Estado de M12, detalhe da vaga (RF016).
class JobDetailController extends ChangeNotifier {
  JobDetailController({required JobExplorationService service})
    : _service = service;

  final JobExplorationService _service;

  JobDetailDto? _detail;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _disposed = false;

  JobDetailDto? get detail => _detail;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  /// Pede a descrição completa, as competências e os benefícios da vaga.
  Future<void> load(String jobId) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      _detail = await _service.getDetail(jobId);
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
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
