import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/katch_app.dart';

void main() {
  testWidgets('apresenta a aplicação e o endereço da API', (tester) async {
    const config = AppConfig(
      apiBaseUrl: 'https://api.test',
      requestTimeout: Duration(seconds: 9),
    );

    await tester.pumpWidget(const KatchApp(config: config));

    expect(find.text('Katch'), findsOneWidget);
    expect(find.text('API: https://api.test'), findsOneWidget);
  });
}
