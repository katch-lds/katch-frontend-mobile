import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_scope.dart';
import 'package:katch_mobile/app/katch_app.dart';

import 'fakes.dart';

/// Arranca a aplicação completa com serviços simulados.
Future<void> pumpKatchApp(WidgetTester tester, TestApp app) async {
  await tester.pumpWidget(KatchApp(dependencies: app.dependencies));
  await tester.pump();
}

/// Mostra um ecrã isolado, com as dependências simuladas.
Future<void> pumpScreen(WidgetTester tester, TestApp app, Widget screen) async {
  await tester.pumpWidget(
    AppScope(
      dependencies: app.dependencies,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}
