import 'package:flutter/widgets.dart';

/// Indica se a aplicação está em primeiro plano (modelo de classes, secção 7).
///
/// É registado no `WidgetsBinding` em `main.dart` e avisa quem o observa
/// quando a aplicação muda de plano: a área de exploração volta a pedir a quota
/// e o cartão ao regressar ao primeiro plano (DFM-15).
class AppLifecycleMonitor extends ChangeNotifier with WidgetsBindingObserver {
  bool _inForeground = true;

  bool get inForeground => _inForeground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _inForeground) {
      return;
    }
    _inForeground = foreground;
    notifyListeners();
  }
}
