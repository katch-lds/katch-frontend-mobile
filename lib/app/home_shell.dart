import 'package:material_ui/material_ui.dart';

import '../screens/profile/profile_screen.dart';
import '../widgets/connection_banner.dart';
import 'app_scope.dart';

/// Área do Candidato, com a barra inferior de quatro separadores (9.1).
///
/// Os separadores «Explorar», «Matches» e «Conversas» chegam com as Issues
/// seguintes (I076 e I078); o separador «Perfil» mostra o perfil do Candidato
/// (M05), com acesso aos ecrãs M06 a M08 e à conta (M20).
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
                ? const ProfileScreen()
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
