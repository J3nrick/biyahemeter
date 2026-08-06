import 'package:hive_flutter/hive_flutter.dart';
import 'package:biyahe_meter/core/models/trip_record.dart';

class HistoryService {
  static const _boxName = 'trip_history';
  Box<dynamic>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      // Plain Map storage — no typed adapter required.
    }
    _box = await Hive.openBox(_boxName);
  }

  Box<dynamic> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('HistoryService.init() must be called first');
    }
    return box;
  }

  Future<void> saveTrip(TripRecord trip) async {
    await _requireBox.put(trip.id, trip.toMap());
  }

  List<TripRecord> loadTrips() {
    final box = _box;
    if (box == null) return const [];
    final trips = box.values
        .whereType<Map>()
        .map((e) => TripRecord.fromMap(e))
        .toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return trips;
  }

  Future<void> clearAll() async {
    await _requireBox.clear();
  }

  Future<void> deleteTrip(String id) async {
    await _requireBox.delete(id);
  }

  String exportCsv(List<TripRecord> trips) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,startedAt,endedAt,durationMin,distanceKm,waitingMin,totalFare,fuelCost,netEarnings,preset,discount',
    );
    for (final t in trips) {
      buffer.writeln(
        [
          t.id,
          t.startedAt.toIso8601String(),
          t.endedAt.toIso8601String(),
          (t.duration.inSeconds / 60).toStringAsFixed(1),
          t.distanceKm.toStringAsFixed(3),
          t.waitingMinutes.toStringAsFixed(2),
          t.totalFare.toStringAsFixed(2),
          t.fuelCost.toStringAsFixed(2),
          t.netEarnings.toStringAsFixed(2),
          '"${t.presetName}"',
          t.discountApplied ? '20%' : '0%',
        ].join(','),
      );
    }
    return buffer.toString();
  }
}
