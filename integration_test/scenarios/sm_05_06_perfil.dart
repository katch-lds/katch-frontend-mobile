import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/screens/profile/preferences_screen.dart';
import 'package:katch_mobile/screens/profile/profile_files_screen.dart';
import 'package:katch_mobile/screens/profile/profile_screen.dart';
import 'package:katch_mobile/screens/profile/skills_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/api.dart';
import '../support/files.dart';
import '../support/harness.dart';

/// SM-05 e SM-06 — Perfil profissional, preferências e ficheiros (RF006 a
/// RF012).
void perfilScenarios() {
  group('SM-05 Perfil profissional e preferências', () {
    testWidgets('SM-05a grava o perfil, as competências (com «C#» pela opção '
        '«Outro») e as preferências', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm05');
      final skills = await KatchApi.referenceList(candidate.session, 'skills');
      final listSkill = skills
          .map((skill) => skill['name'] as String)
          .firstWhere((name) => name != 'C#');
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      // Perfil profissional (RF006).
      await app.openTab(tester, 'Perfil');
      await app.enter(tester, 'profile-desired-role', 'Programador Flutter');
      await app.choose(tester, 'profile-location', Locations.bragancaName);
      await app.choose(tester, 'profile-availability', '15 dias');
      await app.enter(
        tester,
        'profile-summary',
        'Três anos de desenvolvimento de aplicações móveis.',
      );
      await app.tapKey(tester, 'profile-save');
      await app.waitFor(tester, find.text(ProfileScreen.successMessage));

      // Competências da lista e «Outro» (RF007 a RF009).
      await app.tapKey(tester, 'profile-open-skills');
      await app.choose(tester, 'skills-combobox', listSkill);
      await app.waitFor(tester, find.byKey(Key('skill-chip-$listSkill')));
      await app.choose(tester, 'skills-combobox', 'Outro');
      await app.enter(tester, 'skills-custom-label', 'C#');
      await app.tapKey(tester, 'skills-custom-add');
      await app.waitFor(tester, find.byKey(const Key('custom-chip-C#')));
      await app.tapKey(tester, 'skills-save');
      await app.waitFor(tester, find.text(SkillsScreen.successMessage));
      await app.back(tester);

      // Preferências de procura (RF014, RF015).
      await app.tapKey(tester, 'profile-open-preferences');
      await app.enter(tester, 'preferences-distance', '120');
      await app.enter(tester, 'preferences-salary', '1300');
      await app.tapKey(tester, 'preferences-mode-HYBRID');
      await app.tapKey(tester, 'preferences-contract-PERMANENT');
      await app.tapKey(tester, 'preferences-save');
      await app.waitFor(tester, find.text(PreferencesScreen.successMessage));

      final profile =
          await candidate.session.get('/api/candidate/profile', 'perfil')
              as Map<String, Object?>;
      expect(profile['desiredRole'], 'Programador Flutter');
      expect(profile['availability'], 'FIFTEEN_DAYS');
      expect(
        profile['experienceSummary'],
        'Três anos de desenvolvimento de aplicações móveis.',
      );
      expect([
        for (final skill in profile['skills'] as List<Object?>)
          (skill as Map<String, Object?>)['name'],
      ], contains(listSkill));
      expect([
        for (final skill in profile['customSkills'] as List<Object?>)
          (skill as Map<String, Object?>)['label'],
      ], contains('C#'));
      final preferences = profile['preferences'] as Map<String, Object?>;
      expect(preferences['maxDistanceKm'], 120);
      expect(preferences['minSalaryExpectation'], 1300);
      expect(preferences['workModes'], ['HYBRID']);
      expect(preferences['contractTypes'], ['PERMANENT']);
    });

    testWidgets('SM-05b resumo com 1001 caracteres, competência com 41 '
        'caracteres e distância de 501 km são recusados', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm05');
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);

      await app.openTab(tester, 'Perfil');
      await app.enter(tester, 'profile-summary', 'a' * 1001);
      await app.tapKey(tester, 'profile-save');
      final tooLong = InputRules.textTooLongReason(InputRules.summaryMaxLength);
      await app.waitFor(tester, find.text(tooLong));
      expect(fieldError(tester, 'profile-summary'), tooLong);
      expect(find.text(ProfileScreen.successMessage), findsNothing);

      await app.tapKey(tester, 'profile-open-skills');
      await app.choose(tester, 'skills-combobox', 'Outro');
      await app.enter(tester, 'skills-custom-label', 'c' * 41);
      await app.tapKey(tester, 'skills-custom-add');
      await app.waitFor(tester, find.text(InputRules.customSkillReason));
      expect(
        fieldError(tester, 'skills-custom-label'),
        InputRules.customSkillReason,
      );
      expect(find.byKey(Key('custom-chip-${'c' * 41}')), findsNothing);
      await app.back(tester);

      await app.tapKey(tester, 'profile-open-preferences');
      await app.enter(tester, 'preferences-distance', '501');
      await app.tapKey(tester, 'preferences-save');
      await app.waitFor(tester, find.text(InputRules.distanceReason));
      expect(
        fieldError(tester, 'preferences-distance'),
        InputRules.distanceReason,
      );
      expect(find.text(PreferencesScreen.successMessage), findsNothing);

      // O servidor também recusa os três valores (RF006 a RF009, ERR-10).
      final session = candidate.session;
      final summary = await session.rawPut('/api/candidate/profile', {
        'desiredRole': null,
        'locationId': Locations.braganca,
        'availability': null,
        'experienceSummary': 'a' * 1001,
      });
      final custom = await session.rawPost(
        '/api/candidate/profile/custom-skills',
        {'label': 'c' * 41},
      );
      final distance = await session
          .rawPut('/api/candidate/profile/preferences', {
            'maxDistanceKm': 501,
            'minSalaryExpectation': null,
            'workModes': <String>[],
            'contractTypes': <String>[],
          });
      for (final outcome in [summary, custom, distance]) {
        expect(outcome.status, 400);
        expect(outcome.code, 'ERR-10');
      }
    });
  });

  group('SM-06 Fotografia, curriculum vitae e hiperligações', () {
    testWidgets('SM-06a carrega a fotografia e o CV e grava três '
        'hiperligações', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm06');
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.openFromProfile(tester, 'profile-open-files');

      app.picker.nextImage(TestFiles.photo());
      await app.tapKey(tester, 'files-pick-photo');
      await app.waitFor(tester, find.text('Escolhido: foto.png'));
      app.picker.nextPdf(TestFiles.cv());
      await app.tapKey(tester, 'files-pick-cv');
      await app.waitFor(tester, find.text('Escolhido: cv.pdf'));
      for (var index = 0; index < InputRules.maxLinks; index++) {
        await app.tapKey(tester, 'files-add-link');
        await app.enter(
          tester,
          'files-link-$index',
          'https://portfolio.example.com/sm06/$index',
        );
      }
      await app.tapKey(tester, 'files-save');
      await app.waitFor(
        tester,
        find.text(ProfileFilesScreen.successMessage),
        timeout: const Duration(seconds: 60),
      );
      await app.waitFor(tester, find.text('Curriculum vitae enviado.'));

      final profile =
          await candidate.session.get('/api/candidate/profile', 'perfil')
              as Map<String, Object?>;
      expect(profile['hasCv'], isTrue);
      expect(profile['photoUrl'], isNotNull);
      expect(profile['links'], hasLength(3));
    });

    testWidgets('SM-06b imagem de 5 MB + 1 byte, PDF com conteúdo de outro '
        'formato e 4.ª hiperligação são recusados', (tester) async {
      final candidate = await KatchApi.createCandidate(prefix: 'sm06');
      final app = await TestApp.start(tester);
      await app.signIn(tester, candidate.email, candidate.password);
      await app.openFromProfile(tester, 'profile-open-files');

      app.picker.nextImage(TestFiles.photoOverLimit());
      await app.tapKey(tester, 'files-pick-photo');
      await app.waitFor(tester, find.text(InputRules.fileTooLargeReason));

      app.picker.nextPdf(TestFiles.fakePdf());
      await app.tapKey(tester, 'files-pick-cv');
      await app.waitFor(tester, find.text(InputRules.cvFormatReason));

      for (var index = 0; index < InputRules.maxLinks; index++) {
        await app.tapKey(tester, 'files-add-link');
      }
      await app.tapKey(tester, 'files-add-link');
      await app.waitFor(tester, find.text(InputRules.tooManyLinksReason));
      expect(
        find.byKey(const Key('files-link-${InputRules.maxLinks}')),
        findsNothing,
      );

      await app.tapKey(tester, 'files-save');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(ProfileFilesScreen.successMessage), findsNothing);

      // O servidor recusa os mesmos ficheiros e a 4.ª hiperligação (RF010 a
      // RF012, RNF016).
      final session = candidate.session;
      final photo = await session.rawUpload(
        '/api/candidate/profile/photo',
        'grande.png',
        TestFiles.pngOverLimit(),
      );
      final cv = await session.rawUpload(
        '/api/candidate/profile/cv',
        'falso.pdf',
        TestFiles.png,
      );
      final links = await session.rawPut('/api/candidate/profile/links', {
        'urls': [
          for (var index = 0; index < 4; index++)
            'https://portfolio.example.com/$index',
        ],
      });
      expect(photo.status, anyOf(400, 413));
      expect(cv.status, 400);
      expect(links.status, 400);
      final profile =
          await candidate.session.get('/api/candidate/profile', 'perfil')
              as Map<String, Object?>;
      expect(profile['hasCv'], isFalse);
      expect(profile['photoUrl'], isNull);
    });
  });
}
