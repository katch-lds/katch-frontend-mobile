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
    return _launch(uri);
  }

  @override
  Future<bool> openEmail(String address) {
    return _launch(emailUri(address));
  }

  @override
  Future<bool> openPhone(String number) {
    return _launch(phoneUri(number));
  }

  /// Endereço `mailto:` do contacto da Empresa.
  static Uri emailUri(String address) {
    return Uri(scheme: 'mailto', path: address.trim());
  }

  /// Endereço `tel:` do contacto da Empresa, só com os algarismos.
  static Uri phoneUri(String number) {
    return Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
