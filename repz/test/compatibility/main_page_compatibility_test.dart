import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../performance/main_page_perf_harness.dart';
import 'compatibility_test_utils.dart';

void main() {
  group('MainPage compatibility', () {
    for (final viewport in kCompatibilityViewports) {
      for (final isDarkMode in <bool>[true, false]) {
        final themeName = isDarkMode ? 'dark' : 'light';

        testWidgets(
          'trainee shell is stable on ${viewport.name} in $themeName mode',
          (tester) async {
            await expectNoFlutterErrorsDuring(tester, () async {
              await pumpWithViewport(
                tester,
                buildMainPageApp(
                  isCoach: false,
                  isDarkMode: isDarkMode,
                ),
                size: viewport.size,
              );

              expect(find.text('Trainee Home'), findsOneWidget);

              final Offset center = tester.getCenter(
                find.byKey(const ValueKey<String>('main_page_camera_button')),
                warnIfMissed: false,
              );
              await tester.tapAt(center);
              await tester.pumpAndSettle();

              expect(find.text('Create Workout Plan'), findsOneWidget);
              expect(find.text('Equipment Detection View'), findsOneWidget);
              expect(find.text("Start Today's Plan"), findsOneWidget);
            });
          },
        );

        testWidgets(
          'trainer shell is stable on ${viewport.name} in $themeName mode',
          (tester) async {
            await expectNoFlutterErrorsDuring(tester, () async {
              await pumpWithViewport(
                tester,
                buildMainPageApp(
                  isCoach: true,
                  isDarkMode: isDarkMode,
                ),
                size: viewport.size,
              );

              expect(find.text('Trainer Home'), findsOneWidget);

              await tester.tap(find.text('Clients'));
              await tester.pumpAndSettle();
              expect(find.text('Client Management'), findsOneWidget);

              final Offset center = tester.getCenter(
                find.byKey(const ValueKey<String>('main_page_camera_button')),
                warnIfMissed: false,
              );
              await tester.tapAt(center);
              await tester.pumpAndSettle();

              expect(find.text('Create Client Plan'), findsOneWidget);
              expect(find.text('Assign Existing Plan'), findsOneWidget);
              expect(find.text('View Client Plans'), findsOneWidget);
            });
          },
        );
      }
    }
  });
}
