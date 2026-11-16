/// Tipo de conta (`UserType` da API v02, secção 2.4).
enum UserType {
  candidate('CANDIDATE'),
  recruiter('RECRUITER'),
  admin('ADMIN');

  const UserType(this.wire);

  /// Valor usado no JSON da API.
  final String wire;

  /// Converte o valor do JSON; um valor desconhecido é rejeitado.
  static UserType fromWire(String value) {
    for (final type in values) {
      if (type.wire == value) {
        return type;
      }
    }
    throw FormatException('Tipo de conta desconhecido: $value');
  }

  String toWire() => wire;
}
