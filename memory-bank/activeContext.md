# Active Context

## Current Focus
Enhanced Splash Screen with luxury transit speedometer dial, glowing telemetry, perspective road velocity grid, and fluid startup choreography.

## Splash Screen Upgrade:
1. **Instrument Speedometer Dial:**
   - Precision circular dial with 36 ticks (major and minor) and dynamic sweep arc (from 0% to 100%) that powers on like a luxury vehicle instrument cluster.
   - Electric cyan glow head particle that travels along the perimeter.
2. **Elevated 3D Glass Squircle Emblem:**
   - Centered inside the dial, the BiyaheMeter mark is mounted in a frosted glass squircle with cyan neon edge, inner highlight rim, and sweeping diagonal specular sheen reflection.
3. **Perspective Highway Streams:**
   - Custom-painted perspective road grid and moving velocity pulses at the horizon, establishing a direct emotional connection to travel, transit, and metering.
4. **Dynamic Telemetry Startup Capsule:**
   - Multi-phase startup ticker (`INITIALIZING SATELLITE GPS` -> `CALIBRATING FARE ENGINE` -> `BIYAHEMETER ARMED & READY`) with pulsing live GPS satellite beacon and numeric percentage readout.
   - Precision hairline gradient progress track filling up to 100% over the 3.0s window.
5. **Fluid Spring & Haptic Choreography:**
   - Smooth spring entrance (`Curves.easeOutBack`), ambient breathing glow, tactile haptic pulses on start and lock, and forward zoom cross-dissolve departure at 3.0s.

## Verification:
- `dart analyze`: 0 warnings, 0 errors.
- `flutter build web --release`: Compiled successfully in 24.8s.






