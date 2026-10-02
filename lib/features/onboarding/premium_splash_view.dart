import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';

/// Premium, transportation-focused splash screen for Byahe Meter.
class PremiumSplashView extends StatelessWidget {
  final AnimationController controller;

  const PremiumSplashView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedOf(context);
    final primary = theme.colorScheme.primary;

    final logoFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    final logoScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.60, curve: _CriticallyDampedSpringCurve()),
      ),
    );

    final routeLineAnim = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.25, 0.75, curve: Curves.easeInOutCubic),
    );

    final textFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
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
            // Soft background glow fields
            Positioned(
              top: -100,
              left: -60,
              child: _GlowOrb(
                size: 260,
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -80,
              child: _GlowOrb(
                size: 300,
                color: primary.withValues(alpha: isDark ? 0.09 : 0.05),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // Logo & App Name
                    FadeTransition(
                      opacity: logoFade,
                      child: ScaleTransition(
                        scale: logoScale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(alpha: isDark ? 0.72 : 0.85),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppTheme.borderOf(context)
                                          .withValues(alpha: 0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    height: 82,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'BYAHE METER',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                fontSize: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Minimal Vector Route Line Graphic
                    SizedBox(
                      height: 40,
                      width: 180,
                      child: AnimatedBuilder(
                        animation: routeLineAnim,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _RouteLinePainter(
                              progress: routeLineAnim.value,
                              color: primary,
                              dotColor: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tagline
                    FadeTransition(
                      opacity: textFade,
                      child: Column(
                        children: [
                          Text(
                            'Know your fare. Plan your byahe.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PH DRIVER & TRAVEL COMPANION',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 4),

                    // Subtle loading dots indicator
                    FadeTransition(
                      opacity: textFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.3 + (index * 0.3)),
                            ),
                          );
                        }),
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

class _RouteLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color dotColor;

  _RouteLinePainter({
    required this.progress,
    required this.color,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(10, size.height / 2);
    path.cubicTo(
      size.width * 0.35,
      10,
      size.width * 0.65,
      size.height - 10,
      size.width - 10,
      size.height / 2,
    );

    // Draw animated route line
    final pathMetrics = path.computeMetrics().first;
    final extractPath =
        pathMetrics.extractPath(0.0, pathMetrics.length * progress);
    canvas.drawPath(extractPath, paint);

    // Draw origin dot
    if (progress > 0.05) {
      final startPaint = Paint()..color = color;
      canvas.drawCircle(Offset(10, size.height / 2), 4.0, startPaint);
    }

    // Draw destination pin dot
    if (progress > 0.90) {
      final endPaint = Paint()..color = color;
      final endWhite = Paint()..color = Colors.white;
      canvas.drawCircle(
          Offset(size.width - 10, size.height / 2), 5.5, endPaint);
      canvas.drawCircle(
          Offset(size.width - 10, size.height / 2), 2.5, endWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
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

/// Apple HIG critically damped spring simulation (damping ratio = 1.0, zero overshoot)
class _CriticallyDampedSpringCurve extends Curve {
  static final _simulation = SpringSimulation(
    const SpringDescription(mass: 1.0, stiffness: 120.0, damping: 21.9),
    0.0,
    1.0,
    0.0,
  );

  const _CriticallyDampedSpringCurve();

  @override
  double transformInternal(double t) => _simulation.x(t).clamp(0.0, 1.0);
}
