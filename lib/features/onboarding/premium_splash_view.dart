import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';

/// Ultra-minimal premium splash.
///
/// Design philosophy: total restraint. No orbs, no particles, no pulsing
/// circles. Just the brand mark, a wordmark, and a whisper-thin linear
/// progress trace. Every element earns its pixel.
class PremiumSplashView extends StatefulWidget {
  final AnimationController controller;

  const PremiumSplashView({super.key, required this.controller});

  @override
  State<PremiumSplashView> createState() => _PremiumSplashViewState();
}

class _PremiumSplashViewState extends State<PremiumSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    // Thin progress trace — deliberate, unhurried fill.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // Begin progress fill after logo settles (400ms delay).
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);
    final onSurface = theme.colorScheme.onSurface;

    // ── Entry choreography (driven by parent controller) ──

    // 1. Logo: fade + critically-damped spring scale (0.94 → 1.0)
    final logoOpacity = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    final logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.50, curve: _CriticalSpring()),
      ),
    );

    // 2. Wordmark: fade + micro-slide (8pt up)
    final wordOpacity = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.18, 0.50, curve: Curves.easeOut),
    );
    final wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOutCubic),
    ));

    // 3. Tagline: delayed, gentle fade only
    final taglineOpacity = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
    );

    // 4. Bottom furniture (progress + version): late reveal
    final bottomOpacity = CurvedAnimation(
      parent: widget.controller,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
      ),
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                // ── Top negative space ──
                const Spacer(flex: 7),

                // ── Brand mark ──
                FadeTransition(
                  opacity: logoOpacity,
                  child: ScaleTransition(
                    scale: logoScale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface
                            .withValues(alpha: isDark ? 0.60 : 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19.5),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Wordmark ──
                SlideTransition(
                  position: wordSlide,
                  child: FadeTransition(
                    opacity: wordOpacity,
                    child: Text(
                      'BiyaheMeter',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Tagline — one quiet line ──
                FadeTransition(
                  opacity: taglineOpacity,
                  child: Text(
                    'Know your fare. Plan your byahe.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                // ── Bottom negative space ──
                const Spacer(flex: 8),

                // ── Linear progress trace ──
                FadeTransition(
                  opacity: bottomOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: SizedBox(
                            height: 1.5,
                            child: Stack(
                              children: [
                                // Track
                                Container(
                                  color: onSurface.withValues(
                                      alpha: isDark ? 0.06 : 0.04),
                                ),
                                // Fill
                                FractionallySizedBox(
                                  widthFactor: _progressController.value,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(1),
                                      color: primary.withValues(alpha: 0.50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Version trace ──
                FadeTransition(
                  opacity: bottomOpacity,
                  child: Text(
                    'v1.0',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muted.withValues(alpha: 0.40),
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Critically damped spring (damping ratio ≈ 1.0). Zero overshoot, zero
/// bounce — the object arrives and stops. This is how physical objects
/// with intentional mass behave.
class _CriticalSpring extends Curve {
  static final _sim = SpringSimulation(
    const SpringDescription(mass: 1.0, stiffness: 120.0, damping: 21.9),
    0.0,
    1.0,
    0.0,
  );

  const _CriticalSpring();

  @override
  double transformInternal(double t) => _sim.x(t).clamp(0.0, 1.0);
}
