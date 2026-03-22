import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_page_perf_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MainPage visual smoke', () {
    testWidgets('captures trainee shell and open menu', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildMainPageApp(isCoach: false));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/main_page_trainee_shell.png',
        ),
      );

      final center = tester.getCenter(
        find.byKey(const ValueKey<String>('main_page_camera_button')),
        warnIfMissed: false,
      );
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/main_page_trainee_menu_open.png',
        ),
      );
    });

    testWidgets('captures trainer shell and open menu', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildMainPageApp(isCoach: true));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/main_page_trainer_shell.png',
        ),
      );

      final center = tester.getCenter(
        find.byKey(const ValueKey<String>('main_page_camera_button')),
        warnIfMissed: false,
      );
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/main_page_trainer_menu_open.png',
        ),
      );
    });
  });
}
