import 'package:flutter/material.dart';
import 'package:repz/views/activity_page.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_management.dart';

import 'object_detector_view.dart';

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
          : TrainerManagementPage(
            isDarkMode: widget.isDarkMode,
            isCoach: false,
          ),
      ObjectDetectorView(),
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
    if (oldWidget.isDarkMode != widget.isDarkMode ||
        oldWidget.avatarUrl != widget.avatarUrl) {
      _buildPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);

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
                border: Border.all(color: accentColor, width: 4),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    width: 2.5,
                  ),
                ),
                child: Icon(Icons.camera_alt, color: accentColor, size: 28),
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

