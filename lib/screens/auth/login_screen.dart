import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/load_status.dart';
import '../../state/login_controller.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';
import 'register_screen.dart';

/// Ecrã de início de sessão do Candidato, M01 (RF001).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.sessionExpired = false});

  /// A sessão anterior expirou ou a credencial foi recusada (RNF005).
  final bool sessionExpired;

  /// Indicação apresentada depois da expiração da sessão (ERR-01).
  static const expiredMessage =
      'A sessão expirou ou não é válida. Inicie sessão novamente.';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = LoginController(
      auth: dependencies.auth,
      session: dependencies.session,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context).monitor;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ConnectionBanner(monitor: monitor),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final loading = _controller.status == LoadStatus.loading;
                  final expired =
                      widget.sessionExpired && _controller.errorMessage == null;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Text('Katch', style: textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        const Text('Inicie sessão para explorar vagas.'),
                        FormMessage(
                          message: expired ? LoginScreen.expiredMessage : null,
                          isError: false,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('login-email'),
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correio eletrónico',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _controller.email = value,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('login-password'),
                          enabled: !loading,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Palavra-passe',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _controller.password = value,
                          onSubmitted: (_) => _controller.submit(),
                        ),
                        FormMessage(message: _controller.errorMessage),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('login-submit'),
                          onPressed: _controller.canSubmit
                              ? _controller.submit
                              : null,
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('login-register'),
                          onPressed: loading ? null : _openRegister,
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
