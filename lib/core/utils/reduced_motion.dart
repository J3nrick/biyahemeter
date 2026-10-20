import 'package:flutter/widgets.dart';

import 'reduced_motion_stub.dart'
    if (dart.library.js_interop) 'reduced_motion_web.dart';

/// Folds every "reduce motion" signal into [MediaQueryData.disableAnimations],
/// so app code and Flutter widgets only need to check that one flag.
/// The web engine ignores `prefers-reduced-motion`, and iOS reports Reduce
/// Motion as a separate engine flag; both are bridged here.
Widget applyReducedMotion(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final reduce =
      mq.disableAnimations ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion ||
      platformPrefersReducedMotion();
  return MediaQuery(
    data: mq.copyWith(disableAnimations: reduce),
    child: child ?? const SizedBox.shrink(),
  );
}
