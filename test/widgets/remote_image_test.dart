import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/widgets/remote_image.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('sem sessão mostra o marcador', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteImage(
          url: '/api/files/profile-photo/a.jpg',
          baseUrl: 'https://api.test',
          credentials: app.session,
        ),
      ),
    );

    expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('pede a imagem com a credencial de sessão', (tester) async {
    final app = TestApp();
    await app.session.start(candidateLogin(token: 'abc'));
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteImage(
          url: '/api/files/profile-photo/a.jpg',
          baseUrl: 'https://api.test/',
          credentials: app.session,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byKey(const Key('remote-image')));
    final provider = image.image as NetworkImage;
    expect(provider.url, 'https://api.test/api/files/profile-photo/a.jpg');
    expect(provider.headers?['Authorization'], 'Bearer abc');
    expect(provider.headers?['X-Client-App'], 'mobile');

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);
  });

  testWidgets('não envia a credencial a um URL fora da API', (tester) async {
    final app = TestApp();
    await app.session.start(candidateLogin(token: 'abc'));
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteImage(
          url: 'https://outro.exemplo.pt/api/files/a.jpg',
          baseUrl: 'https://api.test',
          credentials: app.session,
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);
  });

  testWidgets('a fotografia retangular ocupa o espaço dado', (tester) async {
    final app = TestApp();
    await app.session.start(candidateLogin(token: 'abc'));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            height: 90,
            child: RemoteImage(
              url: '/api/files/job-photo/a.jpg',
              baseUrl: 'https://api.test',
              credentials: app.session,
              circular: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ClipOval), findsNothing);
    expect(find.byType(ClipRRect), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('remote-image'))),
      const Size(120, 90),
    );
  });
}
