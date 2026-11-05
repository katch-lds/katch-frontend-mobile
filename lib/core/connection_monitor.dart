import 'package:flutter/foundation.dart';

/// Guarda se o último pedido falhou por falta de ligação (RNF014).
class ConnectionMonitor extends ChangeNotifier {
  bool _hasFailure = false;

  bool get hasFailure => _hasFailure;

  void reportFailure() => _set(true);

  void reportSuccess() => _set(false);

  void _set(bool value) {
    if (_hasFailure == value) {
      return;
    }
    _hasFailure = value;
    notifyListeners();
  }
}
