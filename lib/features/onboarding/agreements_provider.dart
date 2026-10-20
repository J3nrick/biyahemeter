import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AgreementsProvider extends ChangeNotifier {
  /// Bump when the agreement text changes so everyone re-accepts.
  static const termsVersion = 1;
  static const _acceptedVersionKey = 'agreements_accepted_version';

  final Box<dynamic>? _store;

  /// Starts fully accepted if [store] remembers acceptance of [termsVersion].
  AgreementsProvider([this._store]) {
    if (_store?.get(_acceptedVersionKey) == termsVersion) {
      _acceptedTerms = _acceptedPrivacy = _verifiedGasData = true;
    }
  }

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

  void acceptAll() {
    _acceptedTerms = true;
    _acceptedPrivacy = true;
    _verifiedGasData = true;
    _store?.put(_acceptedVersionKey, termsVersion);
    notifyListeners();
  }
}
