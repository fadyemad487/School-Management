import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

/// Scaffold / AppBar fill in light mode — transparent so [AppBackground] shows through.
Color appScreenBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF12121E)
      : Colors.transparent;
}

/// Softness of the pattern image over the white base (0 = hidden, 1 = full).
const double _kBackgroundImageOpacity = 0.26;

/// Extra white veil on top of the image so it stays subtle behind UI.
const double _kBackgroundVeilOpacity = 0.42;

/// Full-screen decorative background used across the WeCircle app.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Solid white base — keeps screens clean and readable
          const ColoredBox(color: Colors.white),
          // Pattern sits gently on top of white, not at full strength
          Opacity(
            opacity: _kBackgroundImageOpacity,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.appBackground),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Soft veil blends the pattern into the white base
          ColoredBox(
            color: Colors.white.withValues(alpha: _kBackgroundVeilOpacity),
          ),
        ],
      ),
    );
  }
}

/// Wraps [child] with the global app background image.
class AppBackgroundScope extends StatelessWidget {
  final Widget child;

  const AppBackgroundScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        child,
      ],
    );
  }
}
