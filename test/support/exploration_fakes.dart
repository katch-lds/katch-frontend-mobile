import 'dart:async';

import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/clock.dart';
import 'package:katch_mobile/core/external_launcher.dart';
import 'package:katch_mobile/models/api_error_dto.dart';
import 'package:katch_mobile/models/company_page_dto.dart';
import 'package:katch_mobile/models/job_card_dto.dart';
import 'package:katch_mobile/models/job_detail_dto.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/quota_dto.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/services/job_exploration_service.dart';

/// Empresa fictícia das vagas de teste.
const lumenId = 'c4e5f6a7-b8c9-4d0e-a1f2-b3c4d5e6f703';

/// Cartão no formato JSON da API v02 (6.3.1).
Map<String, Object?> cardJson({Object? logoUrl = '/api/files/logo/l.png'}) => {
  'jobId': '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a805',
  'title': 'Programador Backend .NET',
  'companyName': 'Lumen Software, Lda.',
  'logoUrl': logoUrl,
  'minSalary': 1600.00,
  'maxSalary': 2100,
  'locationName': 'Braga (Braga)',
  'distanceKm': 22,
  'contractType': 'PERMANENT',
  'workMode': 'HYBRID',
  'isUrgent': true,
  'photoUrls': ['/api/files/job-photo/a.jpg'],
};

/// Cartão de vaga fictício (dados de teste, API v02, 6.3.1).
JobCardDto sampleCard({
  String jobId = '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a805',
  String title = 'Programador Backend .NET',
  String? logoUrl = '/api/files/company-logo/lumen.png',
  double minSalary = 1600,
  double maxSalary = 2100,
  String locationName = 'Braga (Braga)',
  int distanceKm = 22,
  ContractType contractType = ContractType.permanent,
  WorkMode workMode = WorkMode.hybrid,
  bool isUrgent = true,
  List<String> photoUrls = const ['/api/files/job-photo/escritorio.jpg'],
}) {
  return JobCardDto(
    jobId: jobId,
    title: title,
    companyName: 'Lumen Software, Lda.',
    logoUrl: logoUrl,
    minSalary: minSalary,
    maxSalary: maxSalary,
    locationName: locationName,
    distanceKm: distanceKm,
    contractType: contractType,
    workMode: workMode,
    isUrgent: isUrgent,
    photoUrls: photoUrls,
  );
}

/// Três vagas fictícias: híbrida a 22 km, presencial a 80 km e remota a 300 km.
List<JobCardDto> sampleDeck() => [
  sampleCard(),
  sampleCard(
    jobId: '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a806',
    title: 'Analista de Dados',
    logoUrl: null,
    minSalary: 1200,
    maxSalary: 1500.5,
    locationName: 'Porto (Porto)',
    distanceKm: 80,
    contractType: ContractType.fixedTerm,
    workMode: WorkMode.onSite,
    isUrgent: false,
    photoUrls: const [],
  ),
  sampleCard(
    jobId: '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a807',
    title: 'Programador Flutter',
    minSalary: 2000,
    maxSalary: 2000,
    locationName: 'Faro (Faro)',
    distanceKm: 300,
    contractType: ContractType.serviceProvision,
    workMode: WorkMode.remote,
    isUrgent: false,
  ),
];

JobDetailDto sampleDetail(
  JobCardDto card, {
  List<String> benefits = const ['Seguro de saúde'],
}) {
  return JobDetailDto(
    card: card,
    description:
        'Desenvolvimento e manutenção de APIs REST em ASP.NET Core para '
        'clientes do setor da logística.',
    skills: const ['C#', 'SQL', 'Docker'],
    benefits: benefits,
    companyId: lumenId,
  );
}

const sampleCompany = CompanyPageDto(
  companyId: lumenId,
  companyName: 'Lumen Software, Lda.',
  description:
      'Software de gestão de frotas e armazéns, com equipas em Braga e no '
      'Porto.',
  website: 'https://www.lumen-exemplo.pt',
  logoUrl: '/api/files/company-logo/lumen.png',
  photoUrls: [
    '/api/files/company-photo/a.jpg',
    '/api/files/company-photo/b.jpg',
  ],
);

/// Motivo do ERR-31 (API v02, 6.3.5).
const quotaExhaustedMessage =
    'Esgotou a quota de interesses. Pode voltar a manifestar interesse dentro '
    'de 24 h 0 min.';

/// Motivo do ERR-33 (API v02, 4.3).
const unavailableMessage = 'A vaga deixou de estar disponível.';

