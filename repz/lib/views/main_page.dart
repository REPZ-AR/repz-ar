import 'package:flutter/material.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_management.dart';
import 'package:repz/views/workout_builder_page.dart';

import '../main.dart';
import 'object_detector_view.dart';

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;
  final String userId;
  final WorkoutGateway workoutGateway;
  final Future<void> Function()? onLogout;
  final Function(bool) onThemeChanged;

  const MainPage({
    Key? key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
    required this.userId,
    required this.workoutGateway,
    this.avatarUrl,
    this.userName,
    this.userEmail,
    this.onLogout,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isCameraMenuOpen = false;
  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;

  late Map<int, Widget> _pages;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInOut,
    );
    _buildPages();
  }

  void _buildPages() {
    _pages = {
      0: HomePage(isDarkMode: widget.isDarkMode, avatarUrl: widget.avatarUrl, userId: widget.userId, workoutGateway: widget.workoutGateway),
      1: widget.isCoach
          ? ClientManagementPage(isDarkMode: widget.isDarkMode)
          : TrainerManagementPage(
              isDarkMode: widget.isDarkMode,
              isCoach: false,
            ),
      3: FeedPage(isDarkMode: widget.isDarkMode),
      4: MenuPage(
          isDarkMode: widget.isDarkMode,
          avatarUrl: widget.avatarUrl,
          userName: widget.userName,
          userEmail: widget.userEmail,
          onLogout: widget.onLogout,
          onThemeChanged: widget.onThemeChanged,
        ),
    };
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
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    if (index == 2) {
      _toggleCameraMenu();
      return;
    }

    setState(() {
      _selectedIndex = index;
      _isCameraMenuOpen = false;
    });
    _menuController.reverse();
  }

  void _toggleCameraMenu() {
    setState(() {
      _isCameraMenuOpen = !_isCameraMenuOpen;
    });

    if (_isCameraMenuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _closeCameraMenu() {
    if (!_isCameraMenuOpen) return;

    setState(() {
      _isCameraMenuOpen = false;
    });
    _menuController.reverse();
  }

  Future<void> _openObjectDetection() async {
    _closeCameraMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ObjectDetectorView()),
    );
  }

  Future<void> _openWorkoutBuilder() async {
    _closeCameraMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutBuilderPage()),
    );
  }

  void _showComingSoon(String message) {
    _closeCameraMenu();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final labelColor = widget.isDarkMode ? Colors.white70 : Colors.black87;

    return Stack(
      children: [
        Scaffold(
          body: _pages[_selectedIndex]!,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _handleNavTap,
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
                icon: _buildCameraNavButton(accentColor),
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
        ),
        if (_isCameraMenuOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeCameraMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black45),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  _buildRadialAction(
                    animation: _menuAnimation,
                    offset: const Offset(-112, -118),
                    icon: Icons.edit_note_rounded,
                    label: 'Create Workout Plan',
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap: _openWorkoutBuilder,
                  ),
                  _buildRadialAction(
                    animation: _menuAnimation,
                    offset: const Offset(0, -156),
                    icon: Icons.center_focus_strong,
                    label: 'Object Detection View',
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap: _openObjectDetection,
                  ),
                  _buildRadialAction(
                    animation: _menuAnimation,
                    offset: const Offset(112, -118),
                    icon: Icons.play_arrow_rounded,
                    label: "Start Today's Plan",
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap: () =>
                        _showComingSoon("Start today's plan coming soon"),
                  ),
                  GestureDetector(
                    onTap: _toggleCameraMenu,
                    child: _buildCameraNavButton(accentColor, isOpen: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCameraNavButton(Color accentColor, {bool isOpen = false}) {
    return AnimatedScale(
      scale: isOpen ? 1.08 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor, width: 4),
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.28),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              width: 2.5,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Icon(
            isOpen ? Icons.close_rounded : Icons.camera_alt,
            color: accentColor,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildRadialAction({
    required Animation<double> animation,
    required Offset offset,
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dx = offset.dx * animation.value;
        final dy = offset.dy * animation.value;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 132,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
