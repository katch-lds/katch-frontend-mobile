import 'dart:io';

import '../models/file_selection.dart';

/// Seletor de ficheiros do dispositivo (modelo de classes, secção 4.2).
///
/// Abre o seletor para a fotografia (JPEG ou PNG) e para o curriculum vitae
/// (PDF). Devolve `null` quando o Candidato desiste. Nos testes é substituído
/// por um seletor simulado.
abstract interface class DeviceFilePicker {
  Future<FileSelection?> pickImage();

  Future<FileSelection?> pickPdf();
}

/// Lê a dimensão e os primeiros bytes de um ficheiro local, para a validação
/// local do formato (`InputRules.photoError` e `cvError`).
Future<FileSelection> readFileSelection(String path, String name) async {
  final file = File(path);
  final size = await file.length();
  final header = <int>[];
  await for (final chunk in file.openRead(0, FileSelection.headerLength)) {
    header.addAll(chunk);
  }
  return FileSelection(name: name, path: path, sizeBytes: size, header: header);
}
