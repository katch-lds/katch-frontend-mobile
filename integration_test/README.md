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
