# Active Context

## Current Focus
Vercel deployment verification and live mobile testing.

## Recent Changes
- Removed messy scroll guides from `AgreementsScreen`:
  - Disabled vertical scrollbars via `ScrollConfiguration(scrollbars: false)`, global `MaterialScrollBehavior(scrollbars: false)`, and universal CSS `scrollbar-width: none` / `::-webkit-scrollbar { display: none; }`.
  - Removed horizontal `LinearProgressIndicator` line and progress count under header, allowing the title and subtitle to flow directly into the policy cards.
  - Recompiled web release to `build/web/` for Vercel deployment. Zero analyzer issues.

## Immediate Next Steps
- Verify Vercel deployment URL updates to display the new splash and agreements experience.
- Verify continuous real-time GPS tracking and live fare matrix updates on emulator.



