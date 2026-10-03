import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// Features:
/// - Rich, immersive deep blue background gradient
/// - Seamless floating logo mark (no cards or container boxes)
/// - Bold modern "BiyaheMeter" wordmark in white
/// - Exact single tagline: "Know your fare. Plan your byahe."
/// - Minimalist thin white CircularProgressIndicator
/// - 3-second timer transitioning to AgreementsScreen
class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final AnimationController? controller; // Optional backward compatibility

  const SplashScreen({
    super.key,
    this.onFinish,
    this.controller,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _proceedToAgreements);
  }

  void _proceedToAgreements() {
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AgreementsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF071126),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF071126), // Deep transit night blue
                Color(0xFF0A1838), // Rich transit navy
                Color(0xFF060D1F), // Dark bottom anchor
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 6),

                // Floating Logo Mark (no card or container box around it)
                Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.navigation_rounded,
                      size: 80,
                      color: Colors.white,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Wordmark: Bold, modern, white text
                const Text(
                  'BiyaheMeter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline exactly once: "Know your fare. Plan your byahe."
                const Text(
                  'Know your fare. Plan your byahe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8), // Crisp subtle slate gray
                    fontSize: 14,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 7),

                // Minimalist CircularProgressIndicator near bottom (white, thin stroke)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'v1.0',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef PremiumSplashView = SplashScreen;
