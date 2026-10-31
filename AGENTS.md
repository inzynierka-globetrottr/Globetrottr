# Globetrottr AI Developer Guidelines

This document provides context, architectural rules, and development guidelines for AI coding assistants (Antigravity, Claude Code, etc.) working on the **Globetrottr** repository.

---

## 1. Project Overview & Architecture

Globetrottr is a gamified travel and exploration tracking platform where users discover land areas (fog-of-war clearing), record trips, complete quests, and compete with friends.

The repository is organized as a monorepo:
* **Frontend (`globetrottr_front/`)**: Cross-platform mobile app built with Flutter and Dart.
* **Backend (`globetrottr_backend/`)**: REST API built with Java 25 and Spring Boot 4.0.
* **Database & Infrastructure (`docker-compose.yaml`, `db-init/`)**: PostgreSQL with PostGIS extension for spatial queries.

### ROADMAP.md (mandatory)
`ROADMAP.md` in the repository root is the **source of truth** for what the app is, what is planned and what is being built. Its purpose: any agent can read it first and understand the project, its direction and the reasons behind it from the first prompt.
* **Read it first:** before starting any task, read `ROADMAP.md`.
* **Keep it current:** every planned change, and every change an agent is currently introducing, must be added or updated there as part of the same task. A task is not complete until the roadmap reflects it.
* **Record decisions:** write down the key design and architectural decisions together with the reasons (and rejected alternatives), not implementation detail or measurements.
* **Keep it concise:** short entries, grouped per area, each with a status (Done, In progress, Planned, Idea). Remove or rewrite entries that became outdated.
* **Mentions, not documentation:** one to three lines per decision or plan: what and why. No constant or class names, no mechanics, no numbers beyond the key one, no history of the bug. The explanation belongs in code comments and tests.
* **Code wins:** if the code and the roadmap disagree, trust the code, fix the roadmap and report the discrepancy to the user.
* **Binding decisions:** settled decisions are binding; changing one needs the owner's approval and a roadmap update.

---

## 2. Repository Structure

```text
Globetrottr/
├── ROADMAP.md                  # Source of truth: app scope, plans, key decisions (mandatory reading)
├── globetrottr_front/          # Flutter mobile application
│   ├── lib/
│   │   ├── core/               # Shared theme, routing, config, network, exceptions, widgets
│   │   ├── features/           # Feature-first modularized code
│   │   │   ├── auth/           # Login, registration, token handling
│   │   │   ├── fog/            # Fog of war: own fog as local bitmap tiles, friends' fog
│   │   │   ├── friends/        # Social, friends lists, friend GeoJSON
│   │   │   ├── map/            # Map UI, location tracking, track log, pending GPS points outbox
│   │   │   ├── profile/        # User stats, avatar, settings
│   │   │   └── quests/         # Gamification quests, exp, achievements
│   │   └── main.dart
│   ├── test/                   # Unit and widget tests
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
├── globetrottr_backend/        # Spring Boot application
│   ├── src/
│   │   ├── main/java/sniezynki/agh/globetrottr/
│   │   │   ├── config/         # Security, CORS, OpenAPI, App configuration
│   │   │   ├── email/          # Verification codes & email services
│   │   │   ├── exception/      # Global exception handling & custom errors
│   │   │   ├── fog/            # Fog processing & spatial geometry
│   │   │   ├── friend/         # Friends & social endpoints
│   │   │   ├── location/       # Geolocation records & tracks
│   │   │   ├── profile/        # User profile & avatar management
│   │   │   ├── quest/          # Quests & level/exp mechanics
│   │   │   ├── region/         # Administrative boundaries & discovery
│   │   │   ├── security/       # JWT auth filters, OAuth2, user details
│   │   │   ├── statistics/     # User exploration & region statistics
│   │   │   ├── sync/           # Offline data synchronization
│   │   │   ├── user/           # User management & authentication
│   │   │   └── GlobetrottrApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── db/migration/   # Flyway SQL migrations
│   ├── build.gradle            # Gradle build, Java 25, Spotless (AOSP 4-space indent)
│   └── Dockerfile
│
├── .agents/                    # Agent configuration & skills
├── .claude/                    # Claude Code configuration & skills symlink
├── .mcp.json                   # Shared MCP configuration (Dart MCP server)
├── docker-compose.yaml         # Local PostgreSQL + PostGIS & Backend setup
├── docker-compose.prod.yaml    # Production deployment setup
└── README.md
```

