# Active Context

## Current Focus
Live mobile testing and device execution on custom iPhone 17 Pro profile emulator.

## Recent Changes
- Configured and launched custom `iPhone_17_Pro` virtual device:
  - Created AVD `iPhone_17_Pro` matching physical iPhone 16/17 Pro hardware specs: 1206x2622 px, 460 ppi, 19.5:9 display ratio, hole-punch display cutout overlay.
  - Verified Flutter target recognizing device as `iPhone_17_Pro • iPhone 17 Pro • Apple • android`.
  - Booted emulator daemon and confirmed 1206x2622 physical dimensions and 460 density.
  - Deployed `biyahemeter` debug APK to the `iPhone_17_Pro` virtual device.
  - Verified onboarding permissions flow, location grant, and live dashboard rendering with Apple HIG translucent materials and MapLibre map on the 19.5:9 screen.
- Maintained toolchain compatibility with OpenJDK 21 and Flutter 3.47.

## Immediate Next Steps
- Obtain user approval before pushing git commits to remote `origin/main`.
- Verify continuous real-time GPS tracking and live fare matrix updates on emulator.


