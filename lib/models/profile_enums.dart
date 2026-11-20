import 'json.dart';

/// Disponibilidade do Candidato (`Availability`, API v02, secção 2.4).
enum Availability with WireValue {
  immediate('IMMEDIATE', 'Imediata'),
  fifteenDays('FIFTEEN_DAYS', '15 dias'),
  oneMonth('ONE_MONTH', '1 mês'),
  toBeAgreed('TO_BE_AGREED', 'A combinar');

  const Availability(this.wire, this.label);

  /// Valor usado no JSON da API.
  @override
  final String wire;

  /// Designação apresentada ao Candidato.
  final String label;

  /// Converte o valor do JSON; um valor desconhecido é rejeitado.
  static Availability fromWire(String value) =>
      values.byWire(value, 'Disponibilidade desconhecida');
}

/// Regime de trabalho (`WorkMode`, API v02, secção 2.4).
enum WorkMode with WireValue {
  onSite('ON_SITE', 'Presencial'),
  hybrid('HYBRID', 'Híbrido'),
  remote('REMOTE', 'Remoto');

  const WorkMode(this.wire, this.label);

  @override
  final String wire;
  final String label;

  static WorkMode fromWire(String value) =>
      values.byWire(value, 'Regime de trabalho desconhecido');
}

/// Tipo de contrato (`ContractType`, API v02, secção 2.4).
enum ContractType with WireValue {
  permanent('PERMANENT', 'Sem termo'),
  fixedTerm('FIXED_TERM', 'A termo'),
  internship('INTERNSHIP', 'Estágio'),
  serviceProvision('SERVICE_PROVISION', 'Prestação de serviços');

  const ContractType(this.wire, this.label);

  @override
  final String wire;
  final String label;

  static ContractType fromWire(String value) =>
      values.byWire(value, 'Tipo de contrato desconhecido');
}
