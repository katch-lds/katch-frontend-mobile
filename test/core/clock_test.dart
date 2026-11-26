import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/clock.dart';

void main() {
  test('SystemClock devolve a hora atual em UTC', () {
    final before = DateTime.now().toUtc();

    final now = const SystemClock().now();

    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
  });
}
