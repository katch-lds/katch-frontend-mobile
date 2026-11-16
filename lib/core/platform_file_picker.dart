import 'package:file_selector/file_selector.dart';

import '../models/file_selection.dart';
import 'device_file_picker.dart';

/// `DeviceFilePicker` com o seletor de ficheiros do Android (`file_selector`).
class PlatformFilePicker implements DeviceFilePicker {
  const PlatformFilePicker();

  @override
  Future<FileSelection?> pickImage() {
    return _pick(
      XTypeGroup(
        label: 'Fotografia (JPEG ou PNG)',
        extensions: ['jpg', 'jpeg', 'png'],
        mimeTypes: ['image/jpeg', 'image/png'],
      ),
    );
  }

  @override
  Future<FileSelection?> pickPdf() {
    return _pick(
      XTypeGroup(
        label: 'Curriculum vitae (PDF)',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      ),
    );
  }

  Future<FileSelection?> _pick(XTypeGroup group) async {
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) {
      return null;
    }
    return readFileSelection(file.path, file.name);
  }
}
