import 'package:flutter/material.dart';
import 'package:repz/views/activity_page.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_management.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bpyitmmycmcngfdvkrkz.supabase.co',
    anonKey: 'sb_publishable_Kcz70ZjLMPHs7JjwdaLMcQ_miQTqnWo',
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
      home: MainPage(
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

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;
  final Function(bool) onThemeChanged;

  const MainPage({
    Key? key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
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
      HomePage(isDarkMode: widget.isDarkMode),
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
    if (oldWidget.isDarkMode != widget.isDarkMode) {
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
            // Dynamic label based on user type
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
