import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/url.dart';

void main() {
  test('retira as barras finais sem expressão regular', () {
    const cases = {
      'http://localhost:5180': 'http://localhost:5180',
      'http://localhost:5180/': 'http://localhost:5180',
      'https://api.test///': 'https://api.test',
      '': '',
      '///': '',
    };

    for (final entry in cases.entries) {
      expect(trimTrailingSlashes(entry.key), entry.value);
    }
  });
}
