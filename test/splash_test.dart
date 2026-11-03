import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biyahe_meter/features/onboarding/premium_splash_view.dart';

void main() {
  // Set SPLASH_OUT=<dir> to also dump the frames as PNGs for visual review.
  testWidgets('splash plays every phase and finishes', (tester) async {
    final out = Platform.environment['SPLASH_OUT'];
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: SplashScreen(onFinish: () => finished = true),
        ),
      ),
    );
    // Real codec decode + particle sampling, then the clock starts.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2200));

    var elapsed = 0;
    // Dense 30 fps sequence when dumping (for a preview video), sparse otherwise.
    final stamps = out == null
        ? const [150, 550, 950, 1400, 1990, 2350, 2790]
        : [for (var i = 1; i * 33 < 2800; i++) i * 33];
    for (final ms in stamps) {
      await tester.pump(Duration(milliseconds: ms - elapsed));
      elapsed = ms;
      expect(tester.takeException(), isNull);
      if (out == null) continue;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$out/frame_${(ms ~/ 33).toString().padLeft(3, '0')}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(finished, isTrue);
  });

  testWidgets('a tap skips the splash', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinish: () => finished++)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(const Duration(seconds: 6));
    expect(finished, 1); // once, even though the timeline keeps running
  });
}
