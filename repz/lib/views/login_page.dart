import 'package:flutter/material.dart';

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
                return const ColoredBox(color: Color(0xFFEFF2F5));
              },
            ),
          ),

          // Frosted/washed overlay like the mockup
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x9AFFFFFF),
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
                  _GoogleContinueButton(onPressed: onContinue),

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

class _GoogleContinueButton extends StatelessWidget {
  const _GoogleContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Simple Google "G" mark (vector-like using text).
                // If you later add an actual Google icon asset, swap this widget.
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Continue with Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDAFF00),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

