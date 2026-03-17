import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../ui_components/buttons/wide_proceed_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const String _bgAsset = 'assets/images/login_bg.png';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (image if present, else a light fallback)
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
            child: ColoredBox(
              color: AppColors.overlayLight,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(flex: 12),

                  // Repz wordmark
                  Text(
                    'Repz',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 70,
                      height: 60 / 70,
                      letterSpacing: -4,
                      color: Colors.black,
                    ),
                  ),

                  const Spacer(flex: 22),

                  // Tagline
                  Text(
                    'Your best self is awaiting!',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                      height: 1.0,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),

                  const Spacer(flex: 32),

                  // Google CTA button (pill)
                  WideProceedButton(
                    onPressed: onContinue,
                    text: 'Continue with Google',
                    leftWidget: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/google_icon.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: media.padding.bottom > 0 ? 12 : 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
