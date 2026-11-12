// Gera ou verifica o teste que importa todos os ficheiros de lib/ (I075).
//
// O `flutter test --coverage` só regista os ficheiros carregados por algum
// teste: sem este teste, um ficheiro que nenhum teste importa não conta como
// não coberto (plano de testes do frontend mobile, secção 10).
//
//   dart run tool/coverage_all_files.dart          gera o teste
//   dart run tool/coverage_all_files.dart --check  verifica-o (pipeline)
import 'dart:io';

import 'coverage_scope.dart';

const _outputPath = 'test/coverage_all_files_test.dart';
const _package = 'katch_mobile';

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => normalizePath(file.path))
          .where((path) => path.endsWith('.dart'))
          .where((path) => !isExcludedFromCoverage(path))
          .toList()
        ..sort();
  final content = render(files);
  final output = File(_outputPath);
  if (!check) {
    output.writeAsStringSync(content);
    stdout.writeln('$_outputPath: ${files.length} ficheiros de lib/.');
    return;
  }
  final current = output.existsSync()
      ? output.readAsStringSync().replaceAll('\r\n', '\n')
      : '';
  if (current != content) {
    stderr.writeln(
      '$_outputPath está desatualizado. '
      'Execute: dart run tool/coverage_all_files.dart',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('$_outputPath atualizado: ${files.length} ficheiros de lib/.');
}

/// Conteúdo do teste, já no formato do `dart format`.
String render(List<String> files) {
  final buffer = StringBuffer()
    ..writeln(
      '// Gerado por `dart run tool/coverage_all_files.dart`. Não editar.',
    )
    ..writeln('//')
    ..writeln(
      '// Importa todos os ficheiros de lib/ do âmbito da cobertura, para',
    )
    ..writeln('// os ficheiros sem testes contarem como não cobertos (plano de')
    ..writeln('// testes do frontend mobile, secção 10).')
    ..writeln()
    ..writeln('// ignore_for_file: unused_import')
    ..writeln()
    ..writeln("import 'package:flutter_test/flutter_test.dart';");
  for (final file in files) {
    buffer.writeln("import 'package:$_package/${file.substring(4)}';");
  }
  buffer
    ..writeln()
    ..writeln('void main() {')
    ..writeln("  test('importa todos os ficheiros de lib/', () {")
    ..writeln('    expect(true, isTrue);')
    ..writeln('  });')
    ..writeln('}');
  return buffer.toString();
}
