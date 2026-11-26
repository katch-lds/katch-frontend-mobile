import '../models/file_selection.dart';

/// Seletor de ficheiros do dispositivo.
///
/// Abre o seletor para a fotografia (JPEG ou PNG) e para o curriculum vitae
/// (PDF). Devolve `null` quando o Candidato desiste. Nos testes é substituído
/// por um seletor simulado.
abstract interface class DeviceFilePicker {
  Future<FileSelection?> pickImage();

  Future<FileSelection?> pickPdf();
}
