# Active Context

## Current Focus
Vercel deployment verification and live mobile testing.

## Recent Changes
- Fixed map visibility and restored rock-solid cross-platform map engine:
  - Root Cause Diagnosed: The map was switched to `maplibre_gl` in a previous commit, which completely broke on Web because `maplibre-gl.js` script tags and WebGL context were missing, and the external Carto vector style URLs (`dark-matter-gl-style/style.json`) failed without API keys/CORS/glyph fonts.
  - Solution Implemented: Replaced `maplibre_gl` with high-performance, native `flutter_map` (7.0.2) + CartoDB raster tiles (`dark_all` and `light_all`) + OSM attribution.
  - Removed `maplibre_gl` dependency from `pubspec.yaml`, resolving Mac toolchain native asset crashes and package bloat.
  - Implemented smooth camera tween animations, Apple-style pulsing GPS location puck with radar halo, auto-follow with bottom panel offset, and HIG trip reset dialog.
  - Integrated `MapCacheService` with Hive/MemCacheStore for offline tile caching.
  - Recompiled web release (`flutter build web --release`). Zero analyzer issues.

## Immediate Next Steps
- Inform user of root cause and resolution.
- Request user approval to push commit to `origin/main` for Vercel deployment.





