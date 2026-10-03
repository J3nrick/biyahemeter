import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// Features:
/// - Pure high-definition BiyaheMeter logo with NO text around it
/// - Rich, immersive deep transit midnight blue gradient
/// - Dynamic BiyaheMeter "Engine Ignition & Meter Sweep" animation
/// - Ambient radial aura with speedometer shimmer sweep
/// - Critically damped entry spring with departure launch transition
/// - Exact 3-second duration transitioning seamlessly into AgreementsScreen
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _sweepAnimation;
  late final Animation<double> _departureScale;
  late final Animation<double> _departureOpacity;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    // 3.0 second master animation orchestrator
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Initial spring reveal (0.0s - 0.9s): scale from 0.86 to 1.0 with subtle overshoot
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.40),
      ),
    );

    // 2. Opacity fade-in (0.0s - 0.6s)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // 3. Meter speed sweep along the logo (0.8s - 2.2s)
    _sweepAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.28, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Departure acceleration (2.5s - 3.0s): gentle forward thrust as trip engages
    _departureScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _departureOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    // Listen for animation completion to transition
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    _animController.forward();

    // Safety fallback timer ensuring transition always occurs at 3.0s
    _fallbackTimer = Timer(const Duration(milliseconds: 3050), () {
      if (mounted) _proceed();
    });
  }

  void _proceed() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    if (!mounted) return;

    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AgreementsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Responsive HD logo sizing: prominent, crisp, and centered
    final logoWidth = (size.width * 0.72).clamp(240.0, 360.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF060D1F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF071126), // Midnight transit dark
                Color(0xFF0A1838), // Deep cobalt core
                Color(0xFF060D1F), // Obsidian road anchor
              ],
              stops: [0.0, 0.50, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient radiant meter glow behind logo
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final glowOpacity = (_opacityAnimation.value * 0.40) *
                      (1.0 - (_departureOpacity.value > 0 ? 0.0 : 1.0));
                  return Container(
                    width: logoWidth * 1.35,
                    height: logoWidth * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(logoWidth),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: glowOpacity),
                          const Color(0xFF2563EB).withValues(alpha: glowOpacity * 0.5),
                          Colors.transparent,
                        ],
                        radius: 0.75,
                      ),
                    ),
                  );
                },
              ),

              // The Full HD Logo with Meter Shimmer Sweep and Spring Dynamics
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final currentScale = _scaleAnimation.value * _departureScale.value;
                  final currentOpacity = (_opacityAnimation.value * _departureOpacity.value)
                      .clamp(0.0, 1.0);

                  return Opacity(
                    opacity: currentOpacity,
                    child: Transform.scale(
                      scale: currentScale,
                      child: SizedBox(
                        width: logoWidth,
                        child: ShaderMask(
                          // Dynamic meter sweep highlight
                          shaderCallback: (bounds) {
                            final sweep = _sweepAnimation.value;
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: const [
                                Colors.white,
                                Colors.white,
                                Color(0xFF93C5FD), // Electric blue glare
                                Colors.white,
                                Colors.white,
                              ],
                              stops: [
                                0.0,
                                (sweep - 0.25).clamp(0.0, 1.0),
                                sweep.clamp(0.0, 1.0),
                                (sweep + 0.25).clamp(0.0, 1.0),
                                1.0,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Image.asset(
                            'assets/images/logo_dark_hd.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              // High quality fallback to standard logo if ever needed
                              return Image.asset(
                                'assets/images/logo.png',
                                width: logoWidth,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef PremiumSplashView = SplashScreen;
