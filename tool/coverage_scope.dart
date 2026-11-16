/// Âmbito da cobertura de linhas do frontend mobile (plano de testes do
/// frontend mobile, secção 10).
library;

/// Ficheiros de `lib/` excluídos da cobertura: os gerados automaticamente e o
/// arranque da aplicação (`lib/main.dart`, verificado pelos testes de sistema).
bool isExcludedFromCoverage(String path) {
  final file = normalizePath(path);
  return file == 'lib/main.dart' ||
      file.startsWith('lib/generated/') ||
      file.endsWith('.g.dart') ||
      file.endsWith('.freezed.dart');
}

/// Caminho relativo à raiz do pacote, com `/`, a partir de `lib/`.
String normalizePath(String path) {
  final file = path.replaceAll(r'\', '/');
  if (file.startsWith('lib/')) {
    return file;
  }
  final index = file.lastIndexOf('/lib/');
  return index < 0 ? file : file.substring(index + 1);
}
