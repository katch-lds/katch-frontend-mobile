import '../models/company_page_dto.dart';
import '../models/job_card_dto.dart';
import '../models/job_detail_dto.dart';
import '../models/quota_dto.dart';

/// Operações do `JobExplorationController` (API v02, secção 6.3).
///
/// O servidor obtém o Candidato da credencial de sessão e aplica as
/// preferências de procura guardadas no perfil (RF014).
abstract interface class JobExplorationService {
  /// Cartão de vaga seguinte, ou `null` sem vagas compatíveis (6.3.1; RF013 a
  /// RF015).
  Future<JobCardDto?> getNextCard();

  /// Detalhe da vaga (6.3.2; RF016).
  Future<JobDetailDto> getDetail(String jobId);

  /// Página de apresentação da Empresa (6.3.3; RF017).
  Future<CompanyPageDto> getCompanyPage(String companyId);

  /// Recusa a vaga, sem consumir a quota (6.3.4; RF018).
  Future<void> decline(String jobId);

  /// Manifesta interesse e devolve a quota atualizada (6.3.5; RF019, RF020).
  Future<QuotaDto> expressInterest(String jobId);

  /// Interesses disponíveis e fim do bloqueio (6.3.6; RF021, RF022).
  Future<QuotaDto> getQuota();
}
