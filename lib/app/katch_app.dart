import 'package:material_ui/material_ui.dart';

import '../session/session_manager.dart';
import '../session/session_status.dart';
import 'app_dependencies.dart';
import 'app_scope.dart';
import 'auth_gate.dart';

/// Raiz da aplicação móvel do Candidato (modelo de classes, 9.2).
///
/// Quando a sessão deixa de estar iniciada (fim de sessão, expiração ou
/// credencial recusada), fecha os ecrãs abertos por cima da área do
/// Candidato: o `AuthGate` passa a mostrar o início de sessão e não é possível
/// voltar às áreas reservadas (RF105).
class KatchApp extends StatefulWidget {
  const KatchApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<KatchApp> createState() => _KatchAppState();
}

class _KatchAppState extends State<KatchApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late SessionStatus _lastStatus;

  SessionManager get _session => widget.dependencies.session;

  @override
  void initState() {
    super.initState();
    _lastStatus = _session.status;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final status = _session.status;
    if (_lastStatus == SessionStatus.signedIn &&
        status != SessionStatus.signedIn) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    _lastStatus = status;
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Katch',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF3730A3)),
        home: const AuthGate(),
      ),
    );
  }
}
