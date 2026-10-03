# Active Context

## Current Focus
Resolved UI and rendering lag across Web and Mobile; verified clean release build.

## Root Causes of Lag Identified & Fixed:
1. **Continuous `setState` on Draggable Sheet Drag:**
   - `NotificationListener<DraggableScrollableNotification>` in [home_screen.dart](file:///Users/johnraphaelambalong/jenrick%20%28antigravity%20projects%29/portfolio/biyahemeter/lib/features/meter/home_screen.dart) previously triggered `setState(() => _sheetExtent = next)` on every 0.01 delta, forcing 60-120 full-screen rebuilds per second during gestures.
   - **Fix:** Switched to boolean thresholding `_isCompactSheet = notification.extent < 0.42`. Zero `setState` calls occur during dragging between min/peek/max extents; rebuilds only fire once when crossing the compact layout boundary.
2. **Expensive Multi-Pass `BackdropFilter` Over Moving Map:**
   - Stacked `BackdropFilter` blurs (sigma 10-20) were active in `_DashboardSheet`, `_TopStatusBar`, `_SettingsBottomSheet`, and `trip_summary_sheet.dart` directly above the map canvas.
   - **Fix:** Replaced with hardware-accelerated translucent Apple HIG materials (`theme.colorScheme.surface.withValues(alpha: 0.88-0.96)`) with subtle ambient shadows and hairline borders (0.8px). Eliminated offscreen GPU blur passes while maintaining the exact translucent Apple aesthetic.
3. **Unbounded Animation Repaint Invalidation:**
   - Pulsing radar puck `_GpsPuck` was running an `AnimationController` on a continuous 2-second loop inside `MarkerLayer` without isolation.
   - **Fix:** Wrapped `_GpsPuck` in `RepaintBoundary` so 60fps radar wave repainting is isolated to its own 36x36 layer. Wrapped `FlutterMap` in `RepaintBoundary` to prevent UI overlays from invalidating tile canvas.
4. **Tile Cache Integration & Buffering:**
   - Connected `MapCacheService.createTileProvider()` and added `keepBuffer: 3`, `panBuffer: 1` on `TileLayer` in [map_widget.dart](file:///Users/johnraphaelambalong/jenrick%20%28antigravity%20projects%29/portfolio/biyahemeter/lib/features/map/map_widget.dart).

## Verification:
- `dart analyze`: 0 warnings, 0 errors.
- `flutter build web --release`: Successfully built in 24.6s.






