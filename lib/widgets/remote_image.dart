import 'package:material_ui/material_ui.dart';

import '../core/credential_provider.dart';
import '../core/http_api_client.dart';

/// Fotografia ou logótipo servido por um URL da API.
///
/// Os URL `/api/files/{kind}/{fileName}` só servem o ficheiro com credencial
/// (API v02, 6.9.1), pelo que o pedido leva o cabeçalho de autorização. A
/// credencial só é enviada à própria API: um URL que não seja um caminho
/// `/api/files/...` não é pedido. Sem URL, ou se o ficheiro não for obtido,
/// mostra o marcador do protótipo.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.baseUrl,
    required this.credentials,
    this.size = 72,
    this.circular = true,
  });

  /// Prefixo dos URL de ficheiros devolvidos pela API (API v02, 2.6).
  static const filesPath = '/api/files/';

  /// URL relativo devolvido pela API, ou `null`.
  final String? url;
  final String baseUrl;
  final CredentialProvider credentials;
  final double size;

  /// Redonda, com `size` de diâmetro (fotografia de perfil, logótipo); com
  /// `false`, ocupa o espaço dado pelo widget pai, com os cantos arredondados
  /// (fotografias da vaga e da galeria da Empresa).
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final path = url;
    final token = credentials.accessToken;
    final Widget child;
    if (path == null || token == null || !path.startsWith(filesPath)) {
      child = _placeholder(context);
    } else {
      child = Image.network(
        '$baseUrl$path',
        key: const Key('remote-image'),
        width: circular ? size : null,
        height: circular ? size : null,
        fit: BoxFit.cover,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-App': HttpApiClient.clientApp,
        },
        errorBuilder: (context, _, _) => _placeholder(context),
      );
    }
    if (!circular) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.expand(child: child),
      );
    }
    return ClipOval(
      child: SizedBox.square(dimension: size, child: child),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('remote-image-placeholder'),
      color: colors.surfaceContainerHighest,
      child: Icon(Icons.close, color: colors.onSurfaceVariant),
    );
  }
}