---

## 3. Communication & Tone Guidelines
* **Short and concise:** Always provide brief, direct answers. Avoid lengthy narrative prose.
* **Bullet points:** Format answers, findings, and explanations using structured bullet points.
* **No emojis:** Do NOT use emojis in your responses, in git commit proposals, or in code.
* **Clean existing emojis:** If emojis are encountered anywhere in the codebase or comments, flag them to the user and ask for permission to remove them.

---

## 4. Core Principles & Workflow

### A. Test-Driven Development (TDD)
* **Write tests first:** When implementing new features or fixing bugs, create failing unit/widget/integration tests before writing the implementation code.
* **Never break existing tests:** Always run the test suite to ensure no regressions were introduced.

### B. Compile & Verification (Mandatory)
Before declaring any task complete, verify that code compiles cleanly and passes all linters and tests.

#### Frontend Checks (`globetrottr_front/`)
Run all commands from within the `globetrottr_front` directory:
1. **Analyze / Lint:**
   ```bash
   flutter analyze
   ```
2. **Format:**
   ```bash
   dart format .
   # or verify formatting:
   dart format --output=none --set-exit-if-changed .
   ```
3. **Run Tests:**
   ```bash
   flutter test
   ```
4. **Optional Full Build Check (Releases / CI):**
   ```bash
   flutter build apk --debug
   ```

#### Backend Checks (`globetrottr_backend/`)
Run all commands from within the `globetrottr_backend` directory:
1. **Format / Linter (Spotless - AOSP 4 spaces):**
   ```bash
   # Check code formatting
   ./gradlew spotlessCheck

   # Apply Google Java Format (AOSP 4 spaces), import cleanup, and trailing whitespace fixes
   ./gradlew spotlessApply
   ```
2. **Compile:**
   ```bash
   ./gradlew compileJava
   ```
3. **Run Tests:**
   ```bash
   ./gradlew test
   ```

---

## 5. Coding Standards & Best Practices

### Code Cleanliness & "No AI Smell"
* **No AI commentary:** Never write comments that state the obvious, restate code syntax, or carry "AI smell" (e.g. `// Here we handle the response`, `// Helper function to...`, `// Added by assistant`).
* **Active cleanup:** If you encounter existing AI-smell comments while inspecting or editing code, remove them immediately. Write self-documenting code with clear variable and function names.

### Frontend (Flutter / Dart)
* **Language & Localization Direction:**
  * **English in code:** All source code, variable names, comments, and commit messages must be in English.
  * **No scope creep on existing strings:** Do not proactively rewrite existing strings (e.g. in `debug/` screens) during unrelated tasks.
  * **Current error handling:** Data and service layers currently use `AppException` subclasses carrying English user-facing messages.
  * **Target architecture (planned):** Full i18n support (English `en` and Polish `pl` via `.arb` files) is planned for a dedicated PR. Once `flutter_localizations` is configured, all user-facing UI labels and error mappings will migrate to `.arb` files.
* **Widget granularity & sizing:** Widgets must be small, focused, and reusable. If any widget or file becomes large (>150-200 lines or deep nesting), propose splitting it into smaller, reusable components under `core/widgets/` or `features/<feature>/screens/widgets/`.
* **Configurable theme:** All styling (colors, text styles, margins, corner radiuses, button styles) must be centrally configurable. Never hardcode colors or styles inside widgets. If hardcoded styling is discovered, flag it to the user and ask for permission to migrate it to the theme files under `core/theme/`.
* **State Management:** Use `flutter_riverpod` (v3). Keep UI widgets lightweight and dumb; encapsulate business logic and state in Riverpod providers/notifiers.
* **Routing:** Use `go_router` for declarative navigation and deep linking.
* **Immutability:** Use immutable state models.
* **Offline-first:** Respect offline storage layers (`sqflite` for offline GPS tracks / local data, `flutter_secure_storage` for credentials).

