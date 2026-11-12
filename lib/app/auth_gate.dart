import 'package:material_ui/material_ui.dart';

import '../screens/auth/login_screen.dart';
import '../session/session_status.dart';
import 'app_scope.dart';
import 'home_shell.dart';

/// Escolhe o ecrã segundo o estado da sessão (modelo de classes, 9.2).
///
/// Sem sessão, ou com a sessão expirada, mostra o início de sessão (M01): as
/// áreas reservadas só são apresentadas com a sessão iniciada (RF105, RNF005).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return switch (session.status) {
          SessionStatus.restoring => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          SessionStatus.signedIn => const HomeShell(),
          SessionStatus.signedOut => const LoginScreen(),
          SessionStatus.expired => const LoginScreen(sessionExpired: true),
        };
      },
    );
  }
}
