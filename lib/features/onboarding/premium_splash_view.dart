import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// Crafted with deep luxury minimalism, elegance, and finesse:
/// - Pure high-definition BiyaheMeter emblem with zero clutter or extraneous text
/// - Multi-layered obsidian-sapphire atmospheric depth
/// - Ethereal ambient light bloom that breathes with subtle organic poise
/// - Gentle specular light sheen sweeping across the polished contours
/// - Seamless cinematic cross-dissolve departure transition at exactly 3.0s
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // Refined animation phases
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _specularSweep;
  late final Animation<double> _ambientBreathe;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Entrance: Deliberate, dignified emergence (0.0s – 1.0s)
    // Scale: 0.95 -> 1.0 using easeOutCubic (no abrupt bounce, pure poise)
    _entranceScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // Fade-in: 0.0s – 0.7s
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );

    // 2. Ambient light breathing (gentle expansion of radiant backdrop aura)
    _ambientBreathe = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.20, 0.85),
      ),
    );

    // 3. Specular Sheen Pass (0.9s – 2.2s):
    // Soft diagonal diffused glare sweeping across the logo contours
    _specularSweep = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.30, 0.76, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Departure Transition (2.6s – 3.0s):
    // Gentle forward drift as the trip embarks
    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    _anim.forward();

    // Safety fallback
    _safetyTimer = Timer(const Duration(milliseconds: 3050), () {
      if (mounted) _proceed();
    });
  }

  void _proceed() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
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
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Sophisticated, perfectly balanced logo width (not overpowering, exquisitely proportioned)
    final logoWidth = (size.width * 0.70).clamp(250.0, 350.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF03050B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF040711),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.05),
              radius: 1.25,
              colors: [
                Color(0xFF0A142D), // Atmospheric midnight sapphire
                Color(0xFF060B1A), // Deep indigo transition
                Color(0xFF03050B), // Pure obsidian outer horizon
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ethereal ambient background aura (soft, diffused, breathing)
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final breathe = _ambientBreathe.value;
                  final opacity = _entranceOpacity.value *
                      _exitOpacity.value *
                      0.32 *
                      breathe;

                  return Container(
                    width: logoWidth * 1.5,
                    height: logoWidth * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(logoWidth),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: opacity),
                          const Color(0xFF1D4ED8).withValues(alpha: opacity * 0.45),
                          Colors.transparent,
                        ],
                        radius: 0.7,
                      ),
                    ),
                  );
                },
              ),

              // The Full HD Logo with Specular Glass Sheen
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final currentScale = _entranceScale.value * _exitScale.value;
                  final currentOpacity =
                      (_entranceOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);
                  final sweep = _specularSweep.value;

                  return Opacity(
                    opacity: currentOpacity,
                    child: Transform.scale(
                      scale: currentScale,
                      child: SizedBox(
                        width: logoWidth,
                        child: ShaderMask(
                          // Luxury specular light pass across the logo
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: const Alignment(-0.8, -1.0),
                              end: const Alignment(0.8, 1.0),
                              colors: const [
                                Colors.white,
                                Colors.white,
                                Color(0xFFBAE6FD), // Luminous icy azure reflection
                                Colors.white,
                                Colors.white,
                              ],
                              stops: [
                                0.0,
                                (sweep - 0.22).clamp(0.0, 1.0),
                                sweep.clamp(0.0, 1.0),
                                (sweep + 0.22).clamp(0.0, 1.0),
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
