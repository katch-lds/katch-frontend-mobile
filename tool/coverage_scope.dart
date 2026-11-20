/// Âmbito da cobertura de linhas do frontend mobile (plano de testes do
/// frontend mobile, secção 10).
///
/// Biblioteca sem argumentos de linha de comandos, usada por
/// `coverage_all_files.dart` e `filter_lcov.dart`.
library;

/// Indica se o ficheiro [path] de `lib/` fica fora da cobertura: os gerados
/// automaticamente e o arranque da aplicação (`lib/main.dart`, verificado pelos
/// testes de sistema).
bool isExcludedFromCoverage(String path) {
  final file = normalizePath(path);
  return file == 'lib/main.dart' ||
      file.startsWith('lib/generated/') ||
      file.endsWith('.g.dart') ||
      file.endsWith('.freezed.dart');
}

/// Devolve [path] relativo à raiz do pacote, com `/`, a partir de `lib/`.
String normalizePath(String path) {
  final file = path.replaceAll(r'\', '/');
  if (file.startsWith('lib/')) {
    return file;
  }
  final index = file.lastIndexOf('/lib/');
  return index < 0 ? file : file.substring(index + 1);
}
