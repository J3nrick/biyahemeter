import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/onboarding/brand_mark.dart';

/// "Journey Mark" splash: a route follows the street grid, turns at its
/// intersections and lands on a destination pin above the wordmark.
///
/// The wordmark is static from frame one and sits exactly where the
/// HTML/native launch image sits, so the hand-off never jumps.
/// With reduced motion the controller is simply set to 1 (final composition).
class PremiumSplashView extends StatelessWidget {
  final AnimationController controller;

  const PremiumSplashView({super.key, required this.controller});

  static const String tagline = 'Know your fare. Plan your byahe.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Phases overlap; fractions of the 1250 ms controller.
    final grid = controller.drive(
      CurveTween(curve: const Interval(0.0, 0.32, curve: Curves.easeOut)),
    );
    final route = controller.drive(
      CurveTween(
        curve: const Interval(0.10, 0.66, curve: Curves.easeInOutCubic),
      ),
    );
    final pin = controller.drive(
      CurveTween(
        curve: const Interval(0.60, 0.82, curve: Easing.emphasizedDecelerate),
      ),
    );
    final halo = controller.drive(
      CurveTween(curve: const Interval(0.64, 1.0, curve: Curves.easeOutCubic)),
    );
    final taglineIn = controller.drive(
      CurveTween(
        curve: const Interval(0.68, 1.0, curve: Easing.emphasizedDecelerate),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Semantics(
        container: true,
        label: 'Byahe Meter. $tagline',
        child: ExcludeSemantics(
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screen = constraints.biggest;
                final canvasWidth = BrandLogo.splashCanvasWidth(screen);
                final word = BrandLogo.splashContentRect(screen);
                final geo = _JourneyGeometry.forWordmark(word);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: grid,
                          builder: (context, _) => CustomPaint(
                            painter: StreetGridPainter(
                              anchor: geo.destination,
                              spacing: geo.grid,
                              focus: geo.gridFocus,
                              radius: geo.grid * 5.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: isDark ? 0.10 : 0.07,
                              ),
                              opacity: grid.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) => CustomPaint(
                            painter: _JourneyPainter(
                              geo: geo,
                              route: route.value,
                              pin: pin.value,
                              halo: halo.value,
                              color: theme.colorScheme.primary,
                              casing: theme.scaffoldBackgroundColor,
                              surface: theme.colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Same size/position formula as the HTML launch image.
                    Center(
                      child: Image.asset(
                        BrandLogo.asset,
                        width: canvasWidth,
                        height: canvasWidth,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    Positioned(
                      top: word.bottom + geo.grid * 0.7,
                      left: word.center.dx - 170,
                      width: 340,
                      child: FadeTransition(
                        opacity: taglineIn,
                        child: AnimatedBuilder(
                          animation: taglineIn,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, 8 * (1 - taglineIn.value)),
                            child: child,
                          ),
                          child: Text(
                            tagline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.mutedOf(context),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Route laid out on a grid whose spacing scales with the wordmark, so the
/// composition holds on small phones, tablets and landscape.
class _JourneyGeometry {
  final double grid;
  final Offset destination;
  final Offset gridFocus;
  final Path path;
  final double length;
  final List<double> waypointOffsets;
  final List<Offset> waypoints;

  _JourneyGeometry._({
    required this.grid,
    required this.destination,
    required this.gridFocus,
    required this.path,
    required this.length,
    required this.waypointOffsets,
    required this.waypoints,
  });

  factory _JourneyGeometry.forWordmark(Rect word) {
    final g = word.width * 0.2;
    // Pin sits above the "B", clear of the "METER" label.
    final d = Offset(word.left + word.width * 0.07, word.top - g * 0.35);
    Offset at(double col, double row) => d + Offset(col * g, row * g);

    final points = [
      Offset(-g, at(0, -4).dy), // enters from the screen edge
      at(-1, -4),
      at(-1, -2),
      at(0, -2),
      d,
    ];
    final path = _roundedPolyline(points, g * 0.42);
    final length = path.computeMetrics().first.length;

    final w1 = at(-2, -4);
    final w2 = at(0, -1);
    return _JourneyGeometry._(
      grid: g,
      destination: d,
      gridFocus: at(-1, -2.5),
      path: path,
      length: length,
      // w1 is on the first straight; w2 is one cell before the end.
      waypointOffsets: [w1.dx - points.first.dx, length - g],
      waypoints: [w1, w2],
    );
  }

  /// Polyline with exact quarter-circle corners (conic weight √2/2).
  static Path _roundedPolyline(List<Offset> pts, double r) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final inSeg = pts[i] - pts[i - 1];
      final outSeg = pts[i + 1] - pts[i];
      // Degenerate segments (very narrow windows) would divide by zero.
      if (inSeg.distance < 1e-3 || outSeg.distance < 1e-3) {
        path.lineTo(pts[i].dx, pts[i].dy);
        continue;
      }
      final rr = [r, inSeg.distance / 2, outSeg.distance / 2].reduce(math.min);
      final a = pts[i] - inSeg / inSeg.distance * rr;
      final b = pts[i] + outSeg / outSeg.distance * rr;
      path
        ..lineTo(a.dx, a.dy)
        ..conicTo(pts[i].dx, pts[i].dy, b.dx, b.dy, 0.70710678);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }
}

class _JourneyPainter extends CustomPainter {
  final _JourneyGeometry geo;
  final double route;
  final double pin;
  final double halo;
  final Color color;
  final Color casing;
  final Color surface;

  _JourneyPainter({
    required this.geo,
    required this.route,
    required this.pin,
    required this.halo,
    required this.color,
    required this.casing,
    required this.surface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = geo.length * route;
    final metric = geo.path.computeMetrics().first;

    if (drawn > 0) {
      final segment = metric.extractPath(0, drawn);
      // Casing separates the route from the grid lines, like a map road.
      canvas.drawPath(
        segment,
        Paint()
          ..color = casing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        segment,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Waypoints appear as the route passes them.
    for (var i = 0; i < geo.waypoints.length; i++) {
      if (drawn < geo.waypointOffsets[i]) continue;
      final c = geo.waypoints[i];
      canvas.drawCircle(c, 5.5, Paint()..color = surface);
      canvas.drawCircle(
        c,
        5.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Leading dot while the route is still travelling.
    if (route > 0 && route < 1 && pin == 0) {
      final tip = metric.getTangentForOffset(drawn)?.position;
      if (tip != null) {
        canvas.drawCircle(tip, 6, Paint()..color = surface);
        canvas.drawCircle(tip, 4, Paint()..color = color);
      }
    }

    if (pin > 0) {
      final d = geo.destination;
      // One-shot arrival ring (never loops).
      if (halo > 0 && halo < 1) {
        canvas.drawCircle(
          d,
          11 + 16 * halo,
          Paint()
            ..color = color.withValues(alpha: 0.35 * (1 - halo))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      final s = 0.6 + 0.4 * pin;
      canvas.save();
      canvas.translate(d.dx, d.dy);
      canvas.scale(s);
      final alpha = pin.clamp(0.0, 1.0);
      canvas.drawCircle(
        const Offset(0, 2),
        12,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.16 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset.zero,
        12,
        Paint()..color = surface.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset.zero,
        9,
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset.zero,
        3.5,
        Paint()..color = surface.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter old) =>
      old.route != route ||
      old.pin != pin ||
      old.halo != halo ||
      old.geo != geo ||
      old.color != color ||
      old.casing != casing ||
      old.surface != surface;
}
