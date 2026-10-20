import 'dart:js_interop';

@JS('window.matchMedia')
external _MediaQueryList _matchMedia(String query);

extension type _MediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
}

/// Read when MaterialApp's builder runs; a live OS toggle only takes effect
/// after something else rebuilds it (e.g. a resize or theme change).
bool platformPrefersReducedMotion() =>
    _matchMedia('(prefers-reduced-motion: reduce)').matches;
