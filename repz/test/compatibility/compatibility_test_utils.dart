import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CompatibilityViewport {
  const CompatibilityViewport(this.name, this.size);

  final String name;
  final Size size;
}

const List<CompatibilityViewport> kCompatibilityViewports =
    <CompatibilityViewport>[
      CompatibilityViewport('small_phone', Size(360, 780)),
      CompatibilityViewport('medium_phone', Size(393, 852)),
      CompatibilityViewport('large_phone', Size(412, 915)),
    ];

Future<void> pumpWithViewport(
  WidgetTester tester,
  Widget widget, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> expectNoFlutterErrorsDuring(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final originalOnError = FlutterError.onError;
  final List<FlutterErrorDetails> capturedErrors = <FlutterErrorDetails>[];

  FlutterError.onError = (FlutterErrorDetails details) {
    capturedErrors.add(details);
  };

  try {
    await action();
    final dynamic asyncException = tester.takeException();
    expect(asyncException, isNull);
    expect(
      capturedErrors,
      isEmpty,
      reason: capturedErrors.isEmpty
          ? null
          : capturedErrors
              .map((details) => details.exceptionAsString())
              .join('\n\n'),
    );
  } finally {
    FlutterError.onError = originalOnError;
  }
}
