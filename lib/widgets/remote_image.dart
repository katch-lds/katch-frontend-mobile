import 'package:material_ui/material_ui.dart';

import '../core/credential_provider.dart';
import '../core/http_api_client.dart';
import '../core/url.dart';

/// Fotografia ou logótipo servido por um URL da API (modelo de classes, 9.4).
///
/// Os URL `/api/files/{kind}/{fileName}` só servem o ficheiro com credencial
/// (API v02, 6.9.1), pelo que o pedido leva o cabeçalho de autorização. Sem
/// URL, ou se o ficheiro não for obtido, mostra o marcador do protótipo.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.baseUrl,
    required this.credentials,
    this.size = 72,
  });

  /// URL relativo devolvido pela API, ou `null`.
  final String? url;
  final String baseUrl;
  final CredentialProvider credentials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = url;
    final token = credentials.accessToken;
    final Widget child;
    if (path == null || token == null) {
      child = _placeholder(context);
    } else {
      child = Image.network(
        path.startsWith('http') ? path : '${trimTrailingSlashes(baseUrl)}$path',
        key: const Key('remote-image'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-App': HttpApiClient.clientApp,
        },
        errorBuilder: (context, _, _) => _placeholder(context),
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
