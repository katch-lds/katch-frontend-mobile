import 'json.dart';

/// Tipo de conta (`UserType` da API v02, secção 2.4).
enum UserType with WireValue {
  candidate('CANDIDATE'),
  recruiter('RECRUITER'),
  admin('ADMIN');

  const UserType(this.wire);

  /// Valor usado no JSON da API.
  @override
  final String wire;

  /// Converte o valor do JSON; um valor desconhecido é rejeitado.
  static UserType fromWire(String value) =>
      values.byWire(value, 'Tipo de conta desconhecido');
}
