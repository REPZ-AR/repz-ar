import 'package:flutter/material.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/views/client_management.dart';
import 'package:repz/views/feed_page.dart';
import 'package:repz/views/home_page.dart';
import 'package:repz/views/menu_page.dart';
import 'package:repz/views/trainer_home_page.dart';
import 'package:repz/views/trainer_plan_library_page.dart';
import 'package:repz/views/trainer_management.dart';
import 'package:repz/views/workout_builder_page.dart';
import 'package:repz/views/workout_plan_helpers.dart';

import '../main.dart';
import '../repositories/workout_plan_repository.dart';
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
    super.key,
    required this.isDarkMode,
    required this.isCoach,
    required this.onThemeChanged,
    required this.userId,
    required this.workoutGateway,
    this.avatarUrl,
    this.userName,
    this.userEmail,
    this.onLogout,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  final WorkoutPlanRepository _workoutPlanRepository = WorkoutPlanRepository();
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
      0: widget.isCoach
          ? TrainerHomePage(
              isDarkMode: widget.isDarkMode,
              avatarUrl: widget.avatarUrl,
            )
          : HomePage(
              isDarkMode: widget.isDarkMode,
              avatarUrl: widget.avatarUrl,
              userId: widget.userId,
              workoutGateway: widget.workoutGateway,
            ),
      1: widget.isCoach
          ? ClientManagementPage(isDarkMode: widget.isDarkMode)
          : TrainerManagementPage(isDarkMode: widget.isDarkMode),
      3: FeedPage(isDarkMode: widget.isDarkMode),
      4: MenuPage(
          isDarkMode: widget.isDarkMode,
          isCoach: widget.isCoach,
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
        oldWidget.isCoach != widget.isCoach ||
        oldWidget.avatarUrl != widget.avatarUrl ||
        oldWidget.userId != widget.userId ||
        oldWidget.workoutGateway != widget.workoutGateway) {
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
      MaterialPageRoute(
        builder:
            (context) => WorkoutBuilderPage(
              planScope:
                  widget.isCoach
                      ? WorkoutPlanScope.trainerTemplate
                      : WorkoutPlanScope.personal,
            ),
      ),
    );
  }

  Future<void> _openTrainerPlanLibrary() async {
    _closeCameraMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TrainerPlanLibraryPage(isDarkMode: widget.isDarkMode),
      ),
    );
  }

  Future<void> _startTodaysPlan() async {
    if (widget.isCoach) {
      return;
    }
    _closeCameraMenu();

    try {
      final todaysPlan = await _workoutPlanRepository.fetchScheduledPlanForDay(
        DateTime.now().weekday,
      );

      if (!mounted) return;

      if (todaysPlan == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'No plan is scheduled for today yet. Set one from Weekly Schedule or follow a pre-built plan on Home.',
              ),
            ),
          );
        return;
      }

      await WorkoutPlanHelpers.startPlan(context, todaysPlan);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not start today\'s scheduled plan.'),
          ),
        );
    }
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
                label: widget.isCoach ? 'Assign' : '',
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
                    icon: widget.isCoach
                        ? Icons.edit_note_rounded
                        : Icons.edit_note_rounded,
                    label: widget.isCoach
                        ? 'Create Client Plan'
                        : 'Create Workout Plan',
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap: _openWorkoutBuilder,
                  ),
                  _buildRadialAction(
                    animation: _menuAnimation,
                    offset: const Offset(0, -156),
                    icon: widget.isCoach
                        ? Icons.playlist_add_check_rounded
                        : Icons.center_focus_strong,
                    label: widget.isCoach
                        ? 'Assign Existing Plan'
                        : 'Equipment Detection View',
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap:
                        widget.isCoach
                            ? _openTrainerPlanLibrary
                            : _openObjectDetection,
                  ),
                  _buildRadialAction(
                    animation: _menuAnimation,
                    offset: const Offset(112, -118),
                    icon: widget.isCoach
                        ? Icons.folder_copy_outlined
                        : Icons.play_arrow_rounded,
                    label: widget.isCoach
                        ? 'View Client Plans'
                        : "Start Today's Plan",
                    accentColor: accentColor,
                    labelColor: labelColor,
                    onTap:
                        widget.isCoach
                            ? _openTrainerPlanLibrary
                            : _startTodaysPlan,
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
                    color: accentColor.withValues(alpha: 0.28),
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
                      color: Colors.black.withValues(alpha: 0.16),
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
                  color: Theme.of(context).cardColor.withValues(alpha: 0.96),
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
