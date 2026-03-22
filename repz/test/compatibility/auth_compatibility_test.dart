import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/views/login_page.dart';
import 'package:repz/views/onboarding/mode_selector_page.dart';

import 'compatibility_test_utils.dart';

void main() {
  group('Authentication compatibility', () {
    for (final viewport in kCompatibilityViewports) {
      testWidgets('login page is stable on ${viewport.name}', (tester) async {
        var continueCalls = 0;

        await expectNoFlutterErrorsDuring(tester, () async {
          await pumpWithViewport(
            tester,
            MaterialApp(
              home: LoginPage(
                onContinue: () {
                  continueCalls += 1;
                },
              ),
            ),
            size: viewport.size,
          );

          expect(find.text('Continue with Google'), findsOneWidget);
          expect(find.text('Your best self is awaiting!'), findsOneWidget);

          await tester.tap(find.text('Continue with Google'));
          await tester.pumpAndSettle();

          expect(continueCalls, 1);
        });
      });

      testWidgets(
        'mode selector is stable on ${viewport.name} in both roles',
        (tester) async {
          var selectedMode = <ProfileMode>[];

          await expectNoFlutterErrorsDuring(tester, () async {
            await pumpWithViewport(
              tester,
              MaterialApp(
                home: ModeSelectorPage(
                  mode: null,
                  isDarkMode: false,
                  onThemeChanged: (_) {},
                  userName: 'Taylor Coach',
                  onSelectMode: (mode) async {
                    selectedMode.add(mode);
                  },
                  onCompleteOnboarding: (_) async {},
                ),
              ),
              size: viewport.size,
            );

            expect(find.text('What is\nYour Role?'), findsOneWidget);
            expect(find.text('I am a Trainee'), findsOneWidget);
            expect(find.text('I am an Instructor'), findsOneWidget);

            await tester.tap(find.text('I am a Trainee'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('I am an Instructor'));
            await tester.pumpAndSettle();

            expect(selectedMode, <ProfileMode>[
              ProfileMode.user,
              ProfileMode.trainer,
            ]);
          });
        },
      );
    }
  });
}