/// `JobExplorationService` simulado, com o comportamento do servidor descrito
/// na API v02 (6.3): os cartões respeitam as preferências de procura (RF014);
/// uma vaga respondida deixa de aparecer (RF018, RF019); cada interesse reduz a
/// quota e o 10.º bloqueia-a durante 24 horas (RF020); a quota é reposta no
/// pedido seguinte ao fim do bloqueio (RF021).
class FakeJobExplorationService implements JobExplorationService {
  FakeJobExplorationService({
    required Clock clock,
    SearchPreferencesDto Function()? preferences,
    List<JobCardDto>? cards,
  }) : _clock = clock,
       _preferences = preferences,
       cards = cards ?? sampleDeck();

  static const total = 10;
  static const blockPeriod = Duration(hours: 24);

  final Clock _clock;
  final SearchPreferencesDto Function()? _preferences;

  /// Vagas publicadas «no servidor» ainda sem resposta do Candidato.
  List<JobCardDto> cards;

  QuotaDto quota = const QuotaDto(available: total, total: total);

  /// Benefícios do detalhe das vagas.
  List<String> benefits = const ['Seguro de saúde'];

  /// Página da Empresa devolvida por `getCompanyPage`.
  CompanyPageDto company = sampleCompany;

  /// Com `false`, o servidor ainda não repôs a quota no fim do bloqueio.
  bool restores = true;

  final calls = <String>[];

  /// Falha a lançar pela operação com este nome (por exemplo, `decline`).
  final failures = <String, Object Function()>{};

  /// Pedidos retidos até o teste completar o `Completer` da operação.
  final holds = <String, Completer<void>>{};

  Future<void> _call(String name, [String? argument]) async {
    calls.add(argument == null ? name : '$name:$argument');
    final hold = holds[name];
    if (hold != null) {
      await hold.future;
    }
    final failure = failures[name];
    if (failure != null) {
      throw failure();
    }
  }

  void _restoreIfDue() {
    final until = quota.blockedUntil;
    if (restores && until != null && !_clock.now().isBefore(until)) {
      quota = const QuotaDto(available: total, total: total);
    }
  }

  bool _matches(JobCardDto card) {
    final preferences = _preferences?.call();
    if (preferences == null) {
      return true;
    }
    final distance = preferences.maxDistanceKm;
    final salary = preferences.minSalaryExpectation;
    return (distance == null ||
            card.workMode == WorkMode.remote ||
            card.distanceKm <= distance) &&
        (salary == null || card.maxSalary >= salary) &&
        (preferences.workModes.isEmpty ||
            preferences.workModes.contains(card.workMode)) &&
        (preferences.contractTypes.isEmpty ||
            preferences.contractTypes.contains(card.contractType));
  }

  @override
  Future<JobCardDto?> getNextCard() async {
    await _call('getNextCard');
    for (final card in cards) {
      if (_matches(card)) {
        return card;
      }
    }
    return null;
  }

  @override
  Future<JobDetailDto> getDetail(String jobId) async {
    await _call('getDetail', jobId);
    final card = cards.firstWhere((card) => card.jobId == jobId);
    return sampleDetail(card, benefits: benefits);
  }

  @override
  Future<CompanyPageDto> getCompanyPage(String companyId) async {
    await _call('getCompanyPage', companyId);
    return company;
  }

  @override
  Future<void> decline(String jobId) async {
    await _call('decline', jobId);
    cards = [...cards.where((card) => card.jobId != jobId)];
  }

  @override
  Future<QuotaDto> expressInterest(String jobId) async {
    await _call('expressInterest', jobId);
    _restoreIfDue();
    if (quota.isExhausted) {
      throw ApiRejection(
        ApiErrorDto(
          code: 'ERR-31',
          message: quotaExhaustedMessage,
          blockedUntil: quota.blockedUntil,
        ),
      );
    }
    cards = [...cards.where((card) => card.jobId != jobId)];
    final available = quota.available - 1;
    quota = QuotaDto(
      available: available,
      total: total,
      blockedUntil: available == 0 ? _clock.now().add(blockPeriod) : null,
    );
    return quota;
  }

  @override
  Future<QuotaDto> getQuota() async {
    await _call('getQuota');
    _restoreIfDue();
    return quota;
  }
}

/// Navegador simulado: regista os endereços e devolve `opens`.
class FakeLauncher implements ExternalLauncher {
  final urls = <String>[];
  bool opens = true;

  @override
  Future<bool> openUrl(String url) async {
    urls.add(url);
    return opens;
  }
}
