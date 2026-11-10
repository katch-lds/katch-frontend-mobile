import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/polling/polling_loop.dart';

void main() {
  test('repete a tarefa, continua depois de uma falha e para', () async {
    var calls = 0;
    Future<void> task() async {
      calls++;
      if (calls == 1) {
        throw StateError('sem ligação');
      }
    }

    const interval = Duration(milliseconds: 10);
    final loop = PollingLoop(task, interval: interval);

    loop.start();
    loop.start();
    await Future<void>.delayed(const Duration(milliseconds: 45));
    loop.stop();
    final afterStop = calls;
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(afterStop, greaterThanOrEqualTo(3));
    expect(calls, afterStop);
    expect(loop.isRunning, isFalse);
  });

  test('o intervalo por omissão é de 3 segundos', () {
    final loop = PollingLoop(() async {});

    expect(loop.interval, const Duration(seconds: 3));
  });
}
