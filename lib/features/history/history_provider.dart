import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biyahe_meter/core/models/trip_record.dart';
import 'package:biyahe_meter/services/analytics_service.dart';
import 'package:biyahe_meter/services/history_service.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._history, this._analytics);

  final HistoryService _history;
  final AnalyticsService _analytics;

  List<TripRecord> _trips = [];
  AnalyticsPeriod _period = AnalyticsPeriod.today;
  bool _loaded = false;

  List<TripRecord> get trips => List.unmodifiable(_trips);
  AnalyticsPeriod get period => _period;
  bool get loaded => _loaded;

  List<TripRecord> get filteredTrips =>
      _analytics.filterByPeriod(_trips, _period);

  AnalyticsSnapshot get snapshot => _analytics.summarize(filteredTrips);

  Future<void> load() async {
    _trips = _history.loadTrips();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addTrip(TripRecord trip) async {
    await _history.saveTrip(trip);
    _trips = _history.loadTrips();
    notifyListeners();
  }

  void setPeriod(AnalyticsPeriod period) {
    if (_period == period) return;
    _period = period;
    notifyListeners();
  }

  Future<void> exportCsv() async {
    final csv = _history.exportCsv(_trips);
    await SharePlus.instance.share(
      ShareParams(
        text: csv,
        subject: 'BiyaheMeter PH Trip Log CSV',
      ),
    );
  }

  Future<void> clearAll() async {
    await _history.clearAll();
    _trips = [];
    notifyListeners();
  }
}
