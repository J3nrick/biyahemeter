import 'package:flutter_test/flutter_test.dart';
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
  });
}
