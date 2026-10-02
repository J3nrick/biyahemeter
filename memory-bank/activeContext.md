# Active Context

## Current Focus
Live mobile testing and device execution on local emulator.

## Recent Changes
- Configured and launched native mobile emulator environment on macOS:
  - Installed Android Emulator (v37.2.12) and Android 34 (`google_apis;arm64-v8a`) system image.
  - Created and booted `Pixel_8_Pro` AVD with hardware acceleration on Apple Silicon.
  - Resolved toolchain incompatibility by installing Adoptium Temurin OpenJDK 21 (`~/.jdks/jdk-21.0.12.1+1`).
  - Fixed MapLibre GL controller/widget class casing in `lib/features/map/map_widget.dart` (`ml.MapLibreMapController`, `ml.MapLibreMap`).
  - Upgraded `font_awesome_flutter` to `^11.0.0` for Flutter 3.47 compatibility and updated `_SettingsTile`, `_DefaultRow`, and `MetricCard` to accept `FaIconData`.
  - Built `assembleDebug` APK and launched live on `Pixel_8_Pro` emulator (`emulator-5554`).
  - Verified onboarding flow, location permissions, and live dashboard rendering with MapLibre vector map and Apple HIG frosted glass cards.

## Immediate Next Steps
- Verify continuous real-time GPS tracking and live fare matrix updates on emulator.
- Test responsive layout behavior across tablet/desktop split view form factors.

