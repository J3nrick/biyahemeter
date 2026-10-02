# Technical Context

## Core Stack
- **Frontend:** Flutter (with Cupertino & Material 3), Dart, Next.js / React
- **Backend:** Node.js, PHP Laravel
- **Database & Local Storage:** Hive, SQLite, PostgreSQL, Firebase

## Development Guardrails
- **Agent Rules:** Enforce diff-based patch editing for all LLM code generation. Do not overwrite entire files unnecessarily.
- **Dependency Management:** All new packages must be explicitly approved before modifying `pubspec.yaml` or running dependency commands.
- **UI Architecture:** Keep UI widgets strictly separated from business and state management logic.
