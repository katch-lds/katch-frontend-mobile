# katch-frontend-mobile

Aplicação móvel do Katch, para o Candidato. Flutter e Dart (I120).

## Requisitos

- Flutter SDK (canal stable) com Dart 3.8 ou posterior.
- API do `katch-backend` em execução (por omissão, `http://10.0.2.2:5180`, a API local vista do emulador Android).

## Comandos

| Comando | O que faz |
| --- | --- |
| `flutter pub get` | Instala as dependências |
| `flutter test --coverage` | Testes unitários e de widget, com cobertura em `coverage/lcov.info` |
| `dart format --output=none --set-exit-if-changed lib test` | Verifica a formatação (QG-05) |
| `flutter analyze --fatal-infos --fatal-warnings` | Dart analyzer com flutter_lints (QG-05) |
| `flutter build apk --debug --dart-define=API_BASE_URL=<url>` | Build (QG-01) |

## Configuração por ambiente

O endereço da API vem de `--dart-define=API_BASE_URL=<url>` no build e no `flutter run`. Sem valor, a aplicação usa
a API local do emulador. O tempo limite dos pedidos é de 9 segundos. Não há segredos no repositório.

## Estrutura

As pastas de `lib/` seguem as camadas do modelo de classes do frontend mobile v02 (secção 2.3): `app`, `core`
(cliente da API v02), `models`, `services`, `session`, `polling`, `state`, `screens` e `widgets`.

## Pipeline CI

`.github/workflows/ci.yml`: `build-and-test` (testes com cobertura mínima de 40%, QG-01 com o APK de depuração e o
QG-07 preparado) e `static-analysis` (QG-05: `dart format` e `flutter analyze`). Enquanto a pasta `android/` não
estiver no repositório, a pipeline gera-a e publica-a no artefacto `android-platform`.
