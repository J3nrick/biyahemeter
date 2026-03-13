# Project Guidelines

## Code Style
- Follow `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`) and keep `flutter analyze` clean.
- Use feature-based structure under `lib/features/*` and shared code under `lib/core/*`.
- Keep app-wide colors and typography in `lib/core/theme/app_theme.dart`; avoid hardcoding repeated design tokens in screens.
- For fare math, update `lib/core/utils/trip_calculator.dart` and cover changes in `test/widget_test.dart`.

## Architecture
- Entry point is `lib/main.dart` with `MultiProvider` registration.
- State management is `provider` + `ChangeNotifier`:
  - `lib/features/onboarding/agreements_provider.dart`
  - `lib/features/meter/meter_provider.dart`
- Feature boundaries:
  - `lib/features/onboarding`: consent flow before meter usage
  - `lib/features/meter`: trip state, fare updates, controls UI
  - `lib/features/map`: `flutter_map`-based map rendering
- `MeterProvider` owns live trip data (GPS updates, waiting-time accumulation, total fare recalculation).

## Build And Test
- Install dependencies: `flutter pub get`
- Run app: `flutter run`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Regenerate launcher icons after logo changes: `flutter pub run flutter_launcher_icons:main`
- Regenerate splash after splash config/logo changes: `flutter pub run flutter_native_splash:create`
- Web deploy output is `build/web` (see `vercel.json`), so build with: `flutter build web`

## Conventions
- Respect platform guards around permissions. `permission_handler` is not supported on web; keep `kIsWeb` checks when changing startup/permission logic in `lib/main.dart`.
- Avoid editing generated outputs in `build/`; edit source files under `lib/`, `assets/`, `web/`, and platform folders.
- When changing trip behavior, preserve existing GPS-noise protections in `lib/features/meter/meter_provider.dart` (accuracy filtering, speed threshold, teleport/glitch filtering) unless there is a clear product reason.
- Keep user-tunable pricing inputs (`baseFare`, `kmPerLiter`, `gasPricePerLiter`) flowing through provider state and `TripCalculator` so logic stays testable.
