import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';

/// Animated brand splash shown after the native splash is removed.
class PremiumSplashView extends StatelessWidget {
  final AnimationController controller;

  const PremiumSplashView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedOf(context);
    final primary = theme.colorScheme.primary;

    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.05, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    final logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    final bar = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOutCubic),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft atmospheric fields — restrained, no rainbow.
            Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(
                size: 280,
                color: primary.withValues(alpha: isDark ? 0.14 : 0.10),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -100,
              child: _GlowOrb(
                size: 320,
                color: primary.withValues(alpha: isDark ? 0.10 : 0.07),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: rise,
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: logoScale,
                              child: Hero(
                                tag: 'biyahemeter-logo',
                                child: Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppTheme.borderOf(context),
                                    ),
                                    boxShadow: AppTheme.softShadow(context),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    height: 88,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'BiyaheMeter',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PH',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Premium taxi meter for Filipino drivers',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: fade,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              width: 120,
                              height: 3,
                              child: AnimatedBuilder(
                                animation: bar,
                                builder: (context, _) {
                                  return LinearProgressIndicator(
                                    value: 0.15 + (bar.value * 0.85),
                                    backgroundColor: AppTheme.borderOf(context),
                                    color: primary,
                                    minHeight: 3,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Preparing your meter…',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: muted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
