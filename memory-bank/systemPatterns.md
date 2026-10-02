# System Patterns

## Architecture Overview
Multi-platform architecture utilizing reactive state management and modular repositories. The desktop UI uses split-view layouts (Sidebar, Content, Inspector) while mobile surfaces leverage adaptive tab bars and safe-area insets.

## Design Patterns
- **State Management:** Provider / Riverpod for reactive application state.
- **Data Layer:** Repository pattern abstracting local persistence (Hive/SQLite) and remote endpoints (Dio/HTTP).
- **Component Styling:** Centralized theme data adhering to Apple Human Interface Guidelines; avoid hardcoded hex colors or arbitrary paddings.
