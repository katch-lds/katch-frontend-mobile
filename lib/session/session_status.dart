/// Estado da sessão (modelo de classes do mobile v02, secção 6).
enum SessionStatus {
  /// A ler a sessão do armazenamento seguro, no arranque.
  restoring,

  /// Sem sessão: o Candidato ainda não iniciou sessão ou terminou-a (RF105).
  signedOut,

  /// Sessão iniciada.
  signedIn,

  /// A sessão expirou ou o servidor recusou a credencial (RNF005).
  expired,
}
