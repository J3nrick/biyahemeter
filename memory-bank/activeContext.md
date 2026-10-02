# Active Context

## Current Focus
Vercel deployment verification and live mobile testing.

## Recent Changes
- Recompiled and shipped web release bundle to `build/web`:
  - Identified root cause of Vercel not updating: Vercel does not build Flutter in CI (`buildCommand: ""` in `vercel.json`), serving precompiled assets from `build/web`.
  - Ran `flutter build web --release` to compile the new luxury splash screen, agreements screen, and Apple HIG components into `build/web/`.
  - Committed as `585cbad` and pushed to `origin/main`.
- Redesigned splash screen and agreements screen with luxury minimalism:
  - Splash: stripped all AI-cliché orbs, pulse rings, breathing dots. Pure canvas with critically damped spring logo entry (0.94→1.0), wordmark, single tagline, and 1.5px linear progress trace.
  - Agreements: iOS Settings-style grouped inset cards with 0.5pt hairline borders, inset dividers, outline Cupertino icons, full-width pill CTA with immediate scale-press feedback.
  - SplashGate: 2.2s splash animation with scale-down crossfade transition to agreements.

## Immediate Next Steps
- Verify Vercel deployment URL updates to display the new splash and agreements experience.
- Verify continuous real-time GPS tracking and live fare matrix updates on emulator.



