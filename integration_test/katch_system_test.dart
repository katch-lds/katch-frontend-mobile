import 'package:integration_test/integration_test.dart';

import 'scenarios/sm_01_02_registo.dart';
import 'scenarios/sm_03_04_sessao.dart';
import 'scenarios/sm_05_06_perfil.dart';
import 'scenarios/sm_07_11_16_exploracao.dart';
import 'scenarios/sm_12_15_matches_conversas.dart';
import 'scenarios/sm_17_falha_ligacao.dart';

/// Testes de sistema da aplicação móvel (QG-07, I080): cenários SM-01 a SM-17
/// do plano de testes do frontend mobile (secção 7), na aplicação completa
/// sobre a API do katch-backend com os dados de demonstração.
///
/// Um só ficheiro `*_test.dart`, para a aplicação ser construída e instalada
/// uma vez; cada cenário é um `group` com o código SM-nn no nome
/// (especificação: m4-especificacao-testes-sistema-frontend-mobile-v01.md).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  registoScenarios();
  sessaoScenarios();
  perfilScenarios();
  exploracaoScenarios();
  matchesConversasScenarios();
  falhaLigacaoScenarios();
}
