import '../core/api_client.dart';
import '../models/company_page_dto.dart';
import '../models/job_card_dto.dart';
import '../models/job_detail_dto.dart';
import '../models/quota_dto.dart';
import 'job_exploration_service.dart';
import 'response_reader.dart';

/// `JobExplorationService` sobre a API v02 (`/api/candidate/jobs`, 6.3).
class HttpJobExplorationService implements JobExplorationService {
  HttpJobExplorationService(this._api);

  static const jobsPath = '/api/candidate/jobs';
  static const nextPath = '$jobsPath/next';
  static const quotaPath = '$jobsPath/quota';
  static const companiesPath = '$jobsPath/companies';

  final ApiClient _api;

  @override
  Future<JobCardDto?> getNextCard() async {
    // `204 No Content` (sem corpo) quando nenhuma vaga cumpre o filtro.
    final result = await _api.get(nextPath);
    if (result == null) {
      return null;
    }
    return readModel(() => JobCardDto.fromJson(readObject(result)));
  }

  @override
  Future<JobDetailDto> getDetail(String jobId) async {
    final result = await _api.get(_jobPath(jobId));
    return readModel(() => JobDetailDto.fromJson(readObject(result)));
  }

  @override
  Future<CompanyPageDto> getCompanyPage(String companyId) async {
    final result = await _api.get(
      '$companiesPath/${Uri.encodeComponent(companyId)}',
    );
    return readModel(() => CompanyPageDto.fromJson(readObject(result)));
  }

  @override
  Future<void> decline(String jobId) async {
    await _api.post('${_jobPath(jobId)}/decline');
  }

  @override
  Future<QuotaDto> expressInterest(String jobId) async {
    return _quota(await _api.post('${_jobPath(jobId)}/interest'));
  }

  @override
  Future<QuotaDto> getQuota() async => _quota(await _api.get(quotaPath));

  static String _jobPath(String jobId) {
    return '$jobsPath/${Uri.encodeComponent(jobId)}';
  }

  static QuotaDto _quota(Object? result) {
    return readModel(() => QuotaDto.fromJson(readObject(result)));
  }
}
