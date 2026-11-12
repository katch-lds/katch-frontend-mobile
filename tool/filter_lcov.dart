// Retira do lcov.info os ficheiros excluídos da cobertura (I075; plano de
// testes do frontend mobile, secção 10) e indica a cobertura de linhas.
//
//   dart run tool/filter_lcov.dart [coverage/lcov.info]
import 'dart:io';

import 'coverage_scope.dart';

void main(List<String> arguments) {
  final path = arguments.isEmpty ? 'coverage/lcov.info' : arguments.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('$path não existe. Execute: flutter test --coverage');
    exitCode = 1;
    return;
  }
  final kept = <String>[];
  final removed = <String>[];
  var found = 0;
  var hit = 0;
  for (final record in records(file.readAsStringSync())) {
    final source = sourceOf(record);
    if (source != null && isExcludedFromCoverage(source)) {
      removed.add(normalizePath(source));
      continue;
    }
    kept.add(record);
    found += counter(record, 'LF:');
    hit += counter(record, 'LH:');
  }
  file.writeAsStringSync(kept.map((r) => '$r\nend_of_record\n').join());
  for (final source in removed) {
    stdout.writeln('Retirado do lcov.info: $source');
  }
  final percent = found == 0 ? 0 : 100 * hit / found;
  stdout.writeln(
    'Cobertura de linhas: ${percent.toStringAsFixed(1)}% '
    '($hit de $found linhas, ${kept.length} ficheiros)',
  );
}

/// Registos do lcov.info, sem a linha `end_of_record`.
List<String> records(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .split('end_of_record')
      .map((record) => record.trim())
      .where((record) => record.isNotEmpty)
      .toList();
}

String? sourceOf(String record) {
  for (final line in record.split('\n')) {
    if (line.startsWith('SF:')) {
      return line.substring(3);
    }
  }
  return null;
}

int counter(String record, String prefix) {
  for (final line in record.split('\n')) {
    if (line.startsWith(prefix)) {
      return int.tryParse(line.substring(prefix.length)) ?? 0;
    }
  }
  return 0;
}
