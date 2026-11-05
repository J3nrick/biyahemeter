import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:biyahe_meter/core/models/trip_record.dart';
import 'package:biyahe_meter/features/meter/widgets/trip_card.dart';

void main() {
  const fare = TextStyle(fontSize: 38, color: Colors.white);

  final trip = TripRecord(
    id: 't1',
    startedAt: DateTime(2026, 11, 5, 8, 0),
    endedAt: DateTime(2026, 11, 5, 8, 23),
    distanceKm: 7.4,
    waitingMinutes: 3,
    totalFare: 186.5,
    baseFare: 45,
    distanceFare: 131.5,
    waitingFare: 10,
    discountPercent: 0,
    discountAmount: 0,
    fuelLiters: 0.6,
    fuelCost: 38,
    presetName: 'Taxi',
    discountApplied: false,
  );
  // A small L-shaped drive around Makati.
  const route = [
    LatLng(14.5547, 121.0244),
    LatLng(14.5580, 121.0260),
    LatLng(14.5610, 121.0300),
    LatLng(14.5600, 121.0360),
  ];

  test('route is fitted inside the box, keeping its shape', () {
    const size = Size(300, 120);
    final pts = RouteShapePainter.fit(route, size);
    for (final p in pts) {
      expect(p.dx, inInclusiveRange(10 - 1e-6, 290 + 1e-6));
      expect(p.dy, inInclusiveRange(10 - 1e-6, 110 + 1e-6));
    }
    // North is up: the first point (southernmost) sits lowest.
    expect(pts.first.dy, greaterThan(pts[2].dy));
    // A single point (or a parked car) doesn't divide by zero.
    final still = RouteShapePainter.fit([route.first, route.first], size);
    expect(still.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
  });

  // Set CARD_OUT=<file.png> to dump the rendered card for a look.
  testWidgets('card renders with and without a route', (tester) async {
    final key = GlobalKey();
    for (final r in [route, <LatLng>[]]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: RepaintBoundary(
                key: key,
                child: TripCard(trip: trip, route: r, fareStyle: fare),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final shape = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RouteShapePainter,
      );
      expect(shape, r.isEmpty ? findsNothing : findsOneWidget);
    }

    final out = Platform.environment['CARD_OUT'];
    if (out == null) return;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            child: RepaintBoundary(
              key: key,
              child: TripCard(trip: trip, route: route, fareStyle: fare),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
