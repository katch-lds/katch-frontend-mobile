import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/services/http_job_exploration_service.dart';

import '../support/exploration_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeApiClient api;
  late HttpJobExplorationService service;

  const jobId = '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a805';
  const companyId = 'c4e5f6a7-b8c9-4d0e-a1f2-b3c4d5e6f703';
  final quotaJson = {'available': 9, 'total': 10, 'blockedUntil': null};

  setUp(() {
    api = FakeApiClient();
    service = HttpJobExplorationService(api);
  });

  test('getNextCard pede o cartão seguinte (6.3.1)', () async {
    api.response = cardJson();

    final card = await service.getNextCard();

    expect(api.calls, ['GET /api/candidate/jobs/next']);
    expect(card?.jobId, jobId);
  });

  test('getNextCard devolve null com 204 No Content (sem vagas)', () async {
    api.response = null;

    expect(await service.getNextCard(), isNull);
  });

  test('getDetail e getCompanyPage pedem as rotas 6.3.2 e 6.3.3', () async {
    api.response = {
      'card': cardJson(),
      'description': 'Descrição.',
      'skills': ['C#'],
      'benefits': ['Seguro de saúde'],
      'companyId': companyId,
    };
    final detail = await service.getDetail(jobId);
    api.response = {
      'companyId': companyId,
      'companyName': 'Lumen Software, Lda.',
      'photoUrls': <Object?>[],
    };
    final page = await service.getCompanyPage(companyId);

    expect(api.calls, [
      'GET /api/candidate/jobs/$jobId',
      'GET /api/candidate/jobs/companies/$companyId',
    ]);
    expect(detail.companyId, companyId);
    expect(page.companyName, 'Lumen Software, Lda.');
  });

  test(
    'decline e expressInterest enviam POST sem corpo (6.3.4, 6.3.5)',
    () async {
      api.response = null;
      await service.decline(jobId);
      api.response = quotaJson;
      final quota = await service.expressInterest(jobId);

      expect(api.calls, [
        'POST /api/candidate/jobs/$jobId/decline',
        'POST /api/candidate/jobs/$jobId/interest',
      ]);
      expect(api.bodies, [null, null]);
      expect(quota.available, 9);
    },
  );

  test('getQuota pede a quota (6.3.6)', () async {
    api.response = quotaJson;

    final quota = await service.getQuota();

    expect(api.calls, ['GET /api/candidate/jobs/quota']);
    expect(quota.total, 10);
  });

  test('uma resposta fora do contrato é UnexpectedFailure', () async {
    api.response = {'available': 'nove'};

    expect(service.getQuota(), throwsA(isA<UnexpectedFailure>()));
  });

  test('as rejeições da API chegam ao chamador', () async {
    api.failure = rejection('ERR-32', 'Já respondeu a esta vaga.');

    expect(service.decline(jobId), throwsA(isA<ApiRejection>()));
  });
}
