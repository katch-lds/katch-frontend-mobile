# integration_test

Testes de sistema da aplicação (QG-07, I080): cenários SM-01 a SM-17 do plano de
testes do frontend mobile (secção 7), especificados em
`m4-especificacao-testes-sistema-frontend-mobile-v01.md`.

- `katch_system_test.dart`: único ponto de entrada, para a aplicação ser
  construída e instalada uma vez; chama os grupos de `scenarios/`.
- `scenarios/`: um `group('SM-nn …')` por cenário, com testes `SM-nnx`.
- `support/api.dart`: pedidos diretos à API (contas, Empresas, vagas, matches,
  mensagens e ações do Administrador).
- `support/harness.dart`: arranque da aplicação com as dependências reais e
  apoio à interação (esperas, toques, campos).
- `support/files.dart`: ficheiros de teste e seletor de ficheiros simulado.

## Execução local

Com a API do `katch-backend` a correr no anfitrião (porto 5180, dados de
demonstração) e um emulador Android ligado:

```
flutter test integration_test --dart-define=API_BASE_URL=http://10.0.2.2:5180 --dart-define=E2E_ADMIN_PASSWORD=<palavra-passe do Administrador>
```

A palavra-passe do Administrador nunca fica no repositório (RNF003). Os
cenários criam os seus próprios Candidatos, Recrutadores, Empresas e vagas, com
um sufixo único, por isso a execução repete-se sem repor a base. Com muitas
execuções seguidas, os limites de pedidos por IP da API (`Limits__*`) podem ter
de ser alargados, como na pipeline.

Os tempos do SM-16 e do SM-17 contam a partir do toque e aparecem sempre na
saída, passe ou falhe o teste (`SM-16a job-decline: … ms (limite 2000 ms)`,
`SM-17a: … ms (limite 10000 ms)`).

Desvios ao plano de testes (secção 4.3, 5 e 6), justificados na especificação
(secção 2.1): o armazenamento da sessão é substituído por um em memória, os
Candidatos (exceto no SM-01) e os Recrutadores são criados pela API e o
`katch-backend` é usado na versão fixa `796f81e`.
