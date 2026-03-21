import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repz/main.dart';
import 'package:repz/model/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthGate', () {
    testWidgets(
      'shows login for unauthenticated users and calls Google sign in',
      (tester) async {
        final authGateway = FakeAuthGateway();
        final profileGateway = FakeProfileGateway();
        final workoutGateway = FakeWorkoutGateway();
        addTearDown(authGateway.dispose);

        await tester.pumpWidget(
          _TestApp(
            authGateway: authGateway,
            profileGateway: profileGateway,
            workoutGateway: workoutGateway,
          ),
        );

        expect(find.text('Continue with Google'), findsOneWidget);

        await tester.tap(find.text('Continue with Google'));
        await tester.pump();

        expect(authGateway.signInCalls, 1);
      },
    );

    testWidgets('shows loading indicator while profile is being fetched', (
      tester,
    ) async {
      final session = _sessionForUser();
      final authGateway = FakeAuthGateway(initialSession: session);
      final completer = Completer<Profile?>();
      final profileGateway = FakeProfileGateway(
        onFetchProfile: (_) => completer.future,
      );
      final workoutGateway = FakeWorkoutGateway();
      addTearDown(authGateway.dispose);

      await tester.pumpWidget(
        _TestApp(
          authGateway: authGateway,
          profileGateway: profileGateway,
          workoutGateway: workoutGateway,
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('routes first-time users to mode selector and onboarding', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final session = _sessionForUser();
      final authGateway = FakeAuthGateway(initialSession: session);
      final firstTimeProfile = _profile(firstTime: true);
      final updatedProfile = _profile(firstTime: true, mode: ProfileMode.user);
      final profileGateway = FakeProfileGateway(
        onFetchProfile: (_) async => firstTimeProfile,
        onSaveMode: (userId, mode) async {
          expect(userId, firstTimeProfile.userId);
          expect(mode, ProfileMode.user);
          return updatedProfile;
        },
      );
      final workoutGateway = FakeWorkoutGateway();
      addTearDown(authGateway.dispose);

      await tester.pumpWidget(
        _TestApp(
          authGateway: authGateway,
          profileGateway: profileGateway,
          workoutGateway: workoutGateway,
        ),
      );
      await tester.pump();

      expect(find.text('I am a Trainee'), findsOneWidget);

      await tester.tap(find.text('I am a Trainee'));
      await tester.pump();

      expect(profileGateway.saveModeCalls, 1);
      expect(find.text('Getting Started'), findsOneWidget);
    });

    testWidgets('routes returning users to the main page', (tester) async {
      final session = _sessionForUser();
      final authGateway = FakeAuthGateway(initialSession: session);
      final profileGateway = FakeProfileGateway(
        onFetchProfile:
            (_) async => _profile(firstTime: false, mode: ProfileMode.user),
      );
      final workoutGateway = FakeWorkoutGateway();
      addTearDown(authGateway.dispose);

      await tester.pumpWidget(
        _TestApp(
          authGateway: authGateway,
          profileGateway: profileGateway,
          workoutGateway: workoutGateway,
        ),
      );
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.authGateway,
    required this.profileGateway,
    required this.workoutGateway,
  });

  final AuthGateway authGateway;
  final ProfileGateway profileGateway;
  final WorkoutGateway workoutGateway;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthGate(
        isDarkMode: true,
        onThemeChanged: (_) {},
        authGateway: authGateway,
        profileGateway: profileGateway,
        workoutGateway: workoutGateway,
      ),
    );
  }
}

class FakeWorkoutGateway implements WorkoutGateway {
  @override
  Future<int> fetchWorkoutProgress(String userId) async => 0;

  @override
  Future<void> syncWorkoutProgress(String userId, int index) async {}
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({Session? initialSession}) : _currentSession = initialSession;

  final _controller = StreamController<AuthState>.broadcast();
  Session? _currentSession;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  Session? get currentSession => _currentSession;

  @override
  Future<void> signInWithGoogle() async {
    signInCalls += 1;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  void emit(AuthChangeEvent event, Session? session) {
    _currentSession = session;
    _controller.add(AuthState(event, session));
  }

  Future<void> dispose() => _controller.close();
}

class FakeProfileGateway implements ProfileGateway {
  FakeProfileGateway({
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

  int fetchProfileCalls = 0;
  int saveModeCalls = 0;

  @override
  Future<Profile?> fetchProfile(String userId) async {
    fetchProfileCalls += 1;
    if (onFetchProfile != null) {
      return onFetchProfile!(userId);
    }
    return null;
  }

  @override
  Future<Profile> saveMode(String userId, ProfileMode mode) {
    saveModeCalls += 1;
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
    appMetadata: {},
    userMetadata: {'full_name': 'First Timer'},
    aud: 'authenticated',
    email: 'first.timer@example.com',
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
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}
