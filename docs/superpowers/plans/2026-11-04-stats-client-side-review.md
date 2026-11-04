# Client-side statistics: review fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the client-side statistics on `feat/25-stats-screens` correct and honest: accurate borders for every country, state and city in the world, only statistics the app really measures, screens as in the Neo mock-up, working streaks, and no slow startup.

**Architecture:** Fog tile flushes feed `StatisticsTracker`, which attributes revealed area to a leaf region and its ancestors in `stats.db`; screens read `stats.db` and the local regions DB through Riverpod providers. Boundaries come from one worldwide source (Overture Maps divisions): everything ships inside the app: countries, states and counties in one base DB, cities and city districts as one file per country, copied out of the app's assets the first time the user records in that country (no network). Border tiles are split into small cells so accurate borders show in the numbers.

**Tech Stack:** Flutter, Riverpod 3, go_router, sqflite (+ `sqflite_common_ffi` in tests), intl; Python + DuckDB for the boundary build.

**Spec:** `ROADMAP.md` section "Statistics & administrative boundaries", the mock-up `globetrotttr-neo-neumorphic.html` on `dev` (screens `Neo · Statystyki`, `Neo · Kraje`, `Neo · Region`, `Neo · Miasto`, all in the "Locked in" group), and the findings below.

## Global Constraints

