import 'package:flutter/foundation.dart';

/// `ChangeNotifier` que deixa de notificar depois de `dispose()`: o ecrã pode
/// fechar antes de um pedido terminar.
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @protected
  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
