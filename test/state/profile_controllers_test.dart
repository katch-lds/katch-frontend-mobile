import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/models/custom_skill_dto.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/state/failure_messages.dart';
import 'package:katch_mobile/state/load_status.dart';
import 'package:katch_mobile/state/preferences_controller.dart';
import 'package:katch_mobile/state/profile_files_controller.dart';
import 'package:katch_mobile/state/profile_form_controller.dart';
import 'package:katch_mobile/state/profile_store.dart';
import 'package:katch_mobile/state/reference_data_store.dart';
import 'package:katch_mobile/state/skills_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeCandidateProfileService service;
  late FakeReferenceListService lists;
  late ReferenceDataStore reference;
  late SessionManager session;
  late ProfileStore store;

  setUp(() async {
    service = FakeCandidateProfileService();
    lists = FakeReferenceListService();
    reference = ReferenceDataStore(lists);
    session = SessionManager(
      storage: MemorySessionStorage(),
      clock: FakeClock(),
    );
    await session.start(candidateLogin());
    store = ProfileStore(service: service, session: session);
  });

  group('ProfileFormController (M05, RF006)', () {
    late ProfileFormController controller;

    setUp(() {
      controller = ProfileFormController(
        service: service,
        profile: store,
        reference: reference,
      );
    });

    test('preenche o formulário com o perfil e as localidades', () async {
      await controller.load();

      expect(controller.loadStatus, LoadStatus.loaded);
      expect(controller.desiredRole, 'Programador júnior');
      expect(controller.locationId, braga.id);
      expect(controller.availability, Availability.oneMonth);
      expect(controller.summaryLength, controller.experienceSummary.length);
      expect(controller.locations, [braga, felgueiras]);
    });

    test('grava função, localidade, disponibilidade e resumo', () async {
      await controller.load();
      controller
        ..desiredRole = '  Analista de dados  '
        ..locationId = felgueiras.id
        ..availability = Availability.immediate
        ..experienceSummary = '   ';

      final saved = await controller.save();

      expect(saved, isTrue);
      final request = service.updateRequests.single;
      expect(request.desiredRole, 'Analista de dados');
      expect(request.locationId, felgueiras.id);
      expect(request.availability, Availability.immediate);
      expect(request.experienceSummary, isNull);
      expect(store.profile?.desiredRole, 'Analista de dados');
    });

    test('rejeita o resumo com 1001 caracteres sem enviar (P08)', () async {
      await controller.load();
      controller.experienceSummary = 'a' * 1001;

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(controller.summaryLength, 1001);
      expect(
        controller.errors.reasonFor(
          ProfileFormController.experienceSummaryField,
        ),
        'O texto não pode exceder 1000 caracteres.',
      );
      expect(service.updateRequests, isEmpty);

      controller.experienceSummary = 'a' * 1000;
      expect(
        controller.errors.reasonFor(
          ProfileFormController.experienceSummaryField,
        ),
        isNull,
      );
      expect(await controller.save(), isTrue);
    });

    test('exige a localidade e limita a função a 150 caracteres', () async {
      await controller.load();
      controller
        ..desiredRole = 'f' * 151
        ..locationId = null;

      expect(controller.validate(), isFalse);
      expect(
        controller.errors.reasonFor(ProfileFormController.desiredRoleField),
        InputRules.textTooLongReason(150),
      );
      expect(
        controller.errors.reasonFor(ProfileFormController.locationIdField),
        InputRules.requiredReason,
      );
    });

    test('mostra o motivo do servidor junto do campo', () async {
      await controller.load();
      service.failures['updateProfile'] = () => rejection(
        'ERR-10',
        validationMessage,
        {'locationId': 'O valor não pertence à lista pré-definida.'},
      );

      expect(await controller.save(), isFalse);

      expect(controller.status, LoadStatus.failed);
      expect(controller.errorMessage, validationMessage);
      expect(
        controller.errors.reasonFor(ProfileFormController.locationIdField),
        'O valor não pertence à lista pré-definida.',
      );
    });

    test(
      'indica a falha de ligação ao gravar e ao carregar (RNF014)',
      () async {
        await controller.load();
        service.failures['updateProfile'] = () => const ConnectionFailure();

        await controller.save();
        expect(controller.errorMessage, connectionFailureMessage);

        final other = ProfileFormController(
          service: service,
          profile: ProfileStore(service: service, session: session),
          reference: reference,
        );
        service.failures['getProfile'] = () => const ConnectionFailure();
        await other.load();
        expect(other.loadStatus, LoadStatus.failed);
        expect(other.errorMessage, connectionFailureMessage);
        other.dispose();
        controller.dispose();
      },
    );
  });

  group('ProfileFilesController (M06; RF010, RF011, RF012)', () {
    late FakeFilePicker picker;
    late ProfileFilesController controller;

    setUp(() async {
      service.profile = sampleProfile(links: ['https://exemplo.pt/rita']);
      await store.load();
      picker = FakeFilePicker();
      controller = ProfileFilesController(
        service: service,
        profile: store,
        picker: picker,
      );
      controller.load();
    });

    test(
      'envia a fotografia, o CV e as hiperligações por esta ordem',
      () async {
        picker
          ..image = jpegFile()
          ..pdf = pdfFile();
        await controller.pickPhoto();
        await controller.pickCv();
        controller.addLink();
        controller.setLink(1, ' https://git.exemplo.pt/rita ');

        final saved = await controller.save();

        expect(saved, isTrue);
        expect(service.calls, [
          'getProfile',
          'uploadPhoto',
          'uploadCv',
          'setLinks',
          'getProfile',
        ]);
        expect(service.linkRequests.single.urls, [
          'https://exemplo.pt/rita',
          'https://git.exemplo.pt/rita',
        ]);
        expect(controller.photo, isNull);
        expect(controller.cv, isNull);
        expect(store.profile?.hasCv, isTrue);
        expect(store.photoUrl, '/api/files/profile-photo/fotografia.jpg');
      },
    );

    test('rejeita a imagem com 5 MB + 1 byte antes de enviar', () async {
      picker.image = oversizedJpeg();
      await controller.pickPhoto();

      expect(
        controller.errors.reasonFor(ProfileFilesController.photoField),
        InputRules.fileTooLargeReason,
      );
      expect(await controller.save(), isFalse);
      expect(service.uploads, isEmpty);
    });

    test('rejeita o PDF com outro conteúdo antes de enviar (RNF016)', () async {
      picker.pdf = fakePdf();
      await controller.pickCv();

      expect(await controller.save(), isFalse);
      expect(
        controller.errors.reasonFor(ProfileFilesController.cvField),
        InputRules.cvFormatReason,
      );
      expect(service.uploads, isEmpty);
    });

    test('desistir da escolha não altera nada', () async {
      await controller.pickPhoto();
      await controller.pickCv();

      expect(controller.photo, isNull);
      expect(controller.cv, isNull);
      expect(await controller.save(), isTrue);
      expect(service.calls, ['getProfile']);
    });

    test('aceita 3 hiperligações e rejeita a quarta (RF012)', () {
      expect(controller.addLink(), isTrue);
      expect(controller.addLink(), isTrue);
      expect(controller.links, hasLength(3));

      expect(controller.addLink(), isFalse);

      expect(controller.links, hasLength(3));
      expect(
        controller.errors.reasonFor(ProfileFilesController.linksField),
        InputRules.tooManyLinksReason,
      );

      controller.removeLink(2);
      expect(controller.addLink(), isTrue);
      expect(
        controller.errors.reasonFor(ProfileFilesController.linksField),
        isNull,
      );
    });

    test('rejeita o endereço sem http:// ou https:// (P10)', () async {
      controller.setLink(0, 'exemplo.pt/rita');

      expect(await controller.save(), isFalse);
      expect(
        controller.errors.reasonFor(ProfileFilesController.linkField(0)),
        InputRules.linkReason,
      );
      expect(service.linkRequests, isEmpty);

      controller.removeLink(0);
      expect(controller.errors.isEmpty, isTrue);
      expect(await controller.save(), isTrue);
      expect(service.linkRequests.single.urls, isEmpty);
    });

    test('a recusa do servidor fica no campo do ficheiro enviado', () async {
      service.failures['uploadCv'] = () => rejection(
        'ERR-11',
        'O ficheiro não é aceite.',
        {'file': InputRules.cvFormatReason},
      );
      picker
        ..image = jpegFile()
        ..pdf = pdfFile();
      await controller.pickPhoto();
      await controller.pickCv();

      expect(await controller.save(), isFalse);

      expect(controller.status, LoadStatus.failed);
      expect(controller.photo, isNull);
      expect(controller.cv, isNotNull);
      expect(
        controller.errors.reasonFor(ProfileFilesController.cvField),
        InputRules.cvFormatReason,
      );
      expect(controller.errorMessage, 'O ficheiro não é aceite.');
      expect(service.calls.last, 'getProfile');
    });

    test('indica a falha de ligação (RNF014)', () async {
      service.failures['setLinks'] = () => const ConnectionFailure();
      controller.setLink(0, 'https://outro.pt');

      expect(await controller.save(), isFalse);
      expect(controller.errorMessage, connectionFailureMessage);
      controller.dispose();
    });
  });

  group('SkillsController (M07; RF008, RF009)', () {
    late SkillsController controller;

    setUp(() async {
      controller = SkillsController(
        service: service,
        reference: reference,
        profile: store,
      );
      await controller.load();
    });

    test('mostra as escolhidas e as disponíveis', () {
      expect(controller.loadStatus, LoadStatus.loaded);
      expect(controller.selected, [flutterSkill]);
      expect(controller.available, [dotnet, sql]);
    });

    test(
      'escolhe e retira competências da lista e grava as diferenças',
      () async {
        controller
          ..toggle(dotnet)
          ..toggle(flutterSkill);

        expect(await controller.save(), isTrue);

        expect(service.calls, [
          'getProfile',
          'removeSkill:${flutterSkill.id}',
          'addSkill:${dotnet.id}',
        ]);
        expect(store.profile?.skills.map((s) => s.name), ['.NET']);
        expect(controller.selected, [dotnet]);
      },
    );

    test('só com remoções volta a pedir o perfil', () async {
      controller.toggle(flutterSkill);

      expect(await controller.save(), isTrue);
      expect(service.calls.last, 'getProfile');
      expect(store.profile?.skills, isEmpty);
    });

    test('acrescenta «C#» pela opção «Outro» (RF009)', () async {
      controller.showCustom(true);
      controller.customLabel = ' C# ';

      expect(controller.addCustom(), isTrue);
      expect(controller.customEnabled, isFalse);
      expect(controller.selectedCustom.single.label, 'C#');

      expect(await controller.save(), isTrue);
      expect(service.calls.last, 'addCustomSkill:C#');
      expect(controller.selectedCustom.single.customSkillId, 'custom-1');
    });

    test('rejeita 41 caracteres e «@» antes de enviar (P07)', () {
      controller.showCustom(true);
      controller.customLabel = 'A' * 41;
      expect(controller.addCustom(), isFalse);
      expect(
        controller.errors.reasonFor(SkillsController.labelField),
        InputRules.customSkillReason,
      );

      controller.customLabel = 'dev@home';
      expect(controller.errors.reasonFor(SkillsController.labelField), isNull);
      expect(controller.addCustom(), isFalse);
      expect(
        controller.errors.reasonFor(SkillsController.labelField),
        InputRules.customSkillReason,
      );
      expect(controller.selectedCustom, isEmpty);
      expect(service.calls, ['getProfile']);
    });

    test('rejeita uma competência «Outro» repetida', () {
      controller.customLabel = 'C#';
      controller.addCustom();
      controller.customLabel = 'c#';

      expect(controller.addCustom(), isFalse);
      expect(
        controller.errors.reasonFor(SkillsController.labelField),
        SkillsController.alreadyAddedReason,
      );
    });

    test('retira uma competência «Outro» já gravada', () async {
      service.profile = sampleProfile(
        customSkills: const [CustomSkillDto(customSkillId: 'c1', label: 'C#')],
      );
      await store.refresh();
      await controller.load();

      controller.removeCustom(controller.selectedCustom.single);
      expect(await controller.save(), isTrue);

      expect(service.calls, contains('removeCustomSkill:c1'));
      expect(store.profile?.customSkills, isEmpty);
    });

    test('esconder o campo «Outro» limpa o texto', () {
      controller.showCustom(true);
      controller.customLabel = 'Go';
      controller.showCustom(false);

      expect(controller.customLabel, isEmpty);
      expect(controller.customEnabled, isFalse);
    });

    test('depois de uma recusa, só volta a enviar o que falta', () async {
      service.failures['addCustomSkill:Rust'] = () => rejection(
        'ERR-10',
        validationMessage,
        {'label': SkillsController.alreadyAddedReason},
      );
      controller
        ..customLabel = 'Go'
        ..addCustom()
        ..customLabel = 'Rust'
        ..addCustom();

      expect(await controller.save(), isFalse);

      expect(controller.status, LoadStatus.failed);
      expect(
        controller.errors.reasonFor(SkillsController.labelField),
        SkillsController.alreadyAddedReason,
      );
      expect(controller.selectedCustom.map((s) => s.customSkillId), [
        'custom-1',
        '',
      ]);

      service.failures.clear();
      expect(await controller.save(), isTrue);
      expect(service.calls.where((c) => c.startsWith('addCustomSkill')), [
        'addCustomSkill:Go',
        'addCustomSkill:Rust',
        'addCustomSkill:Rust',
      ]);
    });

    test('indica a falha ao obter as competências (RNF014)', () async {
      lists.skillAnswers.add(() => throw const ConnectionFailure());
      final other = SkillsController(
        service: service,
        reference: ReferenceDataStore(lists),
        profile: store,
      );

      await other.load();

      expect(other.loadStatus, LoadStatus.failed);
      expect(other.errorMessage, connectionFailureMessage);
      other.dispose();
    });

    test('indica a falha de ligação ao gravar (RNF014)', () async {
      service.failures['removeSkill:${flutterSkill.id}'] = () =>
          const ConnectionFailure();
      controller.toggle(flutterSkill);

      expect(await controller.save(), isFalse);
      expect(controller.errorMessage, connectionFailureMessage);
      controller.dispose();
    });
  });

  group('PreferencesController (M08, RF007)', () {
    late PreferencesController controller;

    setUp(() async {
      service.profile = sampleProfile(
        preferences: const SearchPreferencesDto(
          maxDistanceKm: 40,
          minSalaryExpectation: 1100,
          workModes: [WorkMode.hybrid],
          contractTypes: [ContractType.permanent],
        ),
      );
      await store.load();
      controller = PreferencesController(service: service, profile: store);
      controller.load();
    });

    test('preenche o formulário com as preferências', () {
      expect(controller.maxDistanceText, '40');
      expect(controller.minSalaryText, '1100');
      expect(controller.workModes, {WorkMode.hybrid});
      expect(controller.contractTypes, {ContractType.permanent});
    });

    test('grava e entrega as novas preferências ao store', () async {
      controller
        ..maxDistanceText = '500'
        ..minSalaryText = '1250,50'
        ..toggleWorkMode(WorkMode.hybrid)
        ..toggleWorkMode(WorkMode.remote)
        ..toggleContractType(ContractType.internship);

      expect(await controller.save(), isTrue);

      final request = service.preferenceRequests.single;
      expect(request.maxDistanceKm, 500);
      expect(request.minSalaryExpectation, 1250.5);
      expect(request.workModes, [WorkMode.remote]);
      expect(request.contractTypes, [
        ContractType.permanent,
        ContractType.internship,
      ]);
      expect(store.preferences?.maxDistanceKm, 500);
    });

    test('campos vazios significam sem filtro', () async {
      controller
        ..maxDistanceText = ''
        ..minSalaryText = ' ';

      expect(await controller.save(), isTrue);
      expect(service.preferenceRequests.single.maxDistanceKm, isNull);
      expect(service.preferenceRequests.single.minSalaryExpectation, isNull);
    });

    test('rejeita 501 km e valores que não são números (P06)', () async {
      controller.maxDistanceText = '501';
      expect(await controller.save(), isFalse);
      expect(
        controller.errors.reasonFor(PreferencesController.maxDistanceKmField),
        InputRules.distanceReason,
      );

      controller
        ..maxDistanceText = '0'
        ..minSalaryText = '-5';
      expect(controller.validate(), isFalse);
      expect(
        controller.errors.reasonFor(
          PreferencesController.minSalaryExpectationField,
        ),
        InputRules.salaryReason,
      );

      controller.maxDistanceText = '12.5';
      expect(controller.maxDistanceKm, isNull);
      expect(controller.validate(), isFalse);
      expect(service.preferenceRequests, isEmpty);
    });

    test('mostra o motivo do servidor e a falha de ligação', () async {
      service.failures['updatePreferences'] = () => rejection(
        'ERR-10',
        validationMessage,
        {'maxDistanceKm': InputRules.distanceReason},
      );
      expect(await controller.save(), isFalse);
      expect(
        controller.errors.reasonFor(PreferencesController.maxDistanceKmField),
        InputRules.distanceReason,
      );

      service.failures['updatePreferences'] = () => const ConnectionFailure();
      expect(await controller.save(), isFalse);
      expect(controller.errorMessage, connectionFailureMessage);
      controller.dispose();
    });

    test('mostra a pretensão salarial com casas decimais', () {
      store.updatePreferences(
        const SearchPreferencesDto(minSalaryExpectation: 999.5),
      );
      controller.load();
      expect(controller.minSalaryText, '999.5');
    });
  });
}
