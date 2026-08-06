import 'package:flutter/foundation.dart';
import 'package:biyahe_meter/core/models/fare_preset.dart';

class FareMatrixProvider extends ChangeNotifier {
  FarePresetId _presetId = FarePresetId.regularTaxi;
  bool _discountEnabled = false;
  static const double discountPercent = 20.0;

  FarePresetId get presetId => _presetId;
  FarePreset get activePreset => FarePreset.byId(_presetId);
  bool get discountEnabled => _discountEnabled;
  String get discountLabel => 'Senior / PWD / Student (20%)';

  void selectPreset(FarePresetId id) {
    if (_presetId == id) return;
    _presetId = id;
    notifyListeners();
  }

  void setDiscountEnabled(bool value) {
    if (_discountEnabled == value) return;
    _discountEnabled = value;
    notifyListeners();
  }

  void toggleDiscount() => setDiscountEnabled(!_discountEnabled);
}
