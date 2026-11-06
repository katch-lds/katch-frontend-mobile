import 'dart:async';

/// Repete uma tarefa a intervalo fixo, sem sobrepor execuções (secção 7).
class PollingLoop {
  PollingLoop(this._task, {this.interval = defaultInterval});

  /// Intervalo da consulta periódica das conversas (API v02, secção 7).
  static const defaultInterval = Duration(seconds: 3);

  final Future<void> Function() _task;
  final Duration interval;
  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  void start() {
    if (_running) {
      return;
    }
    _running = true;
    _schedule(Duration.zero);
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(Duration delay) {
    _timer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    try {
      await _task();
    } on Object {
      // Uma consulta falhada não interrompe o ciclo: segue a próxima.
    }
    if (_running) {
      _schedule(interval);
    }
  }
}
