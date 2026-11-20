import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/app/app_scope.dart';
import 'package:katch_mobile/widgets/remote_image.dart';

import '../support/fakes.dart';

/// O `RemoteImage` obtém o endereço da API e a credencial do `AppScope`.
Widget scoped(TestApp app, Widget child) {
  return AppScope(
    dependencies: app.dependencies,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('sem sessão mostra o marcador', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(
      scoped(app, RemoteImage(url: '/api/files/profile-photo/a.jpg')),
    );

    expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('pede a imagem com a credencial de sessão', (tester) async {
    final app = TestApp();
    await app.session.start(candidateLogin(token: 'abc'));
    await tester.pumpWidget(
      scoped(app, RemoteImage(url: '/api/files/profile-photo/a.jpg')),
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
      scoped(app, RemoteImage(url: 'https://outro.exemplo.pt/api/files/a.jpg')),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const Key('remote-image-placeholder')), findsOneWidget);
  });

  testWidgets('a fotografia retangular ocupa o espaço dado', (tester) async {
    final app = TestApp();
    await app.session.start(candidateLogin(token: 'abc'));
    await tester.pumpWidget(
      scoped(
        app,
        Center(
          child: SizedBox(
            width: 120,
            height: 90,
            child: RemoteImage(
              url: '/api/files/job-photo/a.jpg',
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
