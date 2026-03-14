import 'package:flutter/material.dart';
import 'package:repz/config/app_config.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/repositories/auth_repository.dart';
import 'package:repz/repositories/profile_repository.dart';
import 'package:repz/views/activity_page.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_management.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:repz/views/login_page.dart';

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
  bool isCoach = true;

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
        isCoach: isCoach,
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
  final bool isCoach;
  final Function(bool) onThemeChanged;

  const AuthGate({
    Key? key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = false;
  bool _profileLoading = false;
  Profile? _profile;
  String? _profileError;

  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepository();

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _authRepository.signInWithGoogle();
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
      await _authRepository.signOut();
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
      final profile = await _profileRepository.fetchProfile(user.id);

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

  Future<void> _markFirstTimeComplete() async {
    final userId = _profile?.userId;
    if (userId == null) {
      return;
    }

    setState(() => _profileLoading = true);
    try {
      final updated = await _profileRepository.markFirstTimeComplete(userId);

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
      _showAuthError('Could not complete setup. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authRepository.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _authRepository.currentSession,
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
                    Text(
                      _profileError!,
                      textAlign: TextAlign.center,
                    ),
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
          return FirstTimeSetupView(
            isLoading: _profileLoading,
            onContinue: _markFirstTimeComplete,
            onLogout: _loading ? null : _signOut,
          );
        }

        final metadata = user.userMetadata;
        final avatarUrl = metadata?['avatar_url'] as String?;
        final displayName = (metadata?['full_name'] as String?) ??
            (metadata?['name'] as String?);
        return MainPage(
          isDarkMode: widget.isDarkMode,
          isCoach: widget.isCoach,
          avatarUrl: avatarUrl,
          userName: displayName,
          userEmail: user.email,
          onLogout: _loading ? null : _signOut,
          onThemeChanged: widget.onThemeChanged,
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;
  final Future<void> Function()? onLogout;
  final Function(bool) onThemeChanged;

  const MainPage({
    Key? key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
    this.avatarUrl,
    this.userName,
    this.userEmail,
    this.onLogout,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      HomePage(isDarkMode: widget.isDarkMode, avatarUrl: widget.avatarUrl),
      widget.isCoach
          ? ClientManagementPage(isDarkMode: widget.isDarkMode)
          : TrainerManagementPage(isDarkMode: widget.isDarkMode, isCoach: false,),
      const ActivityPage(),
      FeedPage(isDarkMode: widget.isDarkMode),
      MenuPage(
        isDarkMode: widget.isDarkMode,
        avatarUrl: widget.avatarUrl,
        userName: widget.userName,
        userEmail: widget.userEmail,
        onLogout: widget.onLogout,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
  }

  @override
  void didUpdateWidget(MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode || oldWidget.avatarUrl != widget.avatarUrl) {
      _buildPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDarkMode
        ? const Color(0xFFCFF500)
        : const Color(0xFFA66CFF);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: accentColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search, color: accentColor),
            label: widget.isCoach ? 'Clients' : 'Trainers',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor,
                  width: 4,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: accentColor,
                  size: 28,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder, color: accentColor),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu, color: accentColor),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}

class FirstTimeSetupView extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onContinue;
  final Future<void> Function()? onLogout;

  const FirstTimeSetupView({
    Key? key,
    required this.isLoading,
    required this.onContinue,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to Repz',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is a temporary first-time setup view. Continue to enter the app.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onContinue,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : onLogout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

