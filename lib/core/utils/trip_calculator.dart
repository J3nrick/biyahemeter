import 'package:biyahe_meter/core/models/fare_preset.dart';

class FareBreakdown {
  final double flagdown;
  final double distanceFare;
  final double waitingFare;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double total;
  final bool isFuelBased;

  const FareBreakdown({
    required this.flagdown,
    required this.distanceFare,
    required this.waitingFare,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.total,
    required this.isFuelBased,
  });
}

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

  /// LTFRB / matrix-style or fuel-based breakdown with optional discount.
  static FareBreakdown calculateBreakdown({
    required FarePreset preset,
    required double distanceKm,
    required double waitingMinutes,
    required double kmPerLiter,
    required double gasPricePerLiter,
    double? customFlagdown,
    bool applyDiscount = false,
    double discountPercent = 20.0,
  }) {
    final flagdown = customFlagdown ?? preset.flagdown;
    late final double distanceFare;
    late final double waitingFare;

    if (preset.isFuelBased) {
      final fuelComponent = (kmPerLiter > 0 && gasPricePerLiter > 0)
          ? (distanceKm / kmPerLiter) * gasPricePerLiter
          : 0.0;
      distanceFare = fuelComponent;
      waitingFare = waitingMinutes * waitingSurchargePerMinute;
    } else {
      distanceFare = distanceKm * preset.ratePerKm;
      waitingFare = waitingMinutes * preset.waitingPerMinute;
    }

    final subtotal = flagdown + distanceFare + waitingFare;
    final discount = applyDiscount
        ? subtotal * (discountPercent.clamp(0, 100) / 100.0)
        : 0.0;
    final total = (subtotal - discount).clamp(0.0, double.infinity);

    return FareBreakdown(
      flagdown: flagdown,
      distanceFare: distanceFare,
      waitingFare: waitingFare,
      subtotal: subtotal,
      discountPercent: applyDiscount ? discountPercent : 0,
      discountAmount: discount,
      total: total,
      isFuelBased: preset.isFuelBased,
    );
  }

  static double estimateFuelLiters({
    required double distanceKm,
    required double kmPerLiter,
  }) {
    if (kmPerLiter <= 0) return 0;
    return distanceKm / kmPerLiter;
  }

  static double estimateFuelCost({
    required double distanceKm,
    required double kmPerLiter,
    required double gasPricePerLiter,
  }) {
    return estimateFuelLiters(distanceKm: distanceKm, kmPerLiter: kmPerLiter) *
        gasPricePerLiter;
  }
}
