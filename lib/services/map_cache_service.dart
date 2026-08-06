import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:path_provider/path_provider.dart';

/// Offline tile caching for flutter_map via flutter_map_cache.
class MapCacheService extends ChangeNotifier {
  bool _enabled = true;
  bool _ready = false;
  CacheStore? _store;

  bool get enabled => _enabled;
  bool get ready => _ready;

  Future<void> init() async {
    if (kIsWeb) {
      _ready = false;
      notifyListeners();
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      _store = HiveCacheStore(dir.path, hiveBoxName: 'mapTiles');
      _ready = true;
    } catch (_) {
      _store = MemCacheStore();
      _ready = true;
    }
    notifyListeners();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  TileProvider createTileProvider() {
    final store = _store;
    if (!_enabled || !_ready || store == null) {
      return NetworkTileProvider();
    }
    return CachedTileProvider(
      store: store,
      maxStale: const Duration(days: 14),
    );
  }
}
