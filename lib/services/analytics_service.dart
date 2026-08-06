import 'package:biyahe_meter/core/models/trip_record.dart';

enum AnalyticsPeriod { today, week, month, all }

class AnalyticsSnapshot {
  final int tripCount;
  final double totalEarnings;
  final double totalFuelCost;
  final double netEarnings;
  final double totalDistanceKm;
  final double totalWaitingMinutes;

  const AnalyticsSnapshot({
    required this.tripCount,
    required this.totalEarnings,
    required this.totalFuelCost,
    required this.netEarnings,
    required this.totalDistanceKm,
    required this.totalWaitingMinutes,
  });

  static const empty = AnalyticsSnapshot(
    tripCount: 0,
    totalEarnings: 0,
    totalFuelCost: 0,
    netEarnings: 0,
    totalDistanceKm: 0,
    totalWaitingMinutes: 0,
  );
}

class AnalyticsService {
  List<TripRecord> filterByPeriod(
    List<TripRecord> trips,
    AnalyticsPeriod period, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    switch (period) {
      case AnalyticsPeriod.today:
        return trips
            .where((t) =>
                t.endedAt.year == current.year &&
                t.endedAt.month == current.month &&
                t.endedAt.day == current.day)
            .toList();
      case AnalyticsPeriod.week:
        final start = current.subtract(Duration(days: current.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day);
        return trips.where((t) => !t.endedAt.isBefore(weekStart)).toList();
      case AnalyticsPeriod.month:
        return trips
            .where((t) =>
                t.endedAt.year == current.year &&
                t.endedAt.month == current.month)
            .toList();
      case AnalyticsPeriod.all:
        return List.of(trips);
    }
  }

  AnalyticsSnapshot summarize(List<TripRecord> trips) {
    if (trips.isEmpty) return AnalyticsSnapshot.empty;
    var earnings = 0.0;
    var fuel = 0.0;
    var distance = 0.0;
    var waiting = 0.0;
    for (final t in trips) {
      earnings += t.totalFare;
      fuel += t.fuelCost;
      distance += t.distanceKm;
      waiting += t.waitingMinutes;
    }
    return AnalyticsSnapshot(
      tripCount: trips.length,
      totalEarnings: earnings,
      totalFuelCost: fuel,
      netEarnings: earnings - fuel,
      totalDistanceKm: distance,
      totalWaitingMinutes: waiting,
    );
  }
}
