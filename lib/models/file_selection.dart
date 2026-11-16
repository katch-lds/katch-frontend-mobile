/// Ficheiro escolhido no dispositivo (modelo de classes, secção 3.4).
///
/// Fotografia ou curriculum vitae, com o nome, o caminho local (ou o conteúdo,
/// nos testes), a dimensão e os primeiros bytes do conteúdo. É validado
/// localmente (`InputRules`) antes de ser enviado; o servidor volta a
/// verificar o formato real (RNF016).
final class FileSelection {
  const FileSelection({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
    this.header = const [],
  });

  /// Bytes lidos do início do ficheiro para reconhecer o formato.
  static const headerLength = 8;

  final String name;

  /// Caminho local do ficheiro escolhido, ou `null` com `bytes`.
  final String? path;

  /// Conteúdo em memória, usado quando não há caminho local.
  final List<int>? bytes;

  final int sizeBytes;

  /// Primeiros bytes do conteúdo (no máximo `headerLength`).
  final List<int> header;

  /// Ficheiro em memória: a dimensão e o início vêm do próprio conteúdo.
  factory FileSelection.fromBytes(String name, List<int> bytes) {
    return FileSelection(
      name: name,
      sizeBytes: bytes.length,
      bytes: bytes,
      header: bytes.take(headerLength).toList(),
    );
  }

  /// Extensão em minúsculas, com o ponto («.pdf»), ou texto vazio.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }

  /// Tipo de conteúdo deduzido da extensão.
  String get mimeType => switch (extension) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
