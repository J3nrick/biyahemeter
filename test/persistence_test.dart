import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:biyahe_meter/core/models/fare_preset.dart';
import 'package:biyahe_meter/features/fare/fare_matrix_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';

class _FakeWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}
  @override
  Future<bool> get enabled async => false;
}

/// Permission granted; first fix at [start], later fixes via [fixes].
class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator(this.start);
  final Position start;
  final fixes = StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      start;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      fixes.stream;
}

Position _fix(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 10,
      speedAccuracy: 0,
    );

void main() {
  late Box<dynamic> box;

  /// Closes and reopens the box so assertions read what reached disk.
  Future<Box<dynamic>> reopen() async {
    await box.close();
    return box = await Hive.openBox('app_state');
  }

  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync('byahe').path));
  setUp(() async => box = await Hive.openBox('app_state'));
  tearDown(() => box.deleteFromDisk());

  test('fare settings survive a restart', () async {
    final matrix = FareMatrixProvider()
      ..selectPreset(FarePresetId.tnvs)
      ..setDiscountEnabled(true);
    MeterProvider()
      ..restoreFrom(box)
      ..kmPerLiter = 15
      ..gasPricePerLiter = 70.25
      ..setBatterySaver(false)
      ..applyFareMatrix(matrix);

    final restored = MeterProvider()..restoreFrom(await reopen());
    expect(restored.kmPerLiter, 15);
    expect(restored.gasPricePerLiter, 70.25);
    expect(restored.baseFare, 50); // TNVS flagdown
    expect(restored.activePreset.id, FarePresetId.tnvs);
    expect(restored.discountEnabled, isTrue);
    expect(restored.batterySaver, isFalse);
  });

  test('a running trip is restored paused; a stopped one is not', () async {
    wakelockPlusPlatformInstance = _FakeWakelock();
    final gps = _FakeGeolocator(_fix(14.5995, 120.9842));
    GeolocatorPlatform.instance = gps;
    MeterProvider.snapshotInterval = const Duration(milliseconds: 20);

    final meter = MeterProvider()..restoreFrom(box);
    await meter.startTrip();
    gps.fixes.add(_fix(14.6005, 120.9842)); // ~111 m north
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final distance = meter.distanceKm;
    expect(distance, closeTo(0.111, 0.005));
    meter.dispose(); // app killed mid-trip: no stopTrip()

    final restored = MeterProvider()..restoreFrom(await reopen());
    expect(restored.isRunning, isFalse);
    expect(restored.canResumeTrip, isTrue);
    expect(restored.distanceKm, distance);
    expect(restored.routePoints, hasLength(2));
    expect(restored.tripStartPosition?.latitude, 14.5995);
    expect(restored.currentPosition?.latitude, 14.6005);
    expect(
      restored.tripStartedAt?.millisecondsSinceEpoch,
      meter.tripStartedAt?.millisecondsSinceEpoch,
    );
    expect(restored.totalFare, meter.totalFare);

    restored.stopTrip();
    final afterStop = MeterProvider()..restoreFrom(await reopen());
    expect(afterStop.canResumeTrip, isFalse);
    expect(afterStop.distanceKm, 0);
  });

  test('agreements are remembered for the current terms version', () async {
    final first = AgreementsProvider(box)
      ..toggleTerms(true)
      ..togglePrivacy(true);
    expect(first.allAccepted, isFalse);
    expect(AgreementsProvider(box).allAccepted, isFalse); // toggles don't persist

    first.acceptAll();
    expect(AgreementsProvider(await reopen()).allAccepted, isTrue);

    await box.put(
      'agreements_accepted_version',
      AgreementsProvider.termsVersion - 1,
    );
    expect(AgreementsProvider(box).allAccepted, isFalse);
    expect(AgreementsProvider().allAccepted, isFalse); // no store
  });
}
