class TripCalculator {
  static const double baseFare = 45.0;
  static const double waitingSurchargePerMinute = 2.0;
  static const double waitingSpeedThreshold = 5.0;

  /// Calculates the fuel-based trip cost.
  /// [distanceKm] - total distance traveled in kilometers.
  /// [kmPerLiter] - vehicle fuel efficiency.
  /// [gasPricePerLiter] - current gas price per liter in PHP.
  /// [baseFare] - user-configurable base fare (defaults to [baseFare]).
  static double calculateFare({
    required double distanceKm,
    required double kmPerLiter,
    required double gasPricePerLiter,
    double? baseFare,
  }) {
    final base = baseFare ?? TripCalculator.baseFare;
    if (kmPerLiter <= 0 || gasPricePerLiter <= 0) return base;
    final fuelCost = (distanceKm / kmPerLiter) * gasPricePerLiter;
    return base + fuelCost;
  }

  /// Calculates the waiting-time surcharge (trapik buffer).
  /// [waitingMinutes] - accumulated minutes where speed was below threshold.
  static double calculateWaitingSurcharge(double waitingMinutes) {
    if (waitingMinutes <= 0) return 0;
    return waitingMinutes * waitingSurchargePerMinute;
  }

  /// Returns the full fare including base + fuel + waiting.
  static double calculateTotalFare({
    required double distanceKm,
    required double kmPerLiter,
    required double gasPricePerLiter,
    required double waitingMinutes,
    double? baseFare,
  }) {
    return calculateFare(
          distanceKm: distanceKm,
          kmPerLiter: kmPerLiter,
          gasPricePerLiter: gasPricePerLiter,
          baseFare: baseFare,
        ) +
        calculateWaitingSurcharge(waitingMinutes);
  }
}
