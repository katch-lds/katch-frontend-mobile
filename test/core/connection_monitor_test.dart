import 'package:flutter_test/flutter_test.dart';
import 'package:katch_mobile/core/connection_monitor.dart';

void main() {
  test('avisa só quando o estado da ligação muda', () {
    final monitor = ConnectionMonitor();
    var notifications = 0;
    monitor.addListener(() => notifications++);

    monitor.reportSuccess();
    monitor.reportFailure();
    monitor.reportFailure();
    monitor.reportSuccess();

    expect(notifications, 2);
    expect(monitor.hasFailure, isFalse);
  });
}
