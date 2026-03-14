import 'package:flutter/material.dart';
import 'package:repz/config/app_config.dart';
import 'package:repz/views/activity_page.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_management.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class AuthGate extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginPage();
        }

        final avatarUrl = session.user.userMetadata?['avatar_url'] as String?;
        return MainPage(
          isDarkMode: isDarkMode,
          isCoach: isCoach,
          avatarUrl: avatarUrl,
          onThemeChanged: onThemeChanged,
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.supabaseRedirectUrl,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Repz',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Sign in with Google to continue'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(_loading ? 'Signing in...' : 'Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;
  final String? avatarUrl;
  final Function(bool) onThemeChanged;

  const MainPage({
    Key? key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
    this.avatarUrl,
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
