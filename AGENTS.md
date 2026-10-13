# Globetrottr AI Developer Guidelines

This document provides context, architectural rules, and development guidelines for AI coding assistants (Antigravity, Claude Code, etc.) working on the **Globetrottr** repository.

---

## 1. Project Overview & Architecture

Globetrottr is a gamified travel and exploration tracking platform where users discover land areas (fog-of-war clearing), record trips, complete quests, and compete with friends.

The repository is organized as a monorepo:
* **Frontend (`globetrottr_front/`)**: Cross-platform mobile app built with Flutter and Dart.
* **Backend (`globetrottr_backend/`)**: REST API built with Java 25 and Spring Boot 4.0.
* **Database & Infrastructure (`docker-compose.yaml`, `db-init/`)**: PostgreSQL with PostGIS extension for spatial queries.

---

## 2. Repository Structure

```text
Globetrottr/
├── globetrottr_front/          # Flutter mobile application
│   ├── lib/
│   │   ├── core/               # Shared theme, routing, config, network, exceptions, widgets
│   │   ├── features/           # Feature-first modularized code
│   │   │   ├── auth/           # Login, registration, token handling
│   │   │   ├── fog/            # Fog of war exploration & spatial polygons
│   │   │   ├── friends/        # Social, friends lists, friend GeoJSON
│   │   │   ├── map/            # Map UI, tile caching, location tracking
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
│   │   │   ├── quest/          # Quests & level/exp mechanics
│   │   │   ├── region/         # Administrative boundaries & discovery
│   │   │   ├── security/       # JWT auth filters, OAuth2, user details
│   │   │   ├── user/           # User management & authentication
│   │   │   └── GlobetrottrApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── db/migration/   # Flyway SQL migrations
│   ├── build.gradle            # Gradle build, Java 25, Spotless
│   └── Dockerfile
│
├── .agents/                    # Antigravity agent configuration & skills
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

### B. Compile & Verification Verification (Mandatory)
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
4. **Compile / Build Verification:**
   ```bash
   flutter build apk --debug
   # or verify compilation with dry-run tests
   ```

#### Backend Checks (`globetrottr_backend/`)
Run all commands from within the `globetrottr_backend` directory:
1. **Format / Linter (Spotless):**
   ```bash
   # Check code formatting
   ./gradlew spotlessCheck

   # Apply Google Java Format, import cleanup, and trailing whitespace fixes
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
* **Complete Localization (i18n & Error Mapping):**
  * **Target languages:** Always localize to both **English (`en`)** and **Polish (`pl`)** (e.g., `app_en.arb` and `app_pl.arb`). Every added translation key must exist in both language files.
  * **Handling Polish in code:** All source code, variable names, comments, and commits must be in English. If any Polish text is encountered:
    * If user-facing (e.g. hardcoded Polish UI strings): rewrite the code in English and extract translations into both `app_en.arb` and `app_pl.arb`.
    * If non-user-facing (e.g. Polish comments, variable/class names): rewrite directly into English.
  * **Layered localization:**
    * **UI strings (labels, buttons, titles, forms, validation messages):** Place in `.arb` localization files.
    * **Service and domain exceptions:** Never throw raw user-facing English strings in data/service layers. Define typed error enums/codes in `core/exceptions/` and map them to localized strings in the UI layer using Dart extensions.
    * **Dynamic quantities & plurals:** Use ICU plural format in `.arb` files so that the generated Dart class handles counts correctly.
  * Only strictly technical, non-user-facing strings may remain as unlocalized Dart constants (HTTP headers, database table/column names, route paths, asset paths, regex).
* **Widget granularity & sizing:** Widgets must be small, focused, and reusable. If any widget or file becomes huge (>150-200 lines or deep nesting), propose splitting it into smaller, reusable components under `core/widgets/` or `features/<feature>/widgets/`.
* **Configurable theme:** All styling (colors, text styles, margins, corner radiuses, button styles) must be centrally configurable. Never hardcode colors or styles inside widgets. If hardcoded styling is discovered, flag it to the user and ask for permission to migrate it to the theme files under `core/theme/`.
* **State Management:** Use `flutter_riverpod` (v3). Keep UI widgets lightweight and dumb; encapsulate business logic and state in Riverpod providers/notifiers.
* **Routing:** Use `go_router` for declarative navigation and deep linking.
* **Immutability:** Use immutable state models.
* **Offline-first:** Respect offline cache layers (`sqflite` for tiles/data, `flutter_secure_storage` for credentials).

### Backend (Java / Spring Boot)
* **Architecture:** Adhere strictly to the Controller $\rightarrow$ Service $\rightarrow$ Repository layering.
* **DTO Pattern:** Never expose JPA Entities directly in Controller request or response bodies. Always map to/from DTOs.
* **Database Migrations:** Never alter database schemas manually or rely on `hibernate.ddl-auto=update`. All database schema changes must be written as Flyway versioned SQL scripts in `src/main/resources/db/migration/V<timestamp>__<description>.sql`.
* **Spatial Data:** Use PostGIS and Hibernate Spatial types (`Geometry`, `Polygon`, `Point`). Ensure SRID 4326 (WGS 84) consistency.
* **Code Formatting:** Follow Google Java Format (enforced via `./gradlew spotlessApply`). Do not check in unused imports or unformatted code.

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
  * `feat(map): implement tile caching for offline map exploration`
  * `fix(auth): handle expired refresh token in Riverpod auth provider`
  * `test(backend): add spatial query integration test for fog polygons`
