import 'package:flutter/widgets.dart';

import 'app/app_config.dart';
import 'app/app_dependencies.dart';
import 'app/katch_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create(AppConfig.fromEnvironment());
  runApp(KatchApp(dependencies: dependencies));
  await dependencies.session.restore();
}
