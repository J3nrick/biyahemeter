import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:biyahe_meter/core/models/trip_record.dart';

/// The branded, shareable picture of a finished trip: the route's shape (no
/// map tiles, no coordinates), the fare, and the trip stats.
class TripCard extends StatelessWidget {
  final TripRecord trip;
  final List<LatLng> route;

  /// The meter's fare font (AppTheme.fareStyle), passed in like RollingFare's.
  final TextStyle fareStyle;

  const TripCard({
    super.key,
    required this.trip,
    required this.route,
    required this.fareStyle,
  });

  static const _cyan = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final mins = trip.duration.inMinutes;
    const label = TextStyle(color: Colors.white60, fontSize: 12);
    const stat = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    Widget statCol(String name, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: label),
        const SizedBox(height: 2),
        Text(value, style: stat),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Same navy as the splash, so the card reads as the brand.
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.6),
          radius: 1.4,
          colors: [Color(0xFF0C1B3E), Color(0xFF060D20), Color(0xFF020409)],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_dark_hd.png',
                height: 24,
                semanticLabel: 'Biyahe Meter',
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d · h:mm a').format(trip.endedAt),
                style: label,
              ),
            ],
          ),
          if (route.length >= 2) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(painter: RouteShapePainter(route)),
            ),
          ],
          const SizedBox(height: 14),
          Text(money.format(trip.totalFare), style: fareStyle),
          const SizedBox(height: 4),
          Text(
            trip.presetName,
            style: const TextStyle(color: _cyan, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: statCol(
                  'Distance',
                  '${trip.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: statCol(
                  'Time',
                  mins > 0 ? '$mins min' : '${trip.duration.inSeconds}s',
                ),
              ),
              Expanded(
                child: statCol(
                  'Avg speed',
                  '${trip.averageSpeedKmh.toStringAsFixed(0)} km/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws the route fitted into the box with its real proportions: a glow, a
/// line that brightens toward the end, and start/end dots.
@visibleForTesting
class RouteShapePainter extends CustomPainter {
  final List<LatLng> route;

  RouteShapePainter(this.route);

  /// Route points mapped into [size], keeping aspect ratio and centred.
  @visibleForTesting
  static List<Offset> fit(List<LatLng> route, Size size, {double pad = 10}) {
    // Longitude degrees shrink with latitude; scale so the shape isn't stretched.
    final k = math.cos(route.first.latitude * math.pi / 180);
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final p in route) {
      final x = p.longitude * k, y = -p.latitude;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    final w = math.max(maxX - minX, 1e-9), h = math.max(maxY - minY, 1e-9);
    final s = math.min((size.width - 2 * pad) / w, (size.height - 2 * pad) / h);
    final ox = (size.width - w * s) / 2, oy = (size.height - h * s) / 2;
    return [
      for (final p in route)
        Offset(
          ox + (p.longitude * k - minX) * s,
          oy + (-p.latitude - minY) * s,
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = fit(route, size);
    final path = Path()..addPolygon(pts, false);
    final shader = LinearGradient(
      colors: const [Color(0xFF2563EB), TripCard._cyan],
    ).createShader(Rect.fromPoints(pts.first, pts.last).inflate(1));

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = TripCard._cyan.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = shader,
    );
    canvas.drawCircle(pts.first, 5, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 7, Paint()..color = TripCard._cyan);
    canvas.drawCircle(pts.last, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(RouteShapePainter old) => old.route != route;
}
