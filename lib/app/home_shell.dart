import 'package:material_ui/material_ui.dart';

import '../screens/account/account_screen.dart';
import '../widgets/connection_banner.dart';
import 'app_scope.dart';

/// Área do Candidato, com a barra inferior de quatro separadores (9.1).
///
/// Os ecrãs de cada separador chegam com as Issues seguintes (I076 a I078); o
/// separador «Perfil» já dá acesso à conta (M20).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _titles = ['Explorar', 'Matches', 'Conversas', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context).monitor;
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: Column(
        children: [
          ConnectionBanner(monitor: monitor),
          Expanded(
            child: _selectedIndex == 3
                ? const _ProfileTab()
                : const _PendingArea(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Conversas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _PendingArea extends StatelessWidget {
  const _PendingArea();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Esta área fica disponível numa próxima versão da aplicação.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('Conta'),
          subtitle: const Text('Palavra-passe e fim de sessão'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
          ),
        ),
      ],
    );
  }
}
