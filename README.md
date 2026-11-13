# katch-frontend-mobile

Aplicação móvel do Katch, para o Candidato. Flutter e Dart (I120).

## Requisitos

- Flutter SDK (canal stable) com Dart 3.8 ou posterior.
- API do `katch-backend` em execução (por omissão, `http://10.0.2.2:5180`, a API local vista do emulador Android).

## Comandos

| Comando | O que faz |
| --- | --- |
| `flutter pub get` | Instala as dependências |
| `dart run tool/coverage_all_files.dart` | Gera `test/coverage_all_files_test.dart`, que importa todos os ficheiros de `lib/` (executar depois de criar ou apagar um ficheiro em `lib/`) |
| `flutter test --coverage` | Testes unitários e de widget, com cobertura em `coverage/lcov.info` |
| `dart run tool/filter_lcov.dart` | Retira do `coverage/lcov.info` os ficheiros excluídos da cobertura e indica a cobertura de linhas |
| `dart format --output=none --set-exit-if-changed lib test tool` | Verifica a formatação (QG-05) |
| `flutter analyze --fatal-infos --fatal-warnings` | Dart analyzer com flutter_lints (QG-05) |
| `flutter build apk --debug --dart-define=API_BASE_URL=<url>` | Build (QG-01) |

## Configuração por ambiente

O endereço da API vem de `--dart-define=API_BASE_URL=<url>` no build e no `flutter run`. Sem valor, a aplicação usa
a API local do emulador. O tempo limite dos pedidos é de 9 segundos. Não há segredos no repositório.

## Rede na variante de depuração

O Android exige HTTPS por omissão. Só a variante de depuração permite tráfego sem TLS, e apenas para `10.0.2.2`, o
computador anfitrião visto a partir do emulador, onde a API local responde em `http://10.0.2.2:5180`
(`android/app/src/debug/res/xml/network_security_config.xml`, referido no `android/app/src/debug/AndroidManifest.xml`).
A variante de produção não usa esta configuração e continua a exigir HTTPS.

## Âmbito da cobertura

A cobertura de linhas mínima é de 40% sobre todos os ficheiros de `lib/` (plano de testes do frontend mobile, secção
10). O teste gerado `test/coverage_all_files_test.dart` importa todos esses ficheiros, para os ficheiros sem testes
contarem como não cobertos; a pipeline verifica que está atualizado. O `lib/main.dart` e os ficheiros gerados
(`*.g.dart`, `*.freezed.dart`, `lib/generated/`) são retirados do `lcov.info` antes da verificação.

## Sessão

A credencial de sessão (JWT) fica no armazenamento seguro do Android (`flutter_secure_storage`) e nunca é escrita nos
registos. A sessão é restaurada no arranque enquanto não expirar (8 horas).

## Perfil do Candidato

O separador «Perfil» (M05) grava a função pretendida, a localidade, a disponibilidade e o resumo da experiência e dá
acesso à fotografia, ao curriculum vitae e às hiperligações (M06), às competências (M07) e às preferências de procura
(M08). A validação local repete as regras da API v02 (P01, P02, P06 a P08, P10) só para indicar o motivo antes de
enviar; o servidor volta a validar tudo. A fotografia e o curriculum vitae são escolhidos com o seletor de ficheiros do
Android (`file_selector`) e enviados em `multipart/form-data`, no campo `file`. A fotografia é pedida à API com a
credencial de sessão.

## Estrutura

As pastas de `lib/` seguem as camadas do modelo de classes do frontend mobile v02 (secção 2.3): `app`, `core`
(cliente da API v02), `models`, `services`, `session`, `polling`, `state`, `screens` e `widgets`.

## Pipeline CI

`.github/workflows/ci.yml`: `build-and-test` (testes com cobertura mínima de 40%, QG-01 com o APK de depuração e o
QG-07 preparado) e `static-analysis` (QG-05: `dart format` e `flutter analyze`). A plataforma Android
(`android/`) está no repositório.
