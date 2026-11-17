import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/models/company_page_dto.dart';
import 'package:katch_mobile/models/job_card_dto.dart';
import 'package:katch_mobile/models/job_detail_dto.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/quota_dto.dart';

import '../support/exploration_fakes.dart';

void main() {
  test('JobCardDto lê o cartão da API v02 (RF013, RF015)', () {
    final card = JobCardDto.fromJson(cardJson());

    expect(card.jobId, '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a805');
    expect(card.title, 'Programador Backend .NET');
    expect(card.companyName, 'Lumen Software, Lda.');
    expect(card.logoUrl, '/api/files/logo/l.png');
    expect(card.minSalary, 1600);
    expect(card.maxSalary, 2100.0);
    expect(card.locationName, 'Braga (Braga)');
    expect(card.distanceKm, 22);
    expect(card.contractType, ContractType.permanent);
    expect(card.workMode, WorkMode.hybrid);
    expect(card.isUrgent, isTrue);
    expect(card.photoUrls, ['/api/files/job-photo/a.jpg']);
  });

  test('JobCardDto sem logótipo nem fotografias', () {
    final json = cardJson(logoUrl: null)..remove('photoUrls');

    final card = JobCardDto.fromJson(json);

    expect(card.logoUrl, isNull);
    expect(card.photoUrls, isEmpty);
  });

  test('JobCardDto rejeita um regime desconhecido', () {
    final json = cardJson()..['workMode'] = 'AO_LUAR';

    expect(() => JobCardDto.fromJson(json), throwsFormatException);
  });

  test('JobDetailDto lê o cartão, a descrição, as listas e a Empresa', () {
    final detail = JobDetailDto.fromJson({
      'card': cardJson(),
      'description': 'APIs REST em ASP.NET Core.',
      'skills': ['C#', 'SQL'],
      'benefits': <Object?>[],
      'companyId': 'c4e5f6a7-b8c9-4d0e-a1f2-b3c4d5e6f703',
    });

    expect(detail.card.title, 'Programador Backend .NET');
    expect(detail.description, 'APIs REST em ASP.NET Core.');
    expect(detail.skills, ['C#', 'SQL']);
    expect(detail.benefits, isEmpty);
    expect(detail.companyId, 'c4e5f6a7-b8c9-4d0e-a1f2-b3c4d5e6f703');
  });

  test('CompanyPageDto lê a página, com os campos opcionais em falta', () {
    final page = CompanyPageDto.fromJson({
      'companyId': 'c4e5f6a7-b8c9-4d0e-a1f2-b3c4d5e6f703',
      'companyName': 'Lumen Software, Lda.',
      'description': null,
      'website': 'https://www.lumen-exemplo.pt',
      'logoUrl': null,
      'photoUrls': ['/api/files/company-photo/a.jpg'],
    });

    expect(page.companyName, 'Lumen Software, Lda.');
    expect(page.description, isNull);
    expect(page.website, 'https://www.lumen-exemplo.pt');
    expect(page.logoUrl, isNull);
    expect(page.photoUrls, hasLength(1));
  });

  test('QuotaDto lê a quota disponível e a esgotada (RF020, RF022)', () {
    final available = QuotaDto.fromJson({
      'available': 9,
      'total': 10,
      'blockedUntil': null,
    });
    final exhausted = QuotaDto.fromJson({
      'available': 0,
      'total': 10,
      'blockedUntil': '2026-10-10T16:05:00Z',
    });

    expect(available.available, 9);
    expect(available.total, 10);
    expect(available.blockedUntil, isNull);
    expect(available.isExhausted, isFalse);
    expect(exhausted.isExhausted, isTrue);
    expect(exhausted.blockedUntil, DateTime.utc(2026, 10, 10, 16, 5));
  });
}
