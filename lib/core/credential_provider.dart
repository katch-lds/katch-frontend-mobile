/// Fonte da credencial de sessão usada pelo `HttpApiClient` (secção 4.1).
abstract interface class CredentialProvider {
  /// Credencial de sessão (JWT), ou `null` sem sessão iniciada.
  String? get accessToken;

  /// Chamado quando o servidor recusa a credencial; termina a sessão.
  void rejectCredential();
}
