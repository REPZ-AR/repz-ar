import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/views/login_page.dart';
import 'package:repz/views/onboarding/mode_selector_page.dart';

import 'performance_test_utils.dart';

void main() {
  group('Entry flow performance smoke', () {
    testWidgets('login page renders within budget', (tester) async {
      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: LoginPage(onContinue: () {}),
            ),
          );
        },
        label: 'entry_login_render',
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 800),
        scenario: 'Login page render',
      );
    });

    testWidgets('login CTA responds within budget', (tester) async {
      var continueCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            onContinue: () {
              continueCalls += 1;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('Continue with Google'));
        },
        label: 'entry_login_tap',
      );

      expect(continueCalls, 1);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 500),
        scenario: 'Login CTA tap',
      );
    });

    testWidgets('mode selector renders within budget', (tester) async {
      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: ModeSelectorPage(
                mode: null,
                isDarkMode: false,
                onThemeChanged: (_) {},
                userName: 'Taylor',
                onSelectMode: (_) async {},
                onCompleteOnboarding: (_) async {},
              ),
            ),
          );
        },
        label: 'entry_mode_selector_render',
      );

      expect(find.text('I am a Trainee'), findsOneWidget);
      expect(find.text('I am an Instructor'), findsOneWidget);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 900),
        scenario: 'Mode selector render',
      );
    });

    testWidgets('mode selector actions respond within budget', (tester) async {
      var selectedModes = <ProfileMode>[];

      await tester.pumpWidget(
        MaterialApp(
          home: ModeSelectorPage(
            mode: null,
            isDarkMode: false,
            onThemeChanged: (_) {},
            userName: 'Taylor',
            onSelectMode: (mode) async {
              selectedModes.add(mode);
            },
            onCompleteOnboarding: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final traineeElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('I am a Trainee'));
        },
        label: 'entry_mode_selector_tap_trainee',
      );

      final trainerElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('I am an Instructor'));
        },
        label: 'entry_mode_selector_tap_trainer',
      );

      expect(selectedModes, <ProfileMode>[
        ProfileMode.user,
        ProfileMode.trainer,
      ]);
      expectWithinBudget(
        traineeElapsed,
        const Duration(milliseconds: 500),
        scenario: 'Mode selector trainee tap',
      );
      expectWithinBudget(
        trainerElapsed,
        const Duration(milliseconds: 500),
        scenario: 'Mode selector trainer tap',
      );
    });
  });
}
