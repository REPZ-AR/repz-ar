import 'package:flutter/material.dart';
import 'package:repz/config/app_colors.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/ui_components/buttons/pill_button.dart';
import 'package:repz/views/main_page.dart';

class ModeSelectorPage extends StatelessWidget {
  const ModeSelectorPage({
    super.key,
    required this.mode,
    required this.onSelectMode,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.userName,
    this.avatarUrl,
    this.userEmail,
    this.isLoading = false,
    this.onLogout,
  });

  static const String _bgAsset = 'assets/images/mode_picker_bg.png';

  final ProfileMode? mode;
  final Future<void> Function(ProfileMode mode) onSelectMode;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String? userName;
  final String? avatarUrl;
  final String? userEmail;
  final bool isLoading;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    if (mode != null) {
      return MainPage(
        isDarkMode: isDarkMode,
        isCoach: mode == ProfileMode.trainer,
        avatarUrl: avatarUrl,
        userName: userName,
        userEmail: userEmail,
        onLogout: onLogout,
        onThemeChanged: onThemeChanged,
      );
    }

    final displayName = _firstName(userName) ?? 'there';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return const ColoredBox(color: AppColors.surfaceSoft);
              },
            ),
          ),
          const Positioned.fill(
            child: ColoredBox(color: AppColors.overlayLight),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: isLoading ? null : () => onLogout?.call(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hi, $displayName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            height: 1,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.white,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                        child:
                            avatarUrl == null
                                ? const Icon(
                                  Icons.person,
                                  color: AppColors.black,
                                )
                                : null,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'What is\nYour Role?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 72,
                        height: 0.9,
                        letterSpacing: -1.8,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  PillButton(
                    text: 'I am a Trainee',
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                    isLoading: isLoading,
                    showLoadingIndicator: false,
                    onPressed: () => onSelectMode(ProfileMode.user),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    text: 'I am an Instructor',
                    backgroundColor: AppColors.accent,
                    textColor: AppColors.black,
                    isLoading: isLoading,
                    showLoadingIndicator: false,
                    onPressed: () => onSelectMode(ProfileMode.trainer),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _firstName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    return name.trim().split(' ').first;
  }
}
