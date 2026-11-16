import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/account_controller.dart';
import 'change_password_screen.dart';

/// Ecrã «Conta», M20: alteração da palavra-passe e fim de sessão (RF105).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = AccountController(
      auth: dependencies.auth,
      session: dependencies.session,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final signingOut = _controller.signingOut;
          return ListView(
            children: [
              ListTile(
                key: const Key('account-change-password'),
                leading: const Icon(Icons.lock_outline),
                title: const Text('Alterar palavra-passe'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !signingOut,
                onTap: _openChangePassword,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonalIcon(
                  key: const Key('account-sign-out'),
                  onPressed: signingOut ? null : _controller.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Terminar sessão'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
