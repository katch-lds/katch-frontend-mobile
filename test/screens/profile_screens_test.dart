import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/models/custom_skill_dto.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/screens/account/account_screen.dart';
import 'package:katch_mobile/screens/profile/preferences_screen.dart';
import 'package:katch_mobile/screens/profile/profile_files_screen.dart';
import 'package:katch_mobile/screens/profile/profile_screen.dart';
import 'package:katch_mobile/screens/profile/skills_screen.dart';
import 'package:katch_mobile/state/failure_messages.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late TestApp app;

  setUp(() async {
    app = TestApp();
    await app.session.start(candidateLogin());
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await pumpScreen(tester, app, const Scaffold(body: ProfileScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('M05 · ProfileScreen (RF006)', () {
    testWidgets('mostra o perfil e grava os dados', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Rita Fictícia Moreira'), findsOneWidget);
      expect(find.text('Programador júnior'), findsOneWidget);
      expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('profile-desired-role')),
        'Analista de dados',
      );
      await tapVisible(tester, find.byKey(const Key('profile-availability')));
      await tester.tap(find.text(Availability.immediate.label).last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('profile-location')));
      await tester.tap(find.text(felgueiras.name).last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('profile-save')));

      final request = app.profileService.updateRequests.single;
      expect(request.desiredRole, 'Analista de dados');
      expect(request.availability, Availability.immediate);
      expect(request.locationId, felgueiras.id);
      expect(find.text(ProfileScreen.successMessage), findsOneWidget);
    });

    testWidgets('mostra o contador e rejeita 1001 caracteres', (tester) async {
      await pumpProfile(tester);

      await tester.enterText(
        find.byKey(const Key('profile-summary')),
        'a' * 1001,
      );
      await tester.pump();
      expect(find.text('1001/1000'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('profile-save')));

      expect(
        find.text('O texto não pode exceder 1000 caracteres.'),
        findsOneWidget,
      );
      expect(app.profileService.updateRequests, isEmpty);
    });

    testWidgets('indica a falha de ligação e permite repetir (RNF014)', (
      tester,
    ) async {
      app.profileService.failures['getProfile'] = () =>
          const ConnectionFailure();
      await pumpProfile(tester);

      expect(find.text(connectionFailureMessage), findsOneWidget);

      app.profileService.failures.clear();
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();

      expect(find.text('Rita Fictícia Moreira'), findsOneWidget);
    });

    testWidgets('abre M06, M07, M08 e a conta (M20)', (tester) async {
      await pumpProfile(tester);

      await tapVisible(tester, find.byKey(const Key('profile-open-files')));
      expect(find.byType(ProfileFilesScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('profile-open-skills')));
      expect(find.byType(SkillsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapVisible(
        tester,
        find.byKey(const Key('profile-open-preferences')),
      );
      expect(find.byType(PreferencesScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('profile-open-account')));
      expect(find.byType(AccountScreen), findsOneWidget);
    });
  });

  group('M06 · ProfileFilesScreen (RF010, RF011, RF012)', () {
    Future<void> pumpFiles(WidgetTester tester) async {
      await pumpScreen(tester, app, const ProfileFilesScreen());
      await tester.pumpAndSettle();
    }

    testWidgets('envia fotografia, CV e hiperligação', (tester) async {
      app.filePicker
        ..image = jpegFile()
        ..pdf = pdfFile();
      await pumpFiles(tester);
      expect(find.text('Sem curriculum vitae.'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('files-pick-photo')));
      await tapVisible(tester, find.byKey(const Key('files-pick-cv')));
      expect(find.text('Escolhido: fotografia.jpg'), findsOneWidget);
      expect(find.text('Escolhido: cv.pdf'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('files-add-link')));
      await tester.enterText(
        find.byKey(const Key('files-link-0')),
        'https://exemplo.pt/rita',
      );
      await tapVisible(tester, find.byKey(const Key('files-save')));

      expect(
        app.profileService.calls,
        containsAllInOrder(['uploadPhoto', 'uploadCv', 'setLinks']),
      );
      expect(find.text('Curriculum vitae enviado.'), findsOneWidget);
      expect(find.text(ProfileFilesScreen.successMessage), findsOneWidget);
    });

    testWidgets('rejeita a imagem de 5 MB + 1 byte e o PDF falso', (
      tester,
    ) async {
      app.filePicker
        ..image = oversizedJpeg()
        ..pdf = fakePdf();
      await pumpFiles(tester);

      await tapVisible(tester, find.byKey(const Key('files-pick-photo')));
      await tapVisible(tester, find.byKey(const Key('files-pick-cv')));
      await tapVisible(tester, find.byKey(const Key('files-save')));

      expect(find.text(InputRules.fileTooLargeReason), findsOneWidget);
      expect(find.text(InputRules.cvFormatReason), findsOneWidget);
      expect(app.profileService.uploads, isEmpty);
    });

    testWidgets('rejeita a quarta hiperligação e o endereço sem http', (
      tester,
    ) async {
      await pumpFiles(tester);
      final add = find.byKey(const Key('files-add-link'));
      for (var i = 0; i < 4; i++) {
        await tapVisible(tester, add);
      }

      expect(find.byKey(const Key('files-link-2')), findsOneWidget);
      expect(find.byKey(const Key('files-link-3')), findsNothing);
      expect(find.text(InputRules.tooManyLinksReason), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('files-link-0')),
        'exemplo.pt',
      );
      await tapVisible(tester, find.byKey(const Key('files-link-remove-2')));
      await tapVisible(tester, find.byKey(const Key('files-save')));

      expect(find.text(InputRules.linkReason), findsOneWidget);
      expect(app.profileService.linkRequests, isEmpty);
    });
  });

  group('M07 · SkillsScreen (RF008, RF009)', () {
    Future<void> pumpSkills(WidgetTester tester) async {
      await pumpScreen(tester, app, const SkillsScreen());
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, String option) async {
      await tapVisible(tester, find.byKey(const Key('skills-combobox')));
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    testWidgets('escolhe da lista, acrescenta «C#» e grava', (tester) async {
      await pumpSkills(tester);
      expect(
        find.byKey(Key('skill-chip-${flutterSkill.name}')),
        findsOneWidget,
      );

      await choose(tester, sql.name);
      expect(find.byKey(Key('skill-chip-${sql.name}')), findsOneWidget);

      await choose(tester, 'Outro');
      await tester.enterText(
        find.byKey(const Key('skills-custom-label')),
        'C#',
      );
      await tapVisible(tester, find.byKey(const Key('skills-custom-add')));
      expect(find.byKey(const Key('custom-chip-C#')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('skills-save')));

      expect(app.profileService.calls, [
        'getProfile',
        'addSkill:${sql.id}',
        'addCustomSkill:C#',
      ]);
      expect(find.text(SkillsScreen.successMessage), findsOneWidget);
    });

    testWidgets('rejeita 41 caracteres e «@» antes de enviar (P07)', (
      tester,
    ) async {
      await pumpSkills(tester);
      await choose(tester, 'Outro');
      final field = find.byKey(const Key('skills-custom-label'));

      await tester.enterText(field, 'A' * 41);
      await tapVisible(tester, find.byKey(const Key('skills-custom-add')));
      expect(find.text(InputRules.customSkillReason), findsOneWidget);

      await tester.enterText(field, 'dev@home');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text(InputRules.customSkillReason), findsOneWidget);
      expect(find.byKey(const Key('custom-chip-dev@home')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('skills-custom-cancel')));
      expect(field, findsNothing);
    });

    testWidgets('retira etiquetas da lista e «Outro»', (tester) async {
      app.profileService.profile = sampleProfile(
        customSkills: const [CustomSkillDto(customSkillId: 'c1', label: 'C#')],
      );
      await pumpSkills(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(Key('skill-chip-${flutterSkill.name}')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('custom-chip-C#')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ainda não escolheu competências.'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('skills-save')));

      expect(
        app.profileService.calls,
        containsAll(['removeSkill:${flutterSkill.id}', 'removeCustomSkill:c1']),
      );
    });

    testWidgets('indica a falha ao obter as competências', (tester) async {
      app.referenceLists.skillAnswers.add(
        () => throw const ConnectionFailure(),
      );
      await pumpSkills(tester);

      expect(find.text(connectionFailureMessage), findsOneWidget);
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('skills-combobox')), findsOneWidget);
    });
  });

  group('M08 · PreferencesScreen (RF007)', () {
    testWidgets('grava as preferências e rejeita 501 km', (tester) async {
      app.profileService.profile = sampleProfile(
        preferences: const SearchPreferencesDto(maxDistanceKm: 30),
      );
      await pumpScreen(tester, app, const PreferencesScreen());
      await tester.pumpAndSettle();
      final distance = find.byKey(const Key('preferences-distance'));
      expect(
        find.descendant(of: distance, matching: find.text('30')),
        findsOneWidget,
      );

      await tester.enterText(distance, '501');
      await tapVisible(tester, find.byKey(const Key('preferences-save')));
      expect(find.text(InputRules.distanceReason), findsOneWidget);
      expect(app.profileService.preferenceRequests, isEmpty);

      await tester.enterText(distance, '100');
      await tester.enterText(
        find.byKey(const Key('preferences-salary')),
        '1300',
      );
      await tapVisible(
        tester,
        find.byKey(const Key('preferences-mode-REMOTE')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('preferences-contract-PERMANENT')),
      );
      await tapVisible(tester, find.byKey(const Key('preferences-save')));

      final request = app.profileService.preferenceRequests.single;
      expect(request.maxDistanceKm, 100);
      expect(request.minSalaryExpectation, 1300);
      expect(request.workModes, [WorkMode.remote]);
      expect(request.contractTypes, [ContractType.permanent]);
      expect(find.text(PreferencesScreen.successMessage), findsOneWidget);
    });

    testWidgets('sem perfil, indica a falha e permite repetir', (tester) async {
      app.profileService.failures['getProfile'] = () =>
          const ConnectionFailure();
      await pumpScreen(tester, app, const PreferencesScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('load-retry')), findsOneWidget);

      app.profileService.failures.clear();
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preferences-distance')), findsOneWidget);
    });
  });
}
