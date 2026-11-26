import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../screens/conversations/conversations_screen.dart';
import '../screens/exploration/exploration_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/katch_scaffold.dart';
import 'app_scope.dart';

/// Área do Candidato, com a barra inferior de quatro separadores.
///
/// O separador «Explorar» mostra a exploração de vagas (M09 a M11); o
/// separador «Matches», os matches e o contacto da Empresa (M14, M15); o
/// separador «Conversas», as conversas (M16 a M18), com o total de mensagens
/// por ler (RF027); o separador «Perfil», o perfil do Candidato (M05), com
/// acesso aos ecrãs M06 a M08 e à conta (M20). Todas as áreas ficam a um
/// toque da barra inferior (RNF011).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    (label: 'Explorar', icon: Icons.explore_outlined),
    (label: 'Matches', icon: Icons.handshake_outlined),
    (label: 'Conversas', icon: Icons.chat_bubble_outline),
    (label: 'Perfil', icon: Icons.person_outline),
  ];
  static const _matchesTab = 1;
  static const _conversationsTab = 2;

  @override
  void initState() {
    super.initState();
    // Lista de conversas pedida ao entrar, para o contador do separador.
    unawaited(AppScope.of(context).conversations.load());
  }

  void _select(int index) {
    if (index == _matchesTab) {
      unawaited(AppScope.of(context).conversations.load());
    }
    setState(() => _selectedIndex = index);
  }

  Widget _icon(int index, int unread) {
    final icon = Icon(_tabs[index].icon);
    if (index != _conversationsTab) {
      return icon;
    }
    return Badge(
      key: const Key('tab-unread'),
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = AppScope.of(context).conversations;
    return KatchScaffold(
      title: _tabs[_selectedIndex].label,
      // Os separadores ficam montados: trocar de separador não descarta as
      // edições por gravar do perfil (M05).
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const ExplorationScreen(),
          MatchesScreen(
            active: _selectedIndex == _matchesTab,
            onExplore: () => _select(0),
          ),
          ConversationsScreen(
            active: _selectedIndex == _conversationsTab,
            onOpenMatches: () => _select(_matchesTab),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: conversations,
        builder: (context, _) {
          final unread = conversations.unreadMessages;
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            destinations: [
              for (var index = 0; index < _tabs.length; index++)
                NavigationDestination(
                  icon: _icon(index, unread),
                  label: _tabs[index].label,
                ),
            ],
          );
        },
      ),
    );
  }
}
