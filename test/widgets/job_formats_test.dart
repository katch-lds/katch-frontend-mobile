import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/widgets/job_formats.dart';

void main() {
  test('valores em euros, com casas decimais só quando existem', () {
    expect(formatEuros(1600), '1600 €');
    expect(formatEuros(1500.5), '1500,50 €');
    expect(salaryRange(1600, 2100), '1600 € – 2100 €');
    expect(salaryRange(2000, 2000), '2000 €');
  });

  test('localidade e distância (RF015)', () {
    expect(locationAndDistance('Braga (Braga)', 22), 'Braga (Braga) · 22 km');
  });

  test('o tempo em falta arredonda ao minuto seguinte (RF020)', () {
    expect(remainingLabel(const Duration(hours: 24)), '24 h 0 min');
    expect(
      remainingLabel(const Duration(hours: 23, minutes: 46, seconds: 1)),
      '23 h 47 min',
    );
    expect(remainingLabel(const Duration(seconds: 30)), '1 min');
    expect(remainingLabel(Duration.zero), '0 min');
  });

  test('o instante da reposição é apresentado na hora local', () {
    final instant = DateTime.utc(2026, 10, 10, 16, 5);
    final local = instant.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');

    expect(
      instantLabel(instant),
      '${two(local.hour)}:${two(local.minute)} de '
      '${two(local.day)}/${two(local.month)}/${local.year}',
    );
    expect(instantLabel(DateTime(2026, 3, 4, 9, 7)), '09:07 de 04/03/2026');
  });
}