- **No backend changes** in this plan (owner: the backend side of statistics sync is a separate issue). The sync request keeps its current shape.
- `AGENTS.md` rules apply: no hardcoded user-facing strings (both `app_en.arb` and `app_pl.arb`), no styling in screens, no emojis.
- Never commit or push autonomously: each task ends with a proposed Conventional Commit message for the owner.
- Branch stays `feat/25-stats-screens`.
- Boundary data is ODbL (OpenStreetMap via Overture): the app shows "© OpenStreetMap contributors, Overture Maps Foundation" wherever boundaries are used, and the build script is committed so the derived database can be reproduced.
- Frontend checks from `globetrottr_front/`: `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, `flutter test`. A `.env` file must exist (copy `.env.example`), otherwise analyze reports a missing asset and the whole test run fails to build.
- `ROADMAP.md` must reflect every change (Task 12).

## Decisions (defaults assumed by the tasks; owner may flip them)

- **D1 Boundary source:** Overture Maps `divisions` (`division_area` polygons with a parent hierarchy, worldwide, ODbL). Rejected: Natural Earth (countries and states only, coarse), geoBoundaries (city levels incomplete, license differs per country), GADM (no redistribution), raw OSM extracts (same data as Overture, much more processing).
- **D2 Distribution (owner: plug and play, files in the repo if possible):** all boundaries are app assets committed to the repo: a base DB (countries, states, counties) and one file per country (cities, districts). A country file is copied to local storage the first time the user records there, so only visited countries take disk space twice. Limits that decide it: Google Play's base module may be at most 200 MB compressed, and GitHub blocks files over 100 MB (warns over 50 MB). Budget: base DB + all country files at most 130 MB compressed, no file over 50 MB. If the measured size (Task 3, Step 1) exceeds it, shrink first (tolerance, delta-encoded coordinates, dropping cities without polygons); if still over, the owner chooses between a Play install-time asset pack (still no download code in the app, up to 1.5 GB, but missing from `flutter run` builds) and GitHub Releases downloads. Cost: every regeneration of the data adds its full size to the git history.
- **D3 Border tiles (changes a recorded roadmap decision):** a tile whose centre and four corners fall in one leaf region goes to it whole, as today; any other tile is split into 16 x 16-pixel cells (about 50 m) attributed by cell centre. Why: a z15 tile is about 0.8 km wide in Poland, so whole-tile attribution would blur accurate borders by hundreds of metres and make small cities and districts meaningless.
- **D4 Styling cleanup** of the statistics feature (Task 10). `AGENTS.md` requires the owner's permission. Default: do it.
- **D5** With "New streets" gone, the quests tile spans the full width of the second row.
- **D6 Location change** (Task 11): remove `forceLocationManager: true`; keep saving fixes after a stream error. See finding 12.

## Review Focus

- A border tile between two cities: the split must follow the polygons to cell size, and the sum over regions must equal the tile's new area (Task 6).
- The first recording in a new country: its cities are copied in and counted from the first flush, without double counting the country, state and county (Tasks 4, 6).
- A history from the 100,000 km journey generator: startup must not read tile blobs or rebuild statistics; a rebuild resolves each leaf once and decodes only border tiles (Tasks 5, 6).
- Day boundaries: a recording across midnight, the app kept in the background for days, week navigation across DST, ISO week 1 / 53 (Tasks 2, 8).
- Switching the app language with a statistics screen open: labels, dates, plurals and region names follow the new locale (Tasks 2, 7).

## Findings (review of `dev...feat/25-stats-screens`)

Verified: frontend analyze clean (with `.env`), format clean, 719 tests pass, 4 skipped. Backend spotless and compile pass; 32 of 35 tests pass, the 3 Testcontainers tests could not reach Docker in the review environment. Not run on a phone.

High:
1. Every app start rebuilds all region statistics: `_replay` in `fog_provider.dart` ends with `backfillStatsIfEmpty(store, true)`; `force` skips the `stats_backfilled` flag, and `loadBaseTilesWithArea` reads every z15 tile blob on the main isolate and fires unawaited updates.
2. Inconsistent attribution in `statistics_tracker.dart`: the first time a tile is seen, its area goes to every region whose shape contains its centre; afterwards to the cached leaf's ancestor chain.
3. Boundary data is not accurate: countries are Natural Earth 1:50m simplified to about 500 m, states 1:10m simplified to about 300 m, Polish gminas are copied from an earlier DB (the build script reads `/tmp/regions_world_git.db`, so it cannot be rerun), Kraków's 18 districts are hand-typed rectangles, 7,318 cities outside Poland are 0.2 degree squares with a fixed 150/300 km2 area, and there are no counties (the mock-up's Region screen lists powiats).
4. Whole-tile attribution by tile centre (see D3).
5. Stubs shown as data: New streets (always 0), Distance by activity (every trip saved as `walk`), Highest (altitude never passed), Furthest (never written), Most visited (counts flush batches per region, not places), Region Streets (hardcoded 0) and Highest (falls back to the global record), City Streets (0), Routes (= flush batch count), Most visited (= the city's own name), Time spent (never written), and generic illustrations instead of the mock-up's country and city maps.
6. Providers are not read-only: `StatsOverviewNotifier._loadStatsFor` triggers a fog backfill when the selected period is empty.

Medium:
7. Localization: providers build Polish/English strings with `isPolish` ternaries; `city_detail_screen.dart` hardcodes `'· miasto'`; no ICU plurals; `statsSubregionsCount` always says "counties"; error states print `err.toString()`; the week label uses the Monday's year instead of the ISO week-year; region names are not localized (the mock-up shows "Czechy", "Praga", "Bratysławski" in Polish).
8. Router: `int.tryParse(...) ?? 1` opens Poland for an invalid id; duplicate top-level `/statistics` route.
9. Countries / Region / City vs mock-up: flag falls back to `'PL'`; with no discovered child every child is listed; lists include 0% rows sorted by name; the subregion header is picked by magic id ranges; every subregion opens the city screen; no state -> cities nesting in the accordion; the country subtitle ignores `statsCountryCardSubtitle`; the overview city list is unbounded (mock: top 3).
10. The quests tile counts all completed quests, ignoring the period; `dev` already has `Quest.completedAt`.
11. Streaks work in the common case but miss days: the app-open day is counted only on a cold start, so resuming an app that stayed in the background (likely with the recording foreground service) does not count; the recording day is counted only when a recording is stopped, so a recording cut by the app being killed never counts and one across midnight counts only the stop day; the recording rule "100 m or new area" ignores area because `recordTripSession` always passes `newAreaM2: 0`; an app-open update does not refresh a statistics screen that is already loaded.
12. Location changes unrelated to statistics, from commit `7926ddd` "fixed the stats":
    - `forceLocationManager: true` makes Android use the old `LocationManager` instead of Google Play's fused location provider. The fused provider combines GPS, Wi-Fi and cell data; without it the first fix is slower, there is no fix indoors, and battery use is usually higher. It helps only on phones without Google Play services. No reason was given and it was not checked on a phone, yet it changes how every Android user's route is recorded.
    - The new `onError` in `LocationService.followPositions` cancels the subscription that saves fixes after any stream error (for example location switched off for a moment). The notifier keeps listening, so the marker still moves and the app still shows "recording", but nothing is saved to the track log or the fog until the user stops and starts again.
13. Regions DB: the 12 MB asset is loaded into memory on every start to compare its length; no version, so `fog_tile_regions` and region stats survive a DB change; `RegionDatabaseSeeder` seeds hardcoded box-only regions if the copy fails.
14. `SyncService` holds a `Ref` and a statistics failure is caught but couples sync to statistics code. The backend-side sync problems (name matching, unused `regionId`, `code` never filled, case-insensitive lookups that can throw) are the separate backend issue.
15. Design system (D4): about 50 `fontSize`/`fontWeight` overrides in statistics screens and widgets (other Neo screens have none), the back + title + subtitle header copied into four screens, an own `BoxShadow` in `country_flag_chip.dart`.
16. The branch is about 20 commits behind `dev` (quests port, newer mock-up).
17. `ROADMAP.md` disagrees with the code: "~55 MB" (asset is 12 MB), R-Tree (code uses B-tree), counties (none), street tracking (not implemented), "under 200 ms" (not measured), the seeder.

---

### Task 0: Bring the branch up to date with `dev`

**Files:** whatever conflicts; expected `lib/core/router/app_router.dart`, `lib/l10n/app_*.arb` and generated `app_localizations*.dart`, `ROADMAP.md`.

- [ ] **Step 1:** `git merge dev` on `feat/25-stats-screens` (the owner approves the merge commit). Resolve conflicts keeping both sides; regenerate l10n with `flutter gen-l10n`.
- [ ] **Step 2:** Run the frontend checks. Expected: same results as in Findings.
- [ ] **Step 3:** Propose: `chore(stats): merge dev into feat/25-stats-screens`.

### Task 1: Remove stubbed statistics UI

**Files:**
- Modify: `lib/features/statistics/screens/stats_screen.dart`, `region_detail_screen.dart`, `city_detail_screen.dart`, `countries_screen.dart`
- Modify: `lib/features/statistics/provider/statistics_overview_provider.dart`, `region_detail_provider.dart`, `screens/widgets/stats_records_grid.dart`
- Delete: `screens/widgets/stats_activity_section.dart`, `screens/widgets/stats_most_visited_card.dart`
- Modify: both `.arb` files (drop keys that become unused: `statsNewStreets`, `statsDistanceByActivity`, `statsActivityWalk/Bike/Run/Other`, `statsRecordFurthest`, `statsMostVisitedTitle`, `statsNoVisitedPlaces`, `statsMetricStreets`, `statsMetricRoutes`, `statsTimeSpent`, and `statsRecordHighest` if nothing uses it)
- Test: `test/features/statistics/screens/stats_screens_test.dart`

**Interfaces:**
- Produces: `StatsOverviewState` without `newStreetsCount`, `activities`, `mostVisitedPlaces`; `RecordTileItem` only for `StatsRecordType.longestRoute` and `.bestDay`; `RegionDetailData` without `streetsCount`, `highestPoint`; `CityDetailData` without `streetsCount`, `routesCount`, `mostVisitedPlace`, `timeSpent`.

- [ ] **Step 1: Write failing widget tests** (English l10n via `lookupAppLocalizations(const Locale('en'))`):
  - `stats screen shows only measured sections`: `statsNewStreets`, `statsDistanceByActivity`, `statsMostVisitedTitle`, `statsRecordHighest`, `statsRecordFurthest` find nothing; `statsRecordLongestRoute`, `statsRecordBestDay`, `statsQuests`, `statsWeeklyNewArea`, `statsStreaksTitle` find one widget each.
  - `region screen hides streets and highest point`: `statsMetricStreets` and `statsRecordHighest` find nothing; `statsMetricCities` finds one.
  - `city screen hides unmeasured metrics`: `statsMetricStreets`, `statsMetricRoutes`, `statsMostVisitedTitle`, `statsTimeSpent` find nothing; `find.byType(AppIllustration)` finds nothing.
  - `countries screen has no placeholder illustration`: `find.byType(AppIllustration)` finds nothing.
- [ ] **Step 2:** `flutter test test/features/statistics/screens/stats_screens_test.dart` -> the four tests FAIL.
- [ ] **Step 3:** Remove the sections, fields, widgets and keys listed above. The second metrics row holds only the quests tile at full width (D5); the city metrics row keeps "Discovered" only. Leave the `stats.db` schema untouched.
- [ ] **Step 4:** Run the file, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `fix(stats): hide statistics the app does not record yet`.

### Task 2: Period logic out of the provider, localization in widgets

**Files:**
- Create: `lib/features/statistics/logic/stats_period.dart` (move `StatsPeriod` here from `stats_period_tabs.dart`)
- Modify: `statistics_overview_provider.dart`, `region_detail_provider.dart`, `stats_screen.dart`, `city_detail_screen.dart`, `region_detail_screen.dart`, `countries_screen.dart`, `stats_weekly_chart.dart`, `stats_records_grid.dart`, `stats_date_navigator.dart`, both `.arb` files
- Test: create `test/features/statistics/logic/stats_period_test.dart`; extend `stats_screens_test.dart`

**Interfaces:**
- Produces:
  - `enum StatsPeriod { week, month, year, allTime }`
  - `({int week, int year}) isoWeekOf(DateTime date)`
  - `class StatsPeriodRange { final StatsPeriod period; final DateTime start; final DateTime end; }` (local midnight, `end` inclusive, value equality: Task 7 uses it as a provider family key)
  - `StatsPeriodRange statsPeriodRange(StatsPeriod period, DateTime anchor)`
  - `DateTime shiftStatsPeriod(StatsPeriod period, DateTime anchor, int steps)` (calendar arithmetic `DateTime(y, m, d + 7 * steps)` etc., never `Duration`)
  - `StatsOverviewState.range` replaces `periodLabel`; `WeeklyBarItem` carries `int isoWeek` and `bool isCurrent`; `RecordTileItem` carries `StatsRecordType type`, `double value`, `DateTime? date`, `String? label`; region and city data carry `DateTime? firstVisit`, `DateTime? lastVisit`.
  - New ARB keys (en/pl): `statsWeekLabel(int week, int year)` "Week {week} · {year}" / "Tydzień {week} · {year}"; `statsVisitYesterday`; `statsCitySubtitle(String region)` "{region} · city" / "{region} · miasto"; `statsCountiesCount`, `statsCitiesCount`, `statsDistrictsCount` (`int discovered`, `int total`, plural on `total`). `statsCountriesSummary` and `statsCountryCardSubtitle` become ICU plurals.

- [ ] **Step 1: Write failing unit tests** in `stats_period_test.dart`:
  - `isoWeekOf(DateTime(2025, 12, 29))` == `(week: 1, year: 2026)`; `isoWeekOf(DateTime(2027, 1, 1))` == `(week: 53, year: 2026)`.
  - `statsPeriodRange(StatsPeriod.month, DateTime(2026, 2, 15))` -> start `DateTime(2026, 2, 1)`, end `DateTime(2026, 2, 28)`.
  - `statsPeriodRange(StatsPeriod.week, DateTime(2026, 11, 4, 18))` -> start `DateTime(2026, 11, 2)`, end `DateTime(2026, 11, 8)`.
  - `shiftStatsPeriod(StatsPeriod.week, DateTime(2026, 3, 30, 0, 30), -1)` has year/month/day `2026, 3, 23`.
- [ ] **Step 2: Write failing widget/l10n tests:**
  - Polish, month anchored at `DateTime(2026, 10, 10)` shows `Październik 2026`; week anchored at `DateTime(2025, 12, 29)` shows `Tydzień 1 · 2026`.
  - `lookupAppLocalizations(const Locale('pl')).statsCountryCardSubtitle('11,6 km²', n)` gives `11,6 km² · 1 miasto`, `· 2 miasta`, `· 9 miast` for n = 1, 2, 9.
  - City screen in English shows `Małopolskie · city`.
- [ ] **Step 3:** Run both files -> FAIL.
- [ ] **Step 4:** Implement `stats_period.dart`; providers return data only and stop reading `localeProvider` or `WidgetsBinding` (remove every `isPolish`, month list and literal label). Widgets format: month with `DateFormat('LLLL y', locale)` and an upper-cased first letter, year as a number, all-time with `statsPeriodAllTime`, current week bar with `statsCurrentWeek`, record headers by `StatsRecordType`, visit dates as today (`statsLastVisitToday`) / yesterday (`statsVisitYesterday`) / `DateFormat.yMMMMd(locale)`, best day `DateFormat.MMMd(locale)`. Error states show `l10n.error`.
- [ ] **Step 5:** Run the files, then the full frontend checks -> PASS.
- [ ] **Step 6:** Propose: `fix(stats): localize period, record and visit labels in widgets`.

### Task 3: Worldwide boundary build

**Files:**
- Create: `tool/regions/build_regions.py`, `tool/regions/requirements.txt` (`duckdb`, `shapely`), `tool/regions/README.md` (how to run, Overture release used, license)
- Delete: `tool/build_regions_db.py`, `tool/build_accurate_regions_db.py`
- Output (committed): `globetrottr_front/assets/data/regions_world.db` (countries, states, counties), `globetrottr_front/assets/data/regions/regions_<ISO2>.db` (cities, districts) and `globetrottr_front/assets/data/regions/index.json`

**Interfaces:**
- Produces, in every DB, table `regions(id INTEGER PRIMARY KEY, parent_id INTEGER, source_id TEXT, name TEXT NOT NULL, name_en TEXT, name_pl TEXT, type TEXT NOT NULL, code TEXT, total_area_km2 REAL NOT NULL, min_lat REAL, max_lat REAL, min_lon REAL, max_lon REAL, geometry BLOB NOT NULL)` with the current indexes, `PRAGMA user_version = 2`.
- Geometry format v2: `uint32` ring count, per ring `uint32` point count then `float32` lon/lat pairs (v1 used `uint16`, too small for detailed coasts).
- `assets/data/regions/index.json`: `{"version": 2, "release": "<overture release>", "packs": [{"country": "PL", "file": "regions_PL.db", "bytes": 0}]}`.
- Type mapping: Overture `country` -> `country`, `region` -> `state`, `county` -> `county`; `city` is the finest level that covers the country without gaps (`locality` areas, else `localadmin`); `district` = `borough`/`macrohood` areas inside a city. Ids are unique across the base DB and all packs (packs use ranges per country). `name` = local name, `name_en`/`name_pl` from Overture translations. Areas from geodesic polygon area minus holes. Simplification tolerance 0.0003 degrees (about 30 m).

- [ ] **Step 1 (spike):** Run the script for PL, CZ, DE, FR, US and the full base DB, then extrapolate all countries from the per-country row counts. Record in `tool/regions/README.md`: rows per type, raw and zip-compressed sizes. Acceptance for Poland: 16 states, 380 counties, 2,477 cities, Kraków with 18 districts; every country has at least one state. Check the D2 budget; if it is exceeded after shrinking, stop and report to the owner.
- [ ] **Step 2: Write `tool/regions/test_build_regions.py`** (pytest): `encode_geometry` -> `decode_geometry` round trip for a ring of 70,000 points; children's summed area within 2% of the parent for Poland's states and Kraków's districts; no `regions` row without geometry; every `parent_id` exists in the same DB or the base DB.
- [ ] **Step 3:** `pytest tool/regions` -> PASS.
- [ ] **Step 4:** Propose: `feat(regions): build worldwide boundaries from Overture divisions`.

### Task 4: Regions DB and country packs in the app

**Files:**
- Create: `lib/features/regions/data/regions_db_version.dart`, `lib/features/regions/data/region_pack_service.dart`, `lib/features/regions/data/region_geometry.dart` (v2 decoder and point-in-polygon, moved out of `region.dart`)
- Modify: `region.dart`, `sqflite_region_storage.dart`, `region_storage.dart`, `lib/features/statistics/provider/statistics_providers.dart`, `lib/features/fog/provider/fog_provider.dart`, `pubspec.yaml` (asset folder `assets/data/regions/`)
- Delete: `lib/features/regions/data/region_database_seeder.dart`
- Test: `test/features/regions/data/region_storage_test.dart`, `regions_world_db_test.dart`, create `region_pack_service_test.dart`, `region_geometry_test.dart`

**Interfaces:**
- Consumes: DB schema, geometry v2 and index format from Task 3.
- Produces:
  - `const int kBundledRegionsDbVersion = 2;`
  - `SqfliteRegionStorage({String? path, Future<ByteData> Function()? loadAsset, int bundledVersion = kBundledRegionsDbVersion})` (no `autoSeed`); copies the asset only when the local file is missing or its `user_version` differs.
  - `Future<bool> RegionStorage.consumeVersionChange()` (true once after the bundled DB replaced an older copy); `Future<Set<String>> RegionStorage.installedPacks()`; `Future<void> RegionStorage.installPack(String country, int version, String packPath)` (copies rows in one transaction, records `installed_packs(country, version)`).
  - `String Region.localizedName(String languageCode)` (`name_pl`/`name_en`, else `name`).
  - `RegionPackService({required RegionStorage storage, Future<ByteData> Function(String assetPath)? loadAsset})` with `Future<bool> ensurePack(String countryCode)`: copies `assets/data/regions/regions_<code>.db` from the app bundle and installs it; true when installed now, false when already installed at the bundled version or the country has no file (never throws).
  - On a version change or a new pack, `FogNotifier` runs `clearRegionStats()` then `backfillStatsIfEmpty(force: true)`.

- [ ] **Step 1: Write failing tests:**
  - geometry: v2 blob with a 70,000-point ring decodes; a point inside a hole is outside.
  - storage: `bundled DB replaces an older copy` (file at `user_version` 1, bundled 2 -> replaced, `consumeVersionChange()` true then false); `current copy is not reloaded` (`loadAsset` called 0 times); `installed pack regions are found by point`.
  - pack service with a fake asset loader: `ensurePack('PL')` true and Kraków found by point; a second call loads nothing and returns false; a country without a file -> false; a pack whose version changed in `index.json` is reinstalled.
  - bundled asset: `PRAGMA user_version` == `kBundledRegionsDbVersion`; contains Poland's 16 states and 380 counties.
  - `Region.localizedName('pl')` for Czechia is `Czechy`.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement. Show the ODbL attribution string (new key `regionsAttribution`) under the Countries screen and the Region and City screens.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `feat(regions): bundle world boundaries with a city file per country`.

### Task 5: Cheap startup and read-only providers

**Files:**
- Modify: `lib/features/fog/data/fog_tile_storage.dart`, `sqflite_fog_tile_storage.dart`, `test/support/in_memory_fog_tile_storage.dart`, `lib/features/fog/provider/fog_provider.dart`, `statistics_overview_provider.dart`
- Test: `test/features/fog/data/fog_tile_storage_test.dart`, `test/features/fog/provider/fog_notifier_test.dart`, `stats_screens_test.dart`

**Interfaces:**
- Produces: `typedef FogTileArea = ({FogTileId id, double areaM2});` and `Future<List<FogTileArea>> FogTileStorage.loadBaseTileAreas()` replacing `loadBaseTilesWithArea()` (selects `z, x, y, area` where `z = FogConfig.baseZoom AND area > 0`; no blobs, no decoding, no writes). `Future<void> FogNotifier.backfillStatsIfEmpty({bool force = false})`.

- [ ] **Step 1: Write failing tests:**
  - storage: `loadBaseTileAreas returns only base tiles with area` — tiles at z15 with area 0 and 50, one at z14 -> one result with 50.
  - fog provider: `startup does not rebuild statistics once backfilled` — with `stats_backfilled` set, opening the fog twice makes zero `rebuildFromFogTiles` calls on a fake tracker.
  - overview: `overview loads empty stats without touching the fog` — empty fakes, no override for `fogTileStorageProvider`/`fogProvider` -> `AsyncData` with zero area.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement; `_replay` calls `backfillStatsIfEmpty()` without force; the developer `rebuild()` keeps `force: true`; remove the backfill block and fog imports from the overview provider.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `perf(stats): stop rebuilding statistics on every start`.

### Task 6: One attribution path, border tiles split into cells

**Files:**
- Modify: `lib/features/statistics/logic/statistics_tracker.dart`, `lib/features/fog/data/store/fog_tile_writer.dart`, `fog_store_models.dart`, the fog tile cache entry (`lib/features/fog/data/store/`), `lib/features/statistics/data/statistics_storage.dart`, `sqflite_statistics_storage.dart`, `lib/features/fog/provider/fog_provider.dart`
- Test: `test/features/statistics/logic/statistics_tracker_test.dart`, `test/features/fog/data/fog_tile_writer_test.dart`, `test/features/statistics/data/statistics_storage_test.dart`

**Interfaces:**
- Consumes: `RegionStorage`, `RegionPackService.ensurePack` (Task 4), `FogTileStorage.loadBaseTileAreas()` (Task 5) and the existing `FogTileStorage.loadTiles(ids)` for border tiles.
- Produces:
  - `class FogCellAreas` wrapping a `Float32List(256)`: m2 per 16 x 16-pixel cell of a z15 tile, row-major.
  - `FogChange.areaDeltas` and `FogWriteResult.areaDeltas` become `Map<FogTileId, FogCellAreas>` (new cell areas minus the cache entry's previous cell areas; the cache entry keeps its cell areas next to `areaM2`).
  - `TileAreaDelta({required FogTileId id, required FogCellAreas cells})`.
  - `StatisticsTracker({..., void Function(String countryCode)? onMissingPack})`.
  - `StatisticsStorage.replaceRegionStats(Iterable<UserRegionStats> stats)` (one transaction: delete all rows, insert `stats`).

- [ ] **Step 1: Write failing tests:**
  - writer: a stroke crossing one tile -> the cell deltas sum to the tile's area delta; a second identical stroke -> all cells 0.
  - tracker: `interior tile goes to one leaf` — centre and corners in leaf L (L -> state S -> country C) -> L, S and C each get the whole delta; one point lookup per corner and centre, none per cell.
  - tracker: `border tile is split by cell` — left half of the tile in city A, right half in city B, coverage only in the left half -> A gets all of it, B has no row; both share state S, which gets the full delta.
  - tracker: `first and cached commits credit the same regions` — two commits of one tile, 100 m2 each, with an unrelated region X whose shape also contains the centre -> L, S, C have 200 m2, X has no row.
  - tracker: `rebuild replaces region stats` — a row for region Z not reached by any tile is gone; `firstVisitMs`/`lastVisitMs` of regions still reached are kept.
  - tracker: `rebuild resolves each leaf once` — 1,000 interior tiles of one leaf -> one `getAncestorChain` call.
  - tracker: `missing pack is requested once per country` — tiles in a country without an installed pack call `onMissingPack('CZ')` once and credit the country, state and county.
  - tracker: `tiles outside every region still count as daily new area`.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement: a private `_hierarchyFor(lat, lon, memo)` (smallest region at the point, then `getAncestorChain`, memoized by leaf id) used by live commits and rebuilds; interior check on the centre and four corners; cell split otherwise. Rebuilds decode masks only for border tiles, in an isolate. Wire `onMissingPack` to `RegionPackService.ensurePack` in `statistics_providers.dart`.
- [ ] **Step 4:** Run, then the full frontend checks and `FOG_BENCH=1 flutter test test/benchmark/fog_benchmark_test.dart` (no regression of flush time beyond 10%).
- [ ] **Step 5:** Propose: `fix(stats): attribute fog area to regions by cell at borders`.

### Task 7: Countries, Region and City as in the mock-up

**Files:**
- Modify: `region_detail_provider.dart`, `statistics_overview_provider.dart`, `countries_screen.dart`, `region_detail_screen.dart`, `city_detail_screen.dart`, `stats_screen.dart`, `widgets/country_accordion_card.dart`, `widgets/country_flag_chip.dart`, `lib/core/router/app_router.dart`
- Create: `lib/features/statistics/screens/stats_routes.dart`
- Test: create `test/features/statistics/provider/region_detail_provider_test.dart`, `test/features/statistics/provider/statistics_overview_provider_test.dart`; extend `stats_screens_test.dart`

**Interfaces:**
- Consumes: `StatsPeriodRange` (Task 2), `Region.localizedName` and counties (Task 4), `Quest.completedAt` (Task 0).
- Produces:
  - `class CountryGroupData { final String? countryCode; final String countryName; final double areaKm2; final int citiesCount; final List<StateGroupData> states; }`
  - `class StateGroupData { final int id; final String name; final List<SubregionItem> cities; }` (cities found through the county level)
  - `RegionDetailData.subregionKind` (`RegionType?`) picks the header and the count key; for a state, each county row has the names of its discovered cities as subtitle (mock: "krakowski · Zabierzów, Skawina").
  - `String? statsRouteFor(RegionType type, int id)`: state/county -> `/profile/statistics/region/$id`, city -> `/profile/statistics/city/$id`, otherwise `null`.
  - `completedQuestsInPeriodProvider` (`Provider.family<int, StatsPeriodRange>`) counting quests with `completedAt` inside the range.

- [ ] **Step 1: Write failing tests:**
  - countries: Poland 11.6 km2 and Czechia 0.5 km2 -> Poland first; Poland's group has Małopolskie with Kraków (7.3%) before Skawina (1.0%); a country without a code has `countryCode == null`; undiscovered states are absent; Polish locale shows `Czechy`.
  - region detail: Małopolskie lists counties sorted by percentage descending, a county with 0 m2 is absent, `krakowski` has subtitle `Zabierzów, Skawina`, header count says `4 z 22 powiatów`; Kraków's children give `subregionKind == RegionType.district`.
  - routes: `statsRouteFor(RegionType.county, 7)` == `/profile/statistics/region/7`; `statsRouteFor(RegionType.district, 9)` is null.
  - overview: five discovered cities -> `discoveredCities.length == 3`; two quests completed in October and one in September -> October 2026 shows 2.
  - router: `/profile/statistics/region/abc` shows `errorNotFound`; `/statistics` is not a route.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement; country subtitle through `statsCountryCardSubtitle(formatKm2(...), citiesCount)`; `CountryFlagChip` takes `String?` and draws a neutral chip for null; remove the id-range header logic.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `feat(stats): match countries, region and city screens to the mock-up`.

### Task 8: Streaks count every day the app is used

**Files:**
- Modify: `lib/main.dart`, `lib/features/statistics/provider/statistics_providers.dart`, `lib/features/statistics/logic/statistics_tracker.dart`, `lib/features/map/provider/map_stats_provider.dart`
- Test: `test/features/statistics/logic/statistics_tracker_test.dart`, `test/features/statistics/logic/streak_service_test.dart`, `test/features/map/provider/map_stats_provider_test.dart`, create `test/features/statistics/provider/streak_stats_provider_test.dart`

**Interfaces:**
- Produces: `Future<void> StreakStatsNotifier.recordAppOpen({DateTime? now})` (bumps `statisticsRevisionProvider` when the stored streak changed); `Future<void> StatisticsTracker.recordRecordingDay({DateTime? now})`; `recordTripSession` no longer touches streaks.

- [ ] **Step 1: Write failing tests:**
  - provider: opens at `DateTime(2026, 11, 3, 9)` and `DateTime(2026, 11, 4, 9)` -> `currentOpenStreak == 2`; a second open the same day does not bump the revision.
  - app: after `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)`, `recordAppOpen` was called (fake notifier counts calls).
  - map stats: while recording, two logged points 150 m apart -> `recordRecordingDay` called once, before recording stops; a recording that only reveals new area (0 m distance, 500 m2) also calls it.
  - map stats: a recording running from 23:50 to 00:20 calls `recordRecordingDay` for both days once qualifying distance accrues after midnight.
  - tracker: `recordRecordingDay` on consecutive days gives `currentRecordingStreak == 2`; on the same day twice gives 1.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement: `_MyAppState` adds an `AppLifecycleListener(onResume: ...)` next to the post-frame call; `SessionNewAreaNotifier` tracks distance and area per calendar day and calls `recordRecordingDay` when either passes `StreakService.minDistanceForRecordingStreak` / `minAreaForRecordingStreak`; remove the streak update from `recordTripSession`.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `fix(stats): count streak days on resume and during recording`.

### Task 9: Statistics payload out of `SyncService` (frontend only)

**Files:**
- Create: `lib/features/statistics/logic/statistics_sync_payload.dart`
- Modify: `lib/features/map/data/sync_service.dart`
- Test: create `test/features/statistics/logic/statistics_sync_payload_test.dart`; the existing sync service test

**Interfaces:**
- Produces: `class StatisticsSyncPayloadBuilder { StatisticsSyncPayloadBuilder({required StatisticsStorage statistics, required RegionStorage regions, required double Function() totalAreaM2}); Future<Map<String, Object?>> build(); }` producing exactly today's keys and values (`totalDiscoveredKm2`, `visitedCountriesCount`, `currentStreak`, `appStreak`, `regions` with `regionId`, `regionName`, `regionCode`, `discoveredAreaKm2`, `discoveryPercentage`). `SyncService(ApiClient client, MapStorage storage, {StatisticsSyncPayloadBuilder? statistics})`.

- [ ] **Step 1: Write failing tests:** builder output equals a recorded payload for a fixed set of stats (backend contract unchanged); a builder that throws -> points are still posted without `statistics` and the outbox is emptied up to the last id.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Implement; the provider wires the builder with `fogProvider`'s `store.totalAreaM2`.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `refactor(sync): build the statistics payload outside the sync service`.

### Task 10: Statistics styling through the design system (needs D4 approval)

**Files:**
- Create: `lib/features/statistics/screens/widgets/stats_screen_header.dart`
- Modify: the four statistics screens, the widgets under `lib/features/statistics/screens/widgets/`, `lib/core/theme/app_typography.dart` (only if no existing token matches)

**Interfaces:**
- Produces: `StatsScreenHeader({required String title, String? subtitle})` (back button, title, subtitle).

- [ ] **Step 1:** Replace the header block in the four screens with `StatsScreenHeader`; replace every `fontSize`/`fontWeight` override with an existing `AppTypography` token, adding a token only where none matches; replace the own `BoxShadow` in `country_flag_chip.dart` with `context.shadows`.
- [ ] **Step 2:** `rg -n "fontSize:|fontWeight:|BoxShadow\(" lib/features/statistics` -> no matches; full frontend checks -> PASS.
- [ ] **Step 3:** Propose: `refactor(stats): style statistics through theme tokens and one header`.

### Task 11: Location: fused provider again, keep saving after errors (D6)

**Files:** `lib/features/map/data/location_service.dart`, `lib/features/map/provider/location_notifier.dart`, `test/features/map/data/location_service_test.dart`

- [ ] **Step 1: Replace the branch's test** `resets the stream reference when the position stream errors` with a failing `keeps saving fixes after a stream error`: while recording, add a fix, an error, then another fix -> both fixes are in the track log and `hasStream` stays true.
- [ ] **Step 2:** Run -> FAIL.
- [ ] **Step 3:** Remove `forceLocationManager: true`; the service's `onError` only logs; the notifier's `onError` sets `errorMessage` without changing `isTracking`.
- [ ] **Step 4:** Run, then the full frontend checks -> PASS.
- [ ] **Step 5:** Propose: `fix(map): keep recording after a location error and use the fused provider`.

### Task 12: Roadmap and final verification

**Files:** `ROADMAP.md`

- [ ] **Step 1:** Rewrite the "Statistics & administrative boundaries" section to the roadmap rules (one to three lines per decision, no class names): what is Done, decisions D1-D3 and D6 with reasons and rejected options (D3 replaces "tiles map to regions by tile centroid"), and Planned items for what Task 1 hid: street counts, activity types, altitude and furthest records, most visited places, time spent, country and city maps. Remove the inaccurate claims of finding 17. Add the backend statistics sync as a separate Planned item.
- [ ] **Step 2:** Full frontend checks -> PASS.
- [ ] **Step 3:** On a phone: record a walk across a city border, stop, open Profile -> Statistics; check new area, distance, weekly bar, streaks, countries banner, a city row -> City screen, back -> Countries -> state -> Region with counties; switch language; turn location off and on during a recording and confirm the route continues; restart and confirm the app opens without a visible delay; record in a second country (flight mode on) and confirm its cities appear.
- [ ] **Step 4:** Propose: `docs(roadmap): record client-side statistics scope and decisions`.
