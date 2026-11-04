# Review handoff: `feat/25-stats-screens`

Open findings of the whole-branch review of the client-side statistics work, for the next reviewer. Two findings are already fixed (see "Fixed after the review"); everything else below is still open.

## Context

- Branch `feat/25-stats-screens`, head `a25b784`, compared with `dev` (merge base `e139d25`). Nothing is pushed.
- Plan: `docs/superpowers/plans/2026-11-04-stats-client-side-review.md` (Decisions D1-D6, Review Focus, Findings, Tasks 0-12).
- Spec: `ROADMAP.md` section "Statistics & administrative boundaries", the mock-up `globetrotttr-neo-neumorphic.html` on `dev` (screens `Neo · Statystyki`, `Neo · Kraje`, `Neo · Region`, `Neo · Miasto`), rules in `AGENTS.md`.
- Boundary data: `tool/regions/` (build script, tests, README). Shipped assets: `globetrottr_front/assets/data/regions_world.db` (31 MB: countries, states, counties of the world) and `assets/data/regions/` (230 country files, 130 MB: cities and districts), Overture Maps release 2026-10-21.0, compact profile (city borders within about 150 m), geometry format v2 (zigzag varint deltas, 1e-5 degree).
- Backend untouched (owner: the statistics sync on the backend is a separate issue).

## Verification so far

- Frontend at `3f66943`: `flutter analyze` clean, `dart format` clean, `flutter test` 855 passed, 4 skipped. After the two fix commits only the region and tracker suites were rerun (73 passed); the full suite was not rerun.
- `tool/regions`: `pytest` 32 passed (includes Poland 16 voivodeships, 380 powiats, 2,479 gminas, Kraków with 18 districts).
- Fog benchmark (`FOG_BENCH=1`): live apply 717 -> 613 us/point, 50k-point import 6.57 -> 6.89 s (+4.8%), cold start 17 -> 15 ms.
- Not checked: a real phone (recording, pack install, first launch copying the 31 MB asset, location errors); the backend tests (Testcontainers needs Docker).

## Fixed after the review

| # | Finding | Commit | Test |
| --- | --- | --- | --- |
| 1 (Critical) | The leaf region was the smallest by area, so cities with county rights (same area as their county) and coastal cities (boundary includes water, larger than their county) were never credited: Kielce, Sopot, Koszalin, Gdańsk... | `3726751`: candidates ordered by level (district, city, county, state, country), then area | `regions_world_db_test.dart` "Kielce / Sopot / Gdańsk is found as a city", `statistics_tracker_test.dart` "a city as large as its county is the leaf" |
| 6 (Important) | Concurrent first callers each copied the 31 MB asset; a copy cut short kept `user_version` 2 in its header and was never replaced | `a25b784`: one shared open future, copy to `.tmp` then rename, stale `-journal` removed | `region_storage_test.dart` "concurrent first reads copy the bundled DB once" |

## Open findings

### Important

