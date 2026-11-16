import 'session.dart';

/// Armazenamento da sessão no dispositivo (modelo de classes, secção 6).
///
/// A implementação real é o `SecureSessionStorage`; nos testes é usada uma
/// implementação em memória (plano de testes do mobile, 4.3).
abstract interface class SessionStorage {
  Future<Session?> read();

  Future<void> write(Session session);

  Future<void> clear();
}
