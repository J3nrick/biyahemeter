import 'package:flutter/material.dart';

/// Geometry of the wordmark inside assets/images/logo.png (500×500, transparent).
class BrandLogo {
  BrandLogo._();

  static const String asset = 'assets/images/logo.png';
  static const double canvas = 500;
  static const Rect content = Rect.fromLTRB(82, 220, 401, 323);

  /// Must match `#splash img` width in web/index.html so the HTML splash and
  /// the first Flutter frame line up pixel for pixel.
  static double splashCanvasWidth(Size screen) =>
      (screen.shortestSide * 0.72).clamp(260.0, 400.0);

  /// Where the visible wordmark sits when the canvas is centered on [screen].
  static Rect splashContentRect(Size screen) {
    final c = splashCanvasWidth(screen);
    final origin = Offset((screen.width - c) / 2, (screen.height - c) / 2);
    final s = c / canvas;
    return Rect.fromLTRB(
      origin.dx + content.left * s,
      origin.dy + content.top * s,
      origin.dx + content.right * s,
      origin.dy + content.bottom * s,
    );
  }
}

/// The wordmark cropped to its visible bounds (the PNG is mostly padding).
class BrandWordmark extends StatelessWidget {
  final double height;

  const BrandWordmark({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    const c = BrandLogo.content;
    const free = BrandLogo.canvas;
    final canvas = height * free / c.height;
    return Semantics(
      label: 'Byahe Meter',
      image: true,
      child: ClipRect(
        child: Align(
          alignment: Alignment(
            2 * c.left / (free - c.width) - 1,
            2 * c.top / (free - c.height) - 1,
          ),
          widthFactor: c.width / free,
          heightFactor: c.height / free,
          child: Image.asset(
            BrandLogo.asset,
            width: canvas,
            height: canvas,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// Faint street grid aligned to [anchor], fading out from [focus].
/// Shared by the splash and the agreements header so they read as one brand.
class StreetGridPainter extends CustomPainter {
  final Offset anchor;
  final double spacing;
  final Offset focus;
  final double radius;
  final Color color;
  final double opacity;

  const StreetGridPainter({
    required this.anchor,
    required this.spacing,
    required this.focus,
    required this.radius,
    required this.color,
    this.opacity = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: color.a * opacity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: focus, radius: radius));

    for (var x = anchor.dx % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = anchor.dy % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant StreetGridPainter old) =>
      old.anchor != anchor ||
      old.spacing != spacing ||
      old.focus != focus ||
      old.radius != radius ||
      old.color != color ||
      old.opacity != opacity;
}
