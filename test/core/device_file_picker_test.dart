import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/device_file_picker.dart';
import 'package:katch_mobile/core/input_rules.dart';

void main() {
  test('lê a dimensão e o início do ficheiro escolhido', () async {
    final dir = await Directory.systemTemp.createTemp('katch-picker');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/cv.pdf');
    await file.writeAsString('%PDF-1.7\n${'x' * 100}');

    final selection = await readFileSelection(file.path, 'cv.pdf');

    expect(selection.name, 'cv.pdf');
    expect(selection.path, file.path);
    expect(selection.sizeBytes, 109);
    expect(selection.header, '%PDF-1.7'.codeUnits);
    expect(InputRules.cvError(selection), isNull);
  });
}
