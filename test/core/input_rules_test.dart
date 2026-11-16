import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/input_rules.dart';

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
}
