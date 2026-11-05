import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/katch_app.dart';

void main() {
  print('Prova de bloqueio da I120');
  runApp(KatchApp(config: AppConfig.fromEnvironment()));
}
