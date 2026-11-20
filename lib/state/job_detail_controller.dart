import '../core/api_exception.dart';
import '../models/job_detail_dto.dart';
import '../services/job_exploration_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'safe_change_notifier.dart';

/// Estado de M12, detalhe da vaga (RF016).
class JobDetailController extends SafeChangeNotifier {
  JobDetailController({required JobExplorationService service})
    : _service = service;

  final JobExplorationService _service;

  JobDetailDto? _detail;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  JobDetailDto? get detail => _detail;

  LoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  /// Pede a descrição completa, as competências e os benefícios da vaga.
  Future<void> load(String jobId) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _detail = await _service.getDetail(jobId);
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    notifyListeners();
  }
}
