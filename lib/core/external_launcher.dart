/// Abre uma aplicação externa do dispositivo.
///
/// A plataforma nunca envia correio eletrónico nem SMS por si própria: só
/// entrega o endereço à aplicação do dispositivo (arquitetura, secção 2.5).
abstract interface class ExternalLauncher {
  /// Abre o endereço no navegador; devolve `false` se não for possível.
  Future<bool> openUrl(String url);
}
