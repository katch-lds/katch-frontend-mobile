import 'dart:collection';
import 'dart:convert';

import 'package:katch_mobile/core/device_file_picker.dart';
import 'package:katch_mobile/core/input_rules.dart';
import 'package:katch_mobile/models/file_selection.dart';

/// Ficheiros de teste, gerados no próprio teste (plano de testes do frontend
/// mobile, secção 6).
abstract final class TestFiles {
  /// Imagem PNG válida de 1×1 píxel.
  static final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
    'hKmMIQAAAABJRU5ErkJggg==',
  );

  /// PDF mínimo válido (assinatura `%PDF-`).
  static final pdf = latin1.encode(
    '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
    '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
    '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n'
    'trailer<</Root 1 0 R>>\n%%EOF\n',
  );

  /// Imagem PNG com 5 MB + 1 byte (P01): a assinatura PNG seguida de zeros.
  static List<int> pngOverLimit() {
    final bytes = List<int>.filled(InputRules.maxFileBytes + 1, 0);
    bytes.setRange(0, 8, png);
    return bytes;
  }

  static FileSelection photo() => FileSelection.fromBytes('foto.png', png);

  static FileSelection cv() => FileSelection.fromBytes('cv.pdf', pdf);

  static FileSelection photoOverLimit() =>
      FileSelection.fromBytes('grande.png', pngOverLimit());

  /// Ficheiro com a extensão `.pdf` e conteúdo de outro formato (RNF016).
  static FileSelection fakePdf() => FileSelection.fromBytes('falso.pdf', png);
}

/// Seletor de ficheiros dos testes de sistema: devolve, por ordem, os ficheiros
/// postos na fila, porque o seletor nativo não é controlável pelo teste
/// (plano de testes do frontend mobile, secção 4.3).
class QueuedFilePicker implements DeviceFilePicker {
  final _images = Queue<FileSelection>();
  final _pdfs = Queue<FileSelection>();

  void nextImage(FileSelection file) => _images.add(file);

  void nextPdf(FileSelection file) => _pdfs.add(file);

  @override
  Future<FileSelection?> pickImage() async =>
      _images.isEmpty ? null : _images.removeFirst();

  @override
  Future<FileSelection?> pickPdf() async =>
      _pdfs.isEmpty ? null : _pdfs.removeFirst();
}
