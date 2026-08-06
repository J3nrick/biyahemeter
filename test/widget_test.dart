import 'package:flutter_test/flutter_test.dart';
import 'package:biyahe_meter/core/models/fare_preset.dart';
import 'package:biyahe_meter/core/utils/trip_calculator.dart';

void main() {
  group('TripCalculator', () {
    test('base fare is 45.0', () {
      expect(TripCalculator.baseFare, 45.0);
    });

    test('calculates fuel-based fare correctly', () {
      // 10 km, 10 km/L, ₱65/L → fuel cost = 1L * 65 = 65
      final fare = TripCalculator.calculateFare(
        distanceKm: 10,
        kmPerLiter: 10,
        gasPricePerLiter: 65,
      );
      expect(fare, 45.0 + 65.0);
    });

    test('calculates waiting surcharge', () {
      expect(TripCalculator.calculateWaitingSurcharge(5), 10.0);
    });

    test('total fare includes fuel + waiting', () {
      final total = TripCalculator.calculateTotalFare(
        distanceKm: 10,
        kmPerLiter: 10,
        gasPricePerLiter: 65,
        waitingMinutes: 5,
      );
      expect(total, 45.0 + 65.0 + 10.0);
    });

    test('LTFRB regular taxi matrix with 20% discount', () {
      final breakdown = TripCalculator.calculateBreakdown(
        preset: FarePreset.byId(FarePresetId.regularTaxi),
        distanceKm: 10,
        waitingMinutes: 5,
        kmPerLiter: 12,
        gasPricePerLiter: 62.5,
        applyDiscount: true,
        discountPercent: 20,
      );
      // 45 + (10*13.50) + (5*2) = 45 + 135 + 10 = 190; 20% off => 152
      expect(breakdown.subtotal, 190.0);
      expect(breakdown.discountAmount, 38.0);
      expect(breakdown.total, 152.0);
    });
  });
}
