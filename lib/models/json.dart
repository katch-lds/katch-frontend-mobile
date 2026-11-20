/// Objeto JSON já descodificado.
typedef Json = Map<String, Object?>;

/// Lista JSON [json] convertida elemento a elemento; sem valor, lista vazia.
List<T> readList<T>(Object? json, T Function(Object? item) convert) => [
  for (final item in json as List<Object?>? ?? const []) convert(item),
];

/// Lista JSON de textos; sem valor, lista vazia.
List<String> readStrings(Object? json) =>
    readList(json, (item) => item as String);

/// Enumeração com o valor usado no JSON da API (`wire`).
mixin WireValue on Enum {
  String get wire;

  String toWire() => wire;
}

extension WireValues<T extends WireValue> on List<T> {
  /// Valor cujo `wire` é [value]; um valor desconhecido é rejeitado com a
  /// indicação [unknown].
  T byWire(String value, String unknown) {
    for (final item in this) {
      if (item.wire == value) {
        return item;
      }
    }
    throw FormatException('$unknown: $value');
  }
}
