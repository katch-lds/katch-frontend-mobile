import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/katch_app.dart';

void main() {
  final int erroDeCompilacao = 'I120';
  runApp(KatchApp(config: AppConfig.fromEnvironment()));
}
