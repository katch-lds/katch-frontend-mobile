import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/state/company_page_controller.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/job_detail_controller.dart';
import 'package:katch_mobile/state/load_status.dart';

import '../support/exploration_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeJobExplorationService service;

  setUp(() => service = FakeJobExplorationService(clock: FakeClock()));

  group('JobDetailController (M12, RF016)', () {
    late JobDetailController controller;

    setUp(() => controller = JobDetailController(service: service));
    tearDown(() => controller.dispose());

    test(
      'obtém a descrição, as competências, os benefícios e a Empresa',
      () async {
        final card = sampleDeck().first;

        await controller.load(card.jobId);

        expect(service.calls, ['getDetail:${card.jobId}']);
        expect(controller.status, LoadStatus.loaded);
        expect(controller.detail?.card.title, card.title);
        expect(controller.detail?.description, startsWith('Desenvolvimento'));
        expect(controller.detail?.skills, ['C#', 'SQL', 'Docker']);
        expect(controller.detail?.benefits, ['Seguro de saúde']);
        expect(controller.detail?.companyId, lumenId);
      },
    );

    test('vaga indisponível (ERR-20) indica o motivo', () async {
      service.failures['getDetail'] = () =>
          rejection('ERR-20', 'O elemento pedido não existe.');

      await controller.load('vaga-retirada');

      expect(controller.status, LoadStatus.failed);
      expect(controller.errorMessage, 'O elemento pedido não existe.');
    });
  });

  group('CompanyPageController (M13, RF017)', () {
    late FakeLauncher launcher;
    late CompanyPageController controller;

    setUp(() {
      launcher = FakeLauncher();
      controller = CompanyPageController(service: service, launcher: launcher);
    });
    tearDown(() => controller.dispose());

    test('obtém a página da Empresa e abre o sítio', () async {
      await controller.load(lumenId);
      await controller.openWebsite();

      expect(service.calls, ['getCompanyPage:$lumenId']);
      expect(controller.page?.companyName, sampleCompany.companyName);
      expect(launcher.urls, [sampleCompany.website]);
      expect(controller.errorMessage, isNull);
    });

    test('indica quando o navegador não abre o sítio', () async {
      launcher.opens = false;
      await controller.load(lumenId);

      await controller.openWebsite();

      expect(
        controller.errorMessage,
        CompanyPageController.websiteFailureMessage,
      );
    });

    test('sem página carregada não abre nada', () async {
      await controller.openWebsite();

      expect(launcher.urls, isEmpty);
    });

    test('a falha de ligação é indicada (RNF014)', () async {
      service.failures['getCompanyPage'] = () => const ConnectionFailure();

      await controller.load(lumenId);

      expect(controller.status, LoadStatus.failed);
      expect(controller.errorMessage, connectionFailureMessage);
    });
  });
}
