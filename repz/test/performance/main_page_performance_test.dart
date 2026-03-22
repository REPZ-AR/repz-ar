import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_page_perf_harness.dart';
import 'performance_test_utils.dart';

void main() {
  group('MainPage performance smoke', () {
    testWidgets('trainee shell renders and opens radial menu within budget', (
      tester,
    ) async {
      var createPlanCalls = 0;

      final renderElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            buildMainPageApp(
              isCoach: false,
              onOpenWorkoutBuilderOverride: () async {
                createPlanCalls += 1;
              },
            ),
          );
        },
        label: 'main_page_trainee_render',
      );

      expect(find.text('Trainee Home'), findsOneWidget);
      expectWithinBudget(
        renderElapsed,
        const Duration(milliseconds: 900),
        scenario: 'Trainee main shell render',
      );

      final radialElapsed = await measureSettledActionDuration(
        tester,
        () async {
          final center = tester.getCenter(
            find.byKey(const ValueKey<String>('main_page_camera_button')),
            warnIfMissed: false,
          );
          await tester.tapAt(center);
        },
        label: 'main_page_trainee_radial_open',
      );

      expect(find.text('Create Workout Plan'), findsOneWidget);
      expect(find.text('Equipment Detection View'), findsOneWidget);
      expect(find.text("Start Today's Plan"), findsOneWidget);
      expectWithinBudget(
        radialElapsed,
        const Duration(milliseconds: 700),
        scenario: 'Trainee radial menu open',
      );

      final actionElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('Create Workout Plan'));
        },
        label: 'main_page_trainee_create_plan_action',
      );

      expect(createPlanCalls, 1);
      expectWithinBudget(
        actionElapsed,
        const Duration(milliseconds: 700),
        scenario: 'Trainee create-plan action',
      );
    });

    testWidgets('trainer shell navigates and opens assign menu within budget', (
      tester,
    ) async {
      var libraryCalls = 0;

      final renderElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            buildMainPageApp(
              isCoach: true,
              onOpenTrainerPlanLibraryOverride: () async {
                libraryCalls += 1;
              },
            ),
          );
        },
        label: 'main_page_trainer_render',
      );

      expect(find.text('Trainer Home'), findsOneWidget);
      expectWithinBudget(
        renderElapsed,
        const Duration(milliseconds: 900),
        scenario: 'Trainer main shell render',
      );

      final clientsNavElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('Clients'));
        },
        label: 'main_page_trainer_clients_nav',
      );

      expect(find.text('Client Management'), findsOneWidget);
      expectWithinBudget(
        clientsNavElapsed,
        const Duration(milliseconds: 700),
        scenario: 'Trainer clients tab switch',
      );

      final radialElapsed = await measureSettledActionDuration(
        tester,
        () async {
          final center = tester.getCenter(
            find.byKey(const ValueKey<String>('main_page_camera_button')),
            warnIfMissed: false,
          );
          await tester.tapAt(center);
        },
        label: 'main_page_trainer_radial_open',
      );

      expect(find.text('Create Client Plan'), findsOneWidget);
      expect(find.text('Assign Existing Plan'), findsOneWidget);
      expect(find.text('View Client Plans'), findsOneWidget);
      expectWithinBudget(
        radialElapsed,
        const Duration(milliseconds: 700),
        scenario: 'Trainer radial menu open',
      );

      final actionElapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.tap(find.text('Assign Existing Plan'));
        },
        label: 'main_page_trainer_library_action',
      );

      expect(libraryCalls, 1);
      expectWithinBudget(
        actionElapsed,
        const Duration(milliseconds: 700),
        scenario: 'Trainer assign-existing-plan action',
      );
    });
  });
}
