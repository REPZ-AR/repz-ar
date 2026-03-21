import 'package:flutter/material.dart';
import 'package:repz/config/app_config.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/repositories/auth_repository.dart';
import 'package:repz/repositories/profile_repository.dart';
import 'package:repz/repositories/workout_repository.dart';
import 'package:repz/views/main_page.dart';
import 'package:repz/views/onboarding/mode_selector_page.dart';
import 'package:repz/views/onboarding/profile_onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:repz/views/login_page.dart';

abstract class AuthGateway {
  Stream<AuthState> get onAuthStateChange;
  Session? get currentSession;
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class AuthRepositoryGateway implements AuthGateway {
  AuthRepositoryGateway({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  @override
  Stream<AuthState> get onAuthStateChange => _repository.onAuthStateChange;

  @override
  Session? get currentSession => _repository.currentSession;

  @override
  Future<void> signInWithGoogle() => _repository.signInWithGoogle();

  @override
  Future<void> signOut() => _repository.signOut();
}

abstract class ProfileGateway {
  Future<Profile?> fetchProfile(String userId);
  Future<Profile> saveMode(String userId, ProfileMode mode);
  Future<Profile> saveOnboarding({
    required String userId,
    required DateTime birthday,
    required String gender,
    required double heightCm,
    required double weightKg,
    required ExperienceLevel experience,
    required int frequency,
  });
}

class ProfileRepositoryGateway implements ProfileGateway {
  ProfileRepositoryGateway({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  @override
  Future<Profile?> fetchProfile(String userId) =>
      _repository.fetchProfile(userId);

  @override
  Future<Profile> saveMode(String userId, ProfileMode mode) =>
      _repository.saveMode(userId, mode);

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
    return _repository.saveOnboarding(
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

abstract class WorkoutGateway {
  Future<int> fetchWorkoutProgress(String userId);
  Future<void> syncWorkoutProgress(String userId, int index);
}

class WorkoutRepositoryGateway implements WorkoutGateway {
  WorkoutRepositoryGateway({WorkoutRepository? repository})
  : _repository = repository ?? WorkoutRepository();

  final WorkoutRepository _repository;

  @override
  Future<int> fetchWorkoutProgress(String userId) {
    return _repository.fetchWorkoutProgress(userId);
  }

  @override
  Future<void> syncWorkoutProgress(String userId, int index) {
    return _repository.syncWorkoutProgress(userId, index);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repz',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFA66CFF),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFCFF500),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthGate(
        isDarkMode: isDarkMode,
        onThemeChanged: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final AuthGateway? authGateway;
  final ProfileGateway? profileGateway;
  final WorkoutGateway? workoutGateway;

  const AuthGate({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.authGateway,
    this.profileGateway,
    this.workoutGateway,
  }) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = false;
  bool _profileLoading = false;
  Profile? _profile;
  String? _profileError;

  late final AuthGateway _authGateway =
      widget.authGateway ?? AuthRepositoryGateway();
  late final ProfileGateway _profileGateway =
      widget.profileGateway ?? ProfileRepositoryGateway();
  late final WorkoutGateway _workoutGateway =
      widget.workoutGateway ?? WorkoutRepositoryGateway();

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authGateway.signInWithGoogle();
    } on AuthException catch (error) {
      _showAuthError(error.message);
    } catch (_) {
      _showAuthError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      await _authGateway.signOut();
    } on AuthException catch (error) {
      _showAuthError(error.message);
    } catch (_) {
      _showAuthError('Logout failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showAuthError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadProfileFlag(User user) async {
    if (_profileLoading) {
      return;
    }

    setState(() {
      _profileLoading = true;
      _profileError = null;
    });

    try {
      final profile = await _profileGateway.fetchProfile(user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileError = 'Failed to load your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  Future<void> _saveMode(ProfileMode mode) async {
    final userId = _profile?.userId;
    if (userId == null) {
      return;
    }

    setState(() => _profileLoading = true);
    try {
      final updated = await _profileGateway.saveMode(userId, mode);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _profileError = null;
      });
    } on PostgrestException catch (error) {
      _showAuthError(error.message);
    } catch (_) {
      _showAuthError('Could not save your role. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  Future<void> _completeOnboarding(OnboardingFormData data) async {
    final userId = _profile?.userId;
    if (userId == null) {
      return;
    }

    setState(() => _profileLoading = true);
    try {
      final updated = await _profileGateway.saveOnboarding(
        userId: userId,
        birthday: data.birthday,
        gender: data.gender,
        heightCm: data.heightCm,
        weightKg: data.weightKg,
        experience: data.experience,
        frequency: data.frequency,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _profileError = null;
      });
    } on PostgrestException catch (error) {
      _showAuthError(error.message);
    } catch (_) {
      _showAuthError('Could not save onboarding details. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authGateway.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _authGateway.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) {
          return LoginPage(onContinue: _loading ? () {} : _signInWithGoogle);
        }

        final user = session.user;
        if (_profile?.userId != user.id && !_profileLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadProfileFlag(user);
            }
          });
        }

        if (_profileLoading && _profile?.userId != user.id) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_profileError != null && _profile?.userId != user.id) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load profile.'),
                    const SizedBox(height: 12),
                    Text(_profileError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadProfileFlag(user),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_profile?.userId == user.id && _profile?.firstTime == true) {
          final metadata = user.userMetadata;
          final avatarUrl = metadata?['avatar_url'] as String?;
          final displayName =
              (metadata?['full_name'] as String?) ??
              (metadata?['name'] as String?);

          return ModeSelectorPage(
            mode: _profile!.mode,
            isLoading: _profileLoading,
            userName: displayName,
            avatarUrl: avatarUrl,
            onSelectMode: _saveMode,
            onCompleteOnboarding: _completeOnboarding,
            onLogout: _loading ? null : _signOut,
            isDarkMode: widget.isDarkMode,
            userEmail: user.email,
            onThemeChanged: widget.onThemeChanged,
          );
        }

        final metadata = user.userMetadata;
        final avatarUrl = metadata?['avatar_url'] as String?;
        final displayName =
            (metadata?['full_name'] as String?) ??
            (metadata?['name'] as String?);
        final isCoach = _profile?.mode == ProfileMode.trainer;
        return MainPage(
          isDarkMode: widget.isDarkMode,
          isCoach: isCoach,
          avatarUrl: avatarUrl,
          userName: displayName,
          userEmail: user.email,
          userId: user.id,
          workoutGateway: _workoutGateway,
          onLogout: _loading ? null : _signOut,
          onThemeChanged: widget.onThemeChanged,
        );
      },
    );
  }
}
