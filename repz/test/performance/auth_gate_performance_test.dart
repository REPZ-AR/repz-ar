import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repz/main.dart';
import 'package:repz/model/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'performance_test_utils.dart';

void main() {
  group('AuthGate performance smoke', () {
    testWidgets('unauthenticated login shell renders within budget', (
      tester,
    ) async {
      final authGateway = _FakeAuthGateway();
      addTearDown(authGateway.dispose);

      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            _PerfTestApp(
              authGateway: authGateway,
              profileGateway: _FakeProfileGateway(),
              workoutGateway: _FakeWorkoutGateway(),
            ),
          );
        },
        label: 'auth_gate_login_render',
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 800),
        scenario: 'AuthGate login render',
      );
    });

    testWidgets('returning trainee routes to main page within budget', (
      tester,
    ) async {
      final authGateway = _FakeAuthGateway(initialSession: _sessionForUser());
      final profileGateway = _FakeProfileGateway(
        onFetchProfile:
            (_) async => _profile(firstTime: false, mode: ProfileMode.user),
      );
      addTearDown(authGateway.dispose);

      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            _PerfTestApp(
              authGateway: authGateway,
              profileGateway: profileGateway,
              workoutGateway: _FakeWorkoutGateway(),
              mainPageBuilder:
                  (user, profile, workoutGateway, onLogout) =>
                      const _FakeMainPage(label: 'Trainee Main'),
            ),
          );
        },
        label: 'auth_gate_trainee_route',
      );

      expect(find.text('Trainee Main'), findsOneWidget);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 1000),
        scenario: 'AuthGate trainee route',
      );
    });

    testWidgets('returning trainer routes to main page within budget', (
      tester,
    ) async {
      final authGateway = _FakeAuthGateway(initialSession: _sessionForUser());
      final profileGateway = _FakeProfileGateway(
        onFetchProfile:
            (_) async => _profile(firstTime: false, mode: ProfileMode.trainer),
      );
      addTearDown(authGateway.dispose);

      final elapsed = await measureSettledActionDuration(
        tester,
        () async {
          await tester.pumpWidget(
            _PerfTestApp(
              authGateway: authGateway,
              profileGateway: profileGateway,
              workoutGateway: _FakeWorkoutGateway(),
              mainPageBuilder:
                  (user, profile, workoutGateway, onLogout) =>
                      const _FakeMainPage(label: 'Trainer Main'),
            ),
          );
        },
        label: 'auth_gate_trainer_route',
      );

      expect(find.text('Trainer Main'), findsOneWidget);
      expectWithinBudget(
        elapsed,
        const Duration(milliseconds: 1000),
        scenario: 'AuthGate trainer route',
      );
    });
  });
}

class _PerfTestApp extends StatelessWidget {
  const _PerfTestApp({
    required this.authGateway,
    required this.profileGateway,
    required this.workoutGateway,
    this.mainPageBuilder,
  });

  final AuthGateway authGateway;
  final ProfileGateway profileGateway;
  final WorkoutGateway workoutGateway;
  final Widget Function(
    User user,
    Profile? profile,
    WorkoutGateway workoutGateway,
    Future<void> Function()? onLogout,
  )?
  mainPageBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthGate(
        isDarkMode: true,
        onThemeChanged: (_) {},
        authGateway: authGateway,
        profileGateway: profileGateway,
        workoutGateway: workoutGateway,
        mainPageBuilder: mainPageBuilder,
      ),
    );
  }
}

class _FakeMainPage extends StatelessWidget {
  const _FakeMainPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

class _FakeWorkoutGateway implements WorkoutGateway {
  @override
  Future<int> fetchWorkoutProgress(
    String userId, {
    String? workoutPlanId,
  }) async => 0;

  @override
  Future<void> syncWorkoutProgress(
    String userId,
    int index, {
    String? workoutPlanId,
  }) async {}
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({Session? initialSession}) : _currentSession = initialSession;

  final _controller = StreamController<AuthState>.broadcast();
  Session? _currentSession;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  Session? get currentSession => _currentSession;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  Future<void> dispose() => _controller.close();
}

class _FakeProfileGateway implements ProfileGateway {
  _FakeProfileGateway({
    this.onFetchProfile,
    this.onSaveMode,
    this.onSaveOnboarding,
  });

  final Future<Profile?> Function(String userId)? onFetchProfile;
  final Future<Profile> Function(String userId, ProfileMode mode)? onSaveMode;
  final Future<Profile> Function({
    required String userId,
    required DateTime birthday,
    required String gender,
    required double heightCm,
    required double weightKg,
    required ExperienceLevel experience,
    required int frequency,
  })?
  onSaveOnboarding;

  @override
  Future<Profile?> fetchProfile(String userId) async {
    if (onFetchProfile != null) {
      return onFetchProfile!(userId);
    }
    return null;
  }

  @override
  Future<Profile> saveMode(String userId, ProfileMode mode) {
    if (onSaveMode == null) {
      throw UnimplementedError('Provide onSaveMode for this test.');
    }
    return onSaveMode!(userId, mode);
  }

  @override
  Future<Profile> saveOnboarding({
    required String userId,
    required DateTime birthday,
    required String gender,
    required double heightCm,
    required double weightKg,
    required ExperienceLevel experience,
    required int frequency,
  }) {
    if (onSaveOnboarding == null) {
      throw UnimplementedError('Provide onSaveOnboarding for this test.');
    }
    return onSaveOnboarding!(
      userId: userId,
      birthday: birthday,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      experience: experience,
      frequency: frequency,
    );
  }
}

Session _sessionForUser() {
  const user = User(
    id: 'user-1',
    appMetadata: <String, dynamic>{},
    userMetadata: <String, dynamic>{'full_name': 'Perf User'},
    aud: 'authenticated',
    email: 'perf.user@example.com',
    createdAt: '2026-01-01T00:00:00Z',
  );

  return Session(
    accessToken: 'header.payload.signature',
    tokenType: 'bearer',
    user: user,
  );
}

Profile _profile({required bool firstTime, ProfileMode? mode}) {
  return Profile(
    userId: 'user-1',
    firstTime: firstTime,
    mode: mode,
    userName: 'Perf User',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}
