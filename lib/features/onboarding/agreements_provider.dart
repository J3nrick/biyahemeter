import 'package:flutter/foundation.dart';

class AgreementsProvider extends ChangeNotifier {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _verifiedGasData = false;

  bool get acceptedTerms => _acceptedTerms;
  bool get acceptedPrivacy => _acceptedPrivacy;
  bool get verifiedGasData => _verifiedGasData;

  /// True only when all three agreements are toggled on.
  bool get allAccepted =>
      _acceptedTerms && _acceptedPrivacy && _verifiedGasData;

  void toggleTerms(bool value) {
    _acceptedTerms = value;
    notifyListeners();
  }

  void togglePrivacy(bool value) {
    _acceptedPrivacy = value;
    notifyListeners();
  }

  void toggleGasData(bool value) {
    _verifiedGasData = value;
    notifyListeners();
  }
}
