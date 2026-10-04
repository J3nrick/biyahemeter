# Active Context

## Current Focus
Implemented the user-selected **Neon Transit Beam Reveal & Hyperspace Zoom** splash animation for BiyaheMeter.

## Splash Animation Architecture:
1. **Phase 1: Horizontal Laser Transit Streak (0.0s – 0.65s):**
   - High-energy cyan/white laser beam sweeps across the road baseline of the logo from left to right.
   - Cascading speed dash ignition along the right half with tactile haptic pulse (`lightImpact`).
2. **Phase 2: Upward Energy Scan & "METER" Pop (0.65s – 1.45s):**
   - Luminous energy wavefront sweeps up from the road bar to reveal the bold "Biyahe" stencil lettering.
   - Electric cyan pop flash on the "METER" header with digital precision.
3. **Phase 3: Pristine HD Lock & Specular Sheen (1.45s – 2.40s):**
   - Logo locked in 100% full HD clarity with breathing ambient sapphire halo.
   - Diagonal liquid specular glint sweeping across the contours (`selectionClick` haptic).
4. **Phase 4: Hyperspace Forward Zoom (2.40s – 3.00s):**
   - Radial velocity light streaks ignite.
   - The logo accelerates directly towards the camera (1.0x -> 3.4x) with an ease-in exponential curve and soft luminous aperture flash, dissolving seamlessly into the Agreements Screen at exactly 3.0s.

## Splash Performance Rules (do NOT regress):
Root causes of the earlier splash lag: two nested `ShaderMask`s over the full logo + `Opacity` (each = per-frame offscreen `saveLayer`, magnified by the 3.4x zoom), `MaskFilter.blur` glows, 24 per-ray gradient shaders per frame, full subtree rebuild every frame via `AnimatedBuilder`, and the logo being decoded on the first animated frame.
Fix (in `premium_splash_view.dart`):
- Entire animation is ONE `CustomPainter` with `repaint: _anim` (zero widget rebuilds); static backdrop and animated canvas in separate `RepaintBoundary`s.
- Logo is pre-decoded to `ui.Image` BEFORE the controller starts (1.5s fallback timer).
- No `saveLayer`: reveal = sliced `drawImageRect` + alpha; glint = clipped tinted re-draw; glows = stacked translucent shapes; rays = batched `drawPoints`.
- Never reintroduce ShaderMask/Opacity/BackdropFilter/MaskFilter.blur on the splash.

## Deployment & Git Status:
- Branch: `main`
- Commit `305e18e` pushed to `origin/main` (original splash). Splash performance rewrite is committed locally; push pending user approval.








