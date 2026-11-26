import 'package:material_ui/material_ui.dart';

import '../app/app_scope.dart';
import 'connection_banner.dart';

/// Ecrã com a barra de título e, por cima do conteúdo, a faixa de falha de
/// ligação (RNF014).
class KatchScaffold extends StatelessWidget {
  const KatchScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Linha por baixo do título.
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
      body: Column(
        children: [
          ConnectionBanner(monitor: AppScope.of(context).monitor),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
