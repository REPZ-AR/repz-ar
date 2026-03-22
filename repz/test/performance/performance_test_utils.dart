import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Duration> measurePumpDuration(
  WidgetTester tester,
  Future<void> Function() action, {
  String? label,
}) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();

  if (label != null) {
    debugPrint('[perf] $label: ${stopwatch.elapsedMilliseconds}ms');
  }

  return stopwatch.elapsed;
}

Future<Duration> measureSettledActionDuration(
  WidgetTester tester,
  Future<void> Function() action, {
  String? label,
}) async {
  final stopwatch = Stopwatch()..start();
  await action();
  await tester.pumpAndSettle();
  stopwatch.stop();

  if (label != null) {
    debugPrint('[perf] $label: ${stopwatch.elapsedMilliseconds}ms');
  }

  return stopwatch.elapsed;
}

void expectWithinBudget(
  Duration actual,
  Duration budget, {
  required String scenario,
}) {
  expect(
    actual,
    lessThanOrEqualTo(budget),
    reason:
        '$scenario exceeded budget: ${actual.inMilliseconds}ms > ${budget.inMilliseconds}ms',
  );
}
