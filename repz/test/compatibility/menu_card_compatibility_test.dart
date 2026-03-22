import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repz/widgets/layouts/menu_card.dart';

import 'compatibility_test_utils.dart';

void main() {
  group('MenuCard compatibility', () {
    for (final viewport in kCompatibilityViewports) {
      for (final isDarkMode in <bool>[true, false]) {
        final themeName = isDarkMode ? 'dark' : 'light';

        testWidgets(
          'trainee menu card is stable on ${viewport.name} in $themeName mode',
          (tester) async {
            await expectNoFlutterErrorsDuring(tester, () async {
              await pumpWithViewport(
                tester,
                MaterialApp(
                  theme: ThemeData.light(useMaterial3: true),
                  darkTheme: ThemeData.dark(useMaterial3: true),
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: viewport.size.width - 32,
                        child: MenuCard(
                          isDarkMode: isDarkMode,
                          isCoach: false,
                        ),
                      ),
                    ),
                  ),
                ),
                size: viewport.size,
              );

              expect(find.text('Saved Plans'), findsOneWidget);
              expect(find.text('Weekly Schedule'), findsOneWidget);
              expect(find.text('Pre-built Plans'), findsOneWidget);
            });
          },
        );

        testWidgets(
          'trainer menu card is stable on ${viewport.name} in $themeName mode',
          (tester) async {
            await expectNoFlutterErrorsDuring(tester, () async {
              await pumpWithViewport(
                tester,
                MaterialApp(
                  theme: ThemeData.light(useMaterial3: true),
                  darkTheme: ThemeData.dark(useMaterial3: true),
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: viewport.size.width - 32,
                        child: MenuCard(
                          isDarkMode: isDarkMode,
                          isCoach: true,
                        ),
                      ),
                    ),
                  ),
                ),
                size: viewport.size,
              );

              expect(find.text('Client Plan Library'), findsOneWidget);
              expect(find.text('Saved Plans'), findsNothing);
              expect(find.text('Weekly Schedule'), findsNothing);
            });
          },
        );
      }
    }
  });
}
