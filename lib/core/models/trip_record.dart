import 'package:latlong2/latlong.dart';

class TripRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double waitingMinutes;
  final double totalFare;
  final double baseFare;
  final double distanceFare;
  final double waitingFare;
  final double discountPercent;
  final double discountAmount;
  final double fuelLiters;
  final double fuelCost;
  final String presetName;
  final bool discountApplied;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;

  const TripRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.waitingMinutes,
    required this.totalFare,
    required this.baseFare,
    required this.distanceFare,
    required this.waitingFare,
    required this.discountPercent,
    required this.discountAmount,
    required this.fuelLiters,
    required this.fuelCost,
    required this.presetName,
    required this.discountApplied,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  Duration get duration => endedAt.difference(startedAt);

  double get averageSpeedKmh {
    final hours = duration.inSeconds / 3600.0;
    if (hours <= 0) return 0;
    return distanceKm / hours;
  }

  double get netEarnings => totalFare - fuelCost;

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'distanceKm': distanceKm,
        'waitingMinutes': waitingMinutes,
        'totalFare': totalFare,
        'baseFare': baseFare,
        'distanceFare': distanceFare,
        'waitingFare': waitingFare,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'fuelLiters': fuelLiters,
        'fuelCost': fuelCost,
        'presetName': presetName,
        'discountApplied': discountApplied,
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
      };

  factory TripRecord.fromMap(Map<dynamic, dynamic> map) => TripRecord(
        id: map['id'] as String,
        startedAt: DateTime.parse(map['startedAt'] as String),
        endedAt: DateTime.parse(map['endedAt'] as String),
        distanceKm: (map['distanceKm'] as num).toDouble(),
        waitingMinutes: (map['waitingMinutes'] as num).toDouble(),
        totalFare: (map['totalFare'] as num).toDouble(),
        baseFare: (map['baseFare'] as num).toDouble(),
        distanceFare: (map['distanceFare'] as num).toDouble(),
        waitingFare: (map['waitingFare'] as num).toDouble(),
        discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
        discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
        fuelLiters: (map['fuelLiters'] as num?)?.toDouble() ?? 0,
        fuelCost: (map['fuelCost'] as num?)?.toDouble() ?? 0,
        presetName: map['presetName'] as String? ?? 'Unknown',
        discountApplied: map['discountApplied'] as bool? ?? false,
        startLat: (map['startLat'] as num?)?.toDouble(),
        startLng: (map['startLng'] as num?)?.toDouble(),
        endLat: (map['endLat'] as num?)?.toDouble(),
        endLng: (map['endLng'] as num?)?.toDouble(),
      );

  LatLng? get startPoint =>
      startLat != null && startLng != null ? LatLng(startLat!, startLng!) : null;

  LatLng? get endPoint =>
      endLat != null && endLng != null ? LatLng(endLat!, endLng!) : null;
}
