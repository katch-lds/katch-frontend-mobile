import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/polling/polling_loop.dart';

void main() {
  test('repete a tarefa, continua depois de uma falha e para', () {
    fakeAsync((async) {
      var calls = 0;
      Future<void> task() async {
        calls++;
        if (calls == 1) {
          throw StateError('sem ligação');
        }
      }

      const interval = Duration(seconds: 3);
      final loop = PollingLoop(task, interval: interval)
        ..start()
        ..start();

      async.elapse(Duration.zero);
      expect(calls, 1);
      async.elapse(interval);
      expect(calls, 2);
      async.elapse(interval);
      expect(calls, 3);

      loop.stop();
      async.elapse(interval * 3);

      expect(calls, 3);
      expect(loop.isRunning, isFalse);
    });
  });

  test('o intervalo por omissão é de 3 segundos', () {
    final loop = PollingLoop(() async {});

    expect(loop.interval, const Duration(seconds: 3));
  });
}