### Fog of War (frontend)
The user's own fog is computed, stored and drawn on the device only; the network never affects discovering or showing it.
* **Track log is the source of truth:** every usable GPS fix goes to `track_log` (`tracks.db`, sessions + zlib delta blocks, see `track_block_codec.dart`) and to `pending_points` (`globetrottr.db`), which is only the outbox for `/api/map/sync` and is emptied after a sync.
* **Fog is a derived cache:** Web Mercator tiles of 256x256 8-bit coverage in `fog.db`. Base level `FogConfig.baseZoom` (z16) plus a pyramid down to z4 for zoomed-out views. Each pair of consecutive points of one session is rasterized as a stadium with the vision radius (`MapConfig.defaultVisionRadius`, 50 m) and merged with `max`. The fog can always be rebuilt from the track log.
* **Flow:** `LocationService` → `loggedPoints` → `FogNotifier` → `FogStore` (queue, LRU cache, batched writes, isolates for large work) → `FogTileSource` → `BitmapFogPainter`. `LocationNotifier` knows nothing about the fog.
* **Tile format:** codec v2 in `fog/bitmap/fog_tile_codec.dart` (documented to be readable from Java); each written tile gets a revision for future differential upload.
* **Legacy still in place:** friends' fog is drawn from backend GeoJSON polygons (`FogLayer`, `FogPainter`, `friendFogProvider`), and the backend still builds its own fog polygon from synced points for quests and statistics. Every place that still has to be switched to the bitmap fog is marked with `TODO(fog)`. Do not extend these paths.
* **Benchmarks:** `FOG_BENCH=1 flutter test test/benchmark/fog_benchmark_test.dart` (skipped by default).

### Backend (Java / Spring Boot)
* **Architecture:** Adhere strictly to the Controller → Service → Repository layering.
* **DTO Pattern:** Never expose JPA Entities directly in Controller request or response bodies. Always map to/from DTOs.
* **Database Migrations:** Never alter database schemas manually or rely on `hibernate.ddl-auto=update`. All database schema changes must be written as Flyway versioned SQL scripts in `src/main/resources/db/migration/V<timestamp>__<description>.sql`.
* **Spatial Data:** Use PostGIS and Hibernate Spatial types (`Geometry`, `Polygon`, `Point`). Ensure SRID 4326 (WGS 84) consistency.
* **Code Formatting:** Follow Google Java Format in AOSP mode with 4-space indentation (enforced via `./gradlew spotlessApply`). Do not check in unused imports or unformatted code.

---

## 6. Security & Sensitive Data
* Never hardcode secrets, private keys, database passwords, or JWT secrets in code.
* Use `.env` or system environment variables (`SPRING_DATASOURCE_*`, `MAIL_*`, `CLOUDINARY_URL`, etc.).
* Never commit `.env` files or secret keys to version control.

---

## 7. Git, Branching & Commit Guidelines

### A. Branching Policy
* **Always create a new branch:** Never work directly on `main` or `dev`.
* **Branch name format:** `<type>/<ticket-number>-<short-description>`
* **Maximum length:** 25 characters total.
* **Examples:**
  * `feat/67-add-ai-tooling`
  * `fix/12-auth-token`
  * `refactor/45-theme-system`

### B. Commit Protocol
* **DO NOT commit code automatically:** Never run `git commit` or `git push` autonomously.
* **Propose a commit message at the end:** When all tasks, tests, and formatting checks pass, summarize your changes and propose a commit message following the **Conventional Commits** specification:
  ```text
  <type>(<scope>): <subject>

  [optional body]
  ```
  *Examples:*
  * `feat(map): implement pending track sync for offline exploration`
  * `fix(auth): handle expired refresh token in Riverpod auth provider`
  * `test(backend): add spatial query integration test for fog polygons`
