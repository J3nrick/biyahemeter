# Active Context

## Current Focus
App-wide Apple Human Interface Guidelines (HIG) compliance across all screens and components.

## Recent Changes
- Completed systematic Apple HIG UI/UX audit & refactoring across the codebase:
  - `lib/core/theme/app_theme.dart`: added `FontFeature.tabularFigures()` to `fareStyle` and configured native Cupertino page transitions.
  - `lib/features/meter/widgets/glass_card.dart`: stripped muddy drop shadows from `GlassCard` and `MetricCard`, implemented translucent material surfaces with hairline borders, and added tabular figures for live meter readouts.
  - `lib/features/meter/home_screen.dart`: converted `_TopStatusBar` to a floating frosted glass pill without drop shadow; enhanced `_FareHeroCard` border and typography.
  - `lib/features/meter/widgets/trip_summary_sheet.dart`: wrapped summary sheet in frosted glass blur with translucent surface styling.
  - `lib/features/history/analytics_screen.dart`: updated `_InsightCard` and trip list items to translucent grouped card styling.
  - `lib/features/onboarding/`: polished splash spring physics, safe areas, and 44x44pt touch targets on agreements screen.

## Immediate Next Steps
- Verify continuous real-time GPS tracking and live fare matrix updates.
- Test responsive layout behavior across tablet/desktop split view form factors.

