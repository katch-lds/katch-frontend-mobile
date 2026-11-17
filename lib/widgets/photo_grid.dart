import 'package:material_ui/material_ui.dart';

import '../core/credential_provider.dart';
import 'remote_image.dart';

/// Fotografias de uma vaga ou da galeria da Empresa, em grelha de 3 colunas.
///
/// A grelha não desliza, para não competir com o gesto de deslizar o cartão de
/// vaga (RNF010).
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.urls,
    required this.baseUrl,
    required this.credentials,
  });

  final List<String> urls;
  final String baseUrl;
  final CredentialProvider credentials;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final url in urls)
          RemoteImage(
            url: url,
            baseUrl: baseUrl,
            credentials: credentials,
            circular: false,
          ),
      ],
    );
  }
}
