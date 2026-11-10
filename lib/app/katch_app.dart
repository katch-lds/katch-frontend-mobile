import 'package:flutter/material.dart';

import 'app_config.dart';

/// Raiz da aplicação móvel do Candidato (I120).
///
/// A navegação e os ecrãs chegam com as Issues dos ecrãs de m4.
class KatchApp extends StatelessWidget {
  const KatchApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katch',
      home: Scaffold(
        appBar: AppBar(title: const Text('Katch')),
        body: Center(child: Text('API: ${config.apiBaseUrl}')),
      ),
    );
  }
}