**2. Installing a country file wipes all region statistics outside the tracker queue.**
- Where: `lib/features/fog/provider/fog_provider.dart:137` (pack install) and `:154` (boundary version change) call `clearRegionStats()`, which deletes `user_region_stats`, `fog_tile_regions` and `stats_backfilled`, before the forced rebuild is queued.
- Failure:
  - (a) First and last visit dates of every region are lost each time the user records in a new country (the rebuild's "keep visit dates" reads an empty table; the next flush sets first visit to today).
  - (b) Statistics screens show only what was flushed after the clear until the rebuild finishes (minutes on large histories).
  - (c) If the app is killed during that rebuild after one live flush, the next start sees `hasAreaStats` (`fog_provider.dart:172`) and marks the statistics backfilled: the history is permanently reduced to those rows.
- Tests encode the current behaviour: `test/features/fog/provider/fog_notifier_test.dart` asserts `clears == 1`.
- Suggested fix: for packs, invalidate only the tile cache, inside the tracker queue, and let `replaceRegionStats` swap atomically; persist a "rebuild pending" record set before and cleared after the replace; force a rebuild at startup while it is set.

**3. The boundary-version change is remembered only in memory.**
- Where: `lib/features/regions/data/sqflite_region_storage.dart:40` (`_versionChanged`), consumed in `fog_provider.dart` `_refreshStatistics` after the replay.
- Failure: killed between the asset copy (can happen at launch through the map pill) and `_refreshStatistics` (after a replay that can take minutes), the next start sees a current DB; statistics rows and the tile cache keep old region ids that point at different regions in the new DB, permanently.
- Suggested fix: store in `stats.db` the regions version the statistics were built from and compare it with `kBundledRegionsDbVersion` at startup (rebuild without carrying visit dates, since ids changed).

**4. Rebuilds are much more expensive than "each leaf once" suggests.**
- Where: `lib/features/statistics/logic/statistics_tracker.dart:260` (`_candidates`) uses `findRegionsInBBox`, which returns `SELECT r.*` with geometry blobs (`sqflite_region_storage.dart:209, 233`); every tile also does a separate `getCachedTileRegion`.
- Failure:
  - 16 regions cross the antimeridian (United States 184 KB, Russia 149 KB, Alaska 116 KB...), so their bbox covers all longitudes and they are candidates for every tile at those latitudes: about 340 KB per query in Kraków, 530 KB in Warsaw, through the sqflite channel on the main isolate.
  - On the first launch after an upgrade, rebuild R1 requests each visited country's file; each install clears the cache and queues another forced rebuild (see 2), so R1 is wasted and k more rebuilds follow.
  - For a 100,000 km history (about 10^5 tiles) this means minutes to hours with blank statistics.
- Suggested fix: geometry-free candidate and chain queries with an LRU of geometries by id; split antimeridian bounding boxes in the build (needs a data rebuild); invalidate only tiles inside the installed country; install all missing files before one rebuild (coalesce); batch-read the tile cache.

**5. Statistics screens scale badly with history size.**
- Where: `lib/features/statistics/provider/region_detail_provider.dart:88-92` (`_Discovered.load`: `findRegionById` plus `getAncestorChain` per discovered region), `statistics_overview_provider.dart:203`, `logic/statistics_sync_payload.dart:31`.
- Failure: about five `SELECT *` per region, every chain re-reads the country row with its blob (US 184 KB, Canada 490 KB); the countries, region, city and overview providers rebuild on every `statisticsRevisionProvider` bump, about every 4 s while recording with the screen open.
- Suggested fix: one geometry-free `WHERE id IN (...)` query, ancestors fetched by id in a few rounds and chains built in memory from `parent_id`.

**7. The selected period goes stale after days in the background.**
- Where: `lib/features/statistics/provider/statistics_overview_provider.dart:80-82` (`statsDateFilterProvider` keep-alive, `DateTime.now()` of the first open).
- Failure: after the app stays in the background across a week or month boundary, reopening Statistics shows the old period ("Październik 2026" with October's numbers on 2 November).
- Suggested fix: make the period/date filters and the overview `autoDispose`, or store an offset relative to now.

**8. Distance is saved only when a recording stops.**
- Where: `lib/features/map/provider/map_stats_provider.dart:154` (`recordTripSession` at stop) with `_distanceM` accumulated at `:191`.
- Failure: a recording killed by the OS loses its distance and its longest-route record (the failure Task 8 fixed for streaks); a recording across midnight puts all its distance on the stop day.
- Suggested fix: write the distance into the daily ledger per calendar day as it accrues (batched, e.g. every 200 m and on a day change), the way `_accrue` already counts streak days; keep the longest-route record at stop.

**9. Country card subtitle has no unit.** (Minor in the review, promoted: users see it on the main Countries screen.)
- Where: `lib/features/statistics/screens/countries_screen.dart:69` passes `formatKm2(...)` without `km²` to `statsCountryCardSubtitle`.
- Failure: "11,6 · 9 miast" instead of the mock-up's "11,6 km² · 9 miast". The l10n test passes the unit by hand, so it does not catch it.
- Suggested fix: append ` km²` (or put the unit in the ARB message) and assert the rendered subtitle in a widget test.

**10. `ROADMAP.md` does not record D6** (fused location provider, keep saving fixes after a stream error), although Task 12 required it.

### Minor (deferred)

- Streak row has two writers: `statistics_providers.dart:76` (`recordAppOpen`) runs outside the tracker queue, `recordRecordingDay` inside it; a concurrent read-modify-write of `user_streak_stats` can lose one update.
- An app kept in the foreground across midnight records no app-open day for the new day (counted only at start and on resume).
- Damaged tiles redrawn are double counted: a cache entry with a null mask gets an all-zero cell baseline (`fog_tile_cache.dart:23-25`) while `areaM2` keeps the old area.
- `ref.watch(completedQuestsInPeriodProvider(range))` runs after awaits in `_loadStatsFor` (`statistics_overview_provider.dart:148`); move it before the first await.
- `StatsRecordType`, `RecordTileItem` and `WeeklyBarItem` live in widget files, so providers import widgets.
- Dead code: `todayExplorationStatsProvider`, `userRegionStatsProvider`; `streakStatsProvider` state is never read.
- City screen shows a "Districts" section with "No subregions discovered" for cities that have no districts (most gminas).
- A city-county row repeats its own name as subtitle ("Kraków" under "Kraków"); the mock-up shows "miasto na prawach powiatu".
- The map pill shows the local region name instead of the localized one (`map_stats_provider.dart:87`).
- `countries_screen.dart:56` styles text in a screen (`typography.body.copyWith(color:)`), which AGENTS.md reserves for components.
- Five-probe interior check: a border that enters and leaves a tile between the probes gives the whole tile to one leaf (follows D3 as written; "only one leaf-level candidate bbox meets the tile" would be safer and cheaper).
- Coastal city areas include water (Gdańsk), which dilutes their percentages.
- A live flush landing between a rebuild's tile read and the rebuild can be overwritten by it (the reviewer traced fog.db ordering and considers it consistent; the real windows are those in finding 2).
- Missing tests: switching the locale with a statistics screen open; the first recording in a new country through `FogNotifier` with real storages.

## Declined to judge (by the reviewer)

- App and repo size (about 155 MB raw, 113 MB compressed): owner decision D2 ("Everything, compact").
- 150 m city tolerance: owner choice of the compact profile.
- The D3 rule itself (whole tile vs 16 x 16 cells): decided in the plan.
- Backend sync payload content, size and name matching: separate backend issue.
- Whether geolocator really resumes after a stream error: needs a phone.
- Streak thresholds (100 m or 1 m2, reachable by GPS drift): roadmap rule.
- Best day being all-time rather than per period: mock-up ambiguous.
- Literal `km²` / `km` units and ` · ` separators: project convention in `measure_format.dart`.
- `BorderRadius.circular` literals: the project has no radius tokens.
- Flag colours as literals: data, not styling.
- The debug journey import writing into today's daily statistics: developer tool.
- Overture name and translation quality: upstream data.
- Up to one flush interval (about 4 s) of area skipped by the replay after a crash: small, and avoids double counting.
- Orphan rows if a country file's version is bumped without the base DB: the README requires bumping both together.

## Decisions made during implementation (for context)

- D2 became "everything bundled in the app, files committed to the repo" after the owner asked for plug and play without downloads. Cost if wrong: app and repo grow by the dataset size; every data regeneration adds about 100+ MB to git history.
- "Let's start with the impl" was taken as approval of D3 (border cells) and D4 (styling cleanup). Cost if wrong: revert Task 6 or Task 10.
- Error states use `errorSomethingWentWrong` (the plan named a non-existent `l10n.error`).
- Record and best-day dates use the existing `formatShortDate` ("d MMM", mock-up "12 paź").
- Boundary build: villages under a `localadmin` are kept (French communes); `localadmin` is treated as a middle level when more than three times as many localities sit below it (France). Cost if wrong: a per-country rule tweak.
- Geometry v2 uses zigzag varint deltas instead of float32 pairs (about 2.5x smaller); the planned `source_id` column was dropped to save space.
- `RegionStorage.installedPacks()` returns country -> version so a newer bundled file is reinstalled.
- `TileAreaDelta.cells` is optional; rebuilds read border cells through a batch `loadCells` (decoded in an isolate), otherwise the tile centre decides.
- The map pill no longer uses the tile-to-region cache, because the tracker stores border markers in it.
- Tasks 4, 6 and 7 share one commit (`910afbf`): their hunks mix in the same files and the v2 data had to land with its v2 reader.
- The boundary fetch was run three times (about 4.6 GB each) because of two filter bugs found by the data tests (French communes dropped; class-less city districts dropped by a SQL NULL comparison).

## Suggested order for the remaining work

1. Findings 2 and 3 together (persisted rebuild-pending and regions-version records, atomic replace, no wipe of visit dates): they decide what ends up stored on users' devices.
2. Findings 4 and 5 (geometry-free queries, coalesced rebuilds), then a fog benchmark run and a rebuild timing on a large generated journey.
3. Findings 7, 8, 9 and 10, then the full frontend suite and a phone check (record across a city border, first recording in a second country, language switch, location off and on during a recording).
