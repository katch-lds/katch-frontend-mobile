import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/models/file_selection.dart';

import '../support/fakes.dart';

void main() {
  group('isValidEmail (P04)', () {
    test('aceita o formato local@domínio', () {
      expect(InputRules.isValidEmail('ana.ferreira@exemplo.pt'), isTrue);
      expect(InputRules.isValidEmail('  ana@exemplo.pt  '), isTrue);
    });

    test(
      'rejeita sem @, com dois @, sem local, sem domínio ou com espaços',
      () {
        expect(InputRules.isValidEmail('ana.exemplo.pt'), isFalse);
        expect(InputRules.isValidEmail('ana@@exemplo.pt'), isFalse);
        expect(InputRules.isValidEmail('@exemplo.pt'), isFalse);
        expect(InputRules.isValidEmail('ana@'), isFalse);
        expect(InputRules.isValidEmail('ana ferreira@exemplo.pt'), isFalse);
      },
    );
  });

  group('isValidPhone (P04)', () {
    test('aceita exatamente 9 algarismos', () {
      expect(InputRules.isValidPhone('912345678'), isTrue);
    });

    test('rejeita 8 e 10 algarismos e outros caracteres', () {
      expect(InputRules.isValidPhone('91234567'), isFalse);
      expect(InputRules.isValidPhone('9123456789'), isFalse);
      expect(InputRules.isValidPhone('91234567a'), isFalse);
      expect(InputRules.isValidPhone('+35191234'), isFalse);
    });
  });

  group('isValidPassword (P05)', () {
    test('aceita 8 caracteres com uma letra e um algarismo', () {
      expect(InputRules.isValidPassword('katch202'), isTrue);
      expect(InputRules.isValidPassword('katch2026'), isTrue);
    });

    test('rejeita 7 caracteres, sem algarismo ou sem letra', () {
      expect(InputRules.isValidPassword('katch20'), isFalse);
      expect(InputRules.isValidPassword('katch'), isFalse);
      expect(InputRules.isValidPassword('katchkatch'), isFalse);
      expect(InputRules.isValidPassword('20262026'), isFalse);
    });
  });

  test('isBlank trata o texto só com espaços como vazio', () {
    expect(InputRules.isBlank('   '), isTrue);
    expect(InputRules.isBlank(' a '), isFalse);
  });

  group('isValidCustomSkill (P07)', () {
    test('aceita «C#», «C++», «.NET» e letras acentuadas', () {
      expect(InputRules.isValidCustomSkill('C#'), isTrue);
      expect(InputRules.isValidCustomSkill('C++'), isTrue);
      expect(InputRules.isValidCustomSkill('.NET'), isTrue);
      expect(InputRules.isValidCustomSkill(' Gestão de projeto '), isTrue);
      expect(InputRules.isValidCustomSkill('A' * 40), isTrue);
    });

    test('rejeita 1 ou 41 caracteres e símbolos fora do P07', () {
      expect(InputRules.isValidCustomSkill('C'), isFalse);
      expect(InputRules.isValidCustomSkill('A' * 41), isFalse);
      expect(InputRules.isValidCustomSkill('dev@home'), isFalse);
      expect(InputRules.isValidCustomSkill('a/b'), isFalse);
    });
  });

  test('isValidDistanceKm aceita de 1 a 500 (P06)', () {
    expect(InputRules.isValidDistanceKm(1), isTrue);
    expect(InputRules.isValidDistanceKm(500), isTrue);
    expect(InputRules.isValidDistanceKm(0), isFalse);
    expect(InputRules.isValidDistanceKm(501), isFalse);
  });

  test('isValidLink exige http:// ou https:// (P10)', () {
    expect(InputRules.isValidLink('https://exemplo.pt'), isTrue);
    expect(InputRules.isValidLink(' HTTP://exemplo.pt '), isTrue);
    expect(InputRules.isValidLink('exemplo.pt'), isFalse);
    expect(InputRules.isValidLink('ftp://exemplo.pt'), isFalse);
  });

  test('isValidSummary aceita 1000 caracteres e rejeita 1001 (P08)', () {
    expect(InputRules.isValidSummary('a' * 1000), isTrue);
    expect(InputRules.isValidSummary('${'a' * 1000}  '), isTrue);
    expect(InputRules.isValidSummary('a' * 1001), isFalse);
    expect(
      InputRules.textTooLongReason(1000),
      'O texto não pode exceder 1000 caracteres.',
    );
  });

  group('photoError (P01)', () {
    test('aceita JPEG e PNG até 5 MB', () {
      expect(InputRules.photoError(jpegFile()), isNull);
      expect(
        InputRules.photoError(FileSelection.fromBytes('a.png', pngBytes)),
        isNull,
      );
      final limit = FileSelection(
        name: 'limite.jpeg',
        sizeBytes: InputRules.maxFileBytes,
        header: jpegBytes,
      );
      expect(InputRules.photoError(limit), isNull);
    });

    test('rejeita 5 MB + 1 byte', () {
      expect(
        InputRules.photoError(oversizedJpeg()),
        InputRules.fileTooLargeReason,
      );
    });

    test('rejeita outra extensão e conteúdo que não é imagem', () {
      expect(
        InputRules.photoError(FileSelection.fromBytes('a.gif', jpegBytes)),
        InputRules.photoFormatReason,
      );
      expect(
        InputRules.photoError(FileSelection.fromBytes('a.jpg', pdfBytes)),
        InputRules.photoFormatReason,
      );
      expect(
        InputRules.photoError(FileSelection.fromBytes('a.png', [0x89])),
        InputRules.photoFormatReason,
      );
      expect(
        InputRules.photoError(FileSelection.fromBytes('a.jpg', [])),
        InputRules.requiredReason,
      );
    });
  });

  group('cvError (P02)', () {
    test('aceita PDF até 5 MB', () {
      expect(InputRules.cvError(pdfFile()), isNull);
    });

    test('rejeita um PDF com outro conteúdo e outra extensão', () {
      expect(InputRules.cvError(fakePdf()), InputRules.cvFormatReason);
      expect(
        InputRules.cvError(FileSelection.fromBytes('cv.docx', pdfBytes)),
        InputRules.cvFormatReason,
      );
    });

    test('rejeita 5 MB + 1 byte', () {
      final file = FileSelection(
        name: 'cv.pdf',
        sizeBytes: InputRules.maxFileBytes + 1,
        header: pdfBytes.take(8).toList(),
      );
      expect(InputRules.cvError(file), InputRules.fileTooLargeReason);
    });
  });
}
