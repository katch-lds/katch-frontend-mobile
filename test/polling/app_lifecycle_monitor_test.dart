import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/polling/app_lifecycle_monitor.dart';

void main() {
  test('indica o primeiro plano e avisa só quando muda', () {
    final monitor = AppLifecycleMonitor();
    var changes = 0;
    monitor.addListener(() => changes++);

    expect(monitor.inForeground, isTrue);

    monitor.didChangeAppLifecycleState(AppLifecycleState.inactive);
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(monitor.inForeground, isFalse);
    expect(changes, 1);

    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(monitor.inForeground, isTrue);
    expect(changes, 2);

    monitor.dispose();
  });
}
