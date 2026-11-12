/// Data e hora atuais em UTC (modelo de classes do mobile v02, 4.2).
///
/// Nos testes é substituído por um relógio fixo, para verificar a expiração
/// da sessão (RNF005, P20).
abstract interface class Clock {
  DateTime now();
}

/// Relógio do dispositivo.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
