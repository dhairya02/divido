import 'package:flutter/material.dart';

import '../theme/brand.dart';
import '../widgets/brand_logo.dart';

/// Branded splash shown while the app boots and for a short minimum window
/// after, so the transition into the welcome / home screen feels intentional
/// instead of a flicker. Pairs with the native launch screens (Android
/// `launch_background.xml`, iOS `LaunchScreen.storyboard`) which use the
/// same brand background — together they give a seamless cold-start.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.showSpinner = true,
    this.tagline = 'Split bills the easy way.',
  });

  /// When `true`, shows a small white progress indicator under the logo.
  /// Use `false` for the "post-bootstrap minimum display" phase, where the
  /// app is ready and we're just letting the splash breathe.
  final bool showSpinner;

  final String tagline;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(height: 64),
                const SizedBox(height: 16),
                Text(
                  widget.tagline,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.showSpinner ? 1 : 0,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
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
