import 'package:url_launcher/url_launcher.dart';

import 'external_launcher.dart';

/// `ExternalLauncher` com o pacote `url_launcher`.
class PlatformExternalLauncher implements ExternalLauncher {
  const PlatformExternalLauncher();

  /// Só são abertos endereços `http` e `https` (P10).
  static const _schemes = {'http', 'https'};

  @override
  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_schemes.contains(uri.scheme)) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
