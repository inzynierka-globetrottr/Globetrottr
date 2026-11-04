# Globetrottr roadmap

Source of truth for the plan and the key design decisions of every part of the app. Keep entries short: the essence and the reasons, not measurements or implementation detail (that lives in the code and its comments).

- Status: **Done**, **In progress**, **Planned**, **Idea**.
- Settled decisions are binding; changing one needs the owner's approval and an update here.
- Coding rules and checks: `AGENTS.md`. If code and this file disagree, trust the code and fix this file.

---

## Fog of war (Done, branch `exp/bitmap-fog`)

**Why it was rebuilt:** the fog used to be a polygon computed by the backend, so it needed a network, disagreed with what the app drew, and its drawing cost grew with every point ever recorded. A client-side polygon union (kept on branch `feature/optimize-fog`) would not scale to users covering whole countries.

**Decisions:**
- The user's own fog is computed, stored and drawn on the device only, fully offline. The backend plays no part in it.
- The track log (`tracks.db`) is the source of truth; the fog is a derived cache that can always be rebuilt from it. The log stays lossless: future views need dense points.
- The fog is a set of Web Mercator tiles with 8-bit coverage per pixel, base level z15, plus a pyramid of coarser levels for zoomed-out views. Merging is a per-pixel `max`; drawing cost does not depend on how much has been discovered.
- Each pair of consecutive points of one session reveals a stadium with a 50 m radius (`MapConfig.defaultVisionRadius`); points of different sessions are never connected.
- A gap over 350 m between two points of a session breaks the path (the later point is a lone disc). Why: a long jump drew a strip across the whole distance and ran the app out of memory. A flat distance limit was chosen over a speed or time test: it needs no timestamps (about 1200 km/h at one fix per second; GPS lag is ignored).
- Tiles store a soft edge wide enough to be enlarged; a colour filter sets its width on the screen at every zoom, so the edge stays smooth. No custom GPU shaders.
- The player moves on the map by gliding along the recorded fixes, and the marker and the fog read that one position, so they cannot be apart. A fix is stored at once but reaches the fog when the player gets there.
- The glide runs at 15-30 steps per second depending on speed, and nothing asks for a frame between steps. Why: a walk moves a fraction of a pixel per frame, so a full frame rate only costs battery. Map gestures stay at the native rate. Rejected: ignoring ticks of a frame-driven timer (frames would still be drawn), reading the screen refresh rate (no visible gain).
- Rejected: polygons with `clipper2`, base levels z16 and z17 (more storage for detail a 50 m radius does not need), binary tiles with a GPU edge shader (kept in `git stash` "exp: binary fog tiles and GPU edge shader"), simplifying old sessions of the track log.

**Invariants:**
- Positions reach the fog only in the rounded form stored in the log, so live and rebuilt fog are identical.
- Anything that changes tile pixels or format must change a value checked when the fog opens, so old tiles are dropped and rebuilt from the track log.
- Heavy work (import, rebuild, encoding) runs in isolates.
- The fog is per installation; logout does not clear it.

**Where:** `lib/features/fog/` (bitmap, data, render, provider) and `lib/features/map/data/` (track log). Developer tools, including a journey generator up to 100,000 km, are in `lib/debug/`.

**Legacy still in place** (marked `TODO(fog)` in code, do not extend):
- Friends' fog is still a backend polygon drawn by `FogLayer` / `FogPainter`.
- The backend still builds its own fog from synced points, and quests and statistics are computed from it.

---

## Fog follow-ups (Planned)

- **Friends' fog as tiles:** the client uploads tiles changed since the last synced revision; the server stores them per user and serves them on demand to accepted friends. The friend's map uses the same renderer with a network tile source. Then the polygon friends' fog is removed.
- **Backend stops computing the fog (In progress, branch `feat/25-stats-screens`):** raw routes are still uploaded and persisted; statistics move to client-side bitmap fog tiles mapped to bundled boundaries. Server PostGIS polygon intersection is deprecated.
- **Restore on a new device:** from server tiles (lower resolution) or by syncing the track log and rebuilding locally; to be decided with the backend work.
- **Store resilience after an out-of-memory (Done, one part open):** a tile cap per path and a replay that retries a failing step small and then skips it keep a bad stretch of the log from blocking every start; skipped entries show in the dev panel and a rebuild redraws them. Still to investigate: after an OOM the store queues did not recover (Clear fog / Clear track log did nothing).
- **New fog as a copy of the future tiles (Done):** points waiting for a flush and the stretch to the player are drawn with exactly the values the tiles will hold, and merged with them by a maximum. Why: a flush changes nothing on the screen and new fog needs no live pyramid updates. Rejected: a differently drawn trail (visible jump at every flush), rebuilding tile images for every point (flicker on zoom changes, fog behind the marker), a disk write for every point (no gain).
- **Fog migration for production (Planned):** a changed `drawVersion`, format or base level now just clears the tiles and rebuilds them from the track log.
- **Gap limit that follows time (Idea):** `min(ceiling, v_max * dt)` instead of a flat 350 m, so tunnels and metro rides get revealed.
- **Verify on phones:** smoothness while panning, zooming and rotating; the glide at 15-30 steps per second, also on 120 Hz screens and at the highest zoom; battery use; import time of very long journeys; recording and crash recovery.

---

## UI redesign "Neo · Neumorphic" (In progress)

The app moves from the current dark neumorphic look to a light neumorphic style with one configurable accent colour. The reference is the HTML mock-up `globetrotttr-neo-neumorphic.html` (branch `design/neo-mockup`); screens in its "Locked in" group are approved, the rest are still being iterated.

**Current frontend:** the whole app uses the light theme tokens, the bundled Manrope font and the shared neumorphic components; the bottom navigation follows the mock-up. The auth, Friends, Add friend, map and Quests screens follow the mock-up; numbers the backend does not provide yet are neutral placeholders. The friend's map and the profile still have their old layouts.

**Stages** (each ends with a review by the owner):
1. Theme tokens, bundled Manrope font, shared components, bottom navigation, fog colour (Done; not yet checked on a phone).
2. Auth: login, registration, e-mail verification, password reset (Done; not yet checked on a phone or against the backend).
3. Friends and adding a friend (Done; not yet checked on a phone or against the backend).
4. Map: area pill, recording, quest flag with its card, layers sheet (Done; not yet checked on a phone).
5. Quests: active quest, places and routes with a map preview, swapping the active quest, history of completed quests (Done; checked on the emulator, not yet on a phone).

**Decisions:**
- Port in stages, cheapest visual gain first. Screens outside the "Locked in" group (comparison with a friend, statistics, countries, regions, cities, badges) wait for approval and data.
- Design system as building blocks: styling lives only in theme tokens and reusable components; screens are just assembled from them, so one change keeps the whole app consistent.
- Light theme first. The architecture supports a dark mode and a different accent (components read them from the theme); the switch itself is Planned. Accent for now: one teal colour.
- Own shadow implementation in the shared components instead of `flutter_neumorphic_plus`. Why: the package does not reproduce the mock-up shadows and forces a neumorphic theme wrapper on every screen.
- Manrope is bundled with the app, not downloaded at run time (offline-first).
- Icons are the mock-up's own SVG drawings, not Material Icons, which look different.
- Shadows follow one scale of five depths taken from the mock-up instead of a value per element. Why: the mock-up's small differences in shadow opacity are not visible and one scale keeps components consistent.
- The fog colour and opacity come from the theme palette like every other colour.
- Dev and release builds differ only by the dev button and its tools. Missing data is shown as placeholders from providers, marked `TODO(data)`, in both builds.
- Guest mode in release: "Skip" on the login screen enters the app without an account and is remembered across restarts until the user leaves it from the profile; everything local works, backend features fail as offline. An account and guest mode never hold at once: a stored session or a sign-in that ends after "Skip" wins, so a logout still syncs that account's points.
- Registration goes through e-mail verification (the backend already supports it); password rules follow the backend. Instead of the mock-up's strength bar the registration shows each rule as a pill that is ticked once met (owner's decision: a password is either good or not, and symbols read faster than a sentence).
- Signing in to an account whose e-mail is not verified only shows a message. Why: the backend needs the address to send a code and the user may have typed the nickname. Known gap: such an account can be verified only right after registering.
- Password reset is UI only until the backend has an endpoint for it: "Send code" says it is not available yet and the code screen is built but not reachable.
- The auth screens are nested routes under the login screen, so going back follows the routes and one redirect takes the user to the map once they are in.
- Startup decides from the device alone: a stored token or the guest choice opens the map at once, behind a blank start screen instead of a flash of the login. The token is refreshed afterwards; only the backend rejecting it signs the user out, being offline never does (offline-first; waiting for the refresh kept the login on screen up to the network timeout).
- The player marker is the accent dot without the mock-up's faint halo (owner's decision: the halo read as GPS accuracy or vision range and showed neither).
- Placeholders for missing data are neutral ("— km²", empty rings, level "–", no invite details), never sample numbers, because they show next to real friends in release.
- "This week" shows the user and every friend with discovered area that week, largest first; with more than four the row scrolls and the next person peeks in at the edge. With no friends the strip and the list give way to one empty card with an "Add a friend" action, because a lone avatar looked broken (the mock-up has no such state; owner approval pending).
- Received invites live in a folding card on the Friends screen and sent ones on the Add friend screen; the separate invites screen and user search are gone. Until the comparison screen is approved, a friend's arrow opens their map.
- The map always keeps north up and has no compass, as in the mock-up.
- The layers sheet lists every planned view; only the fog can be chosen, the others say they are coming.
- The map shows only the active quest: the next point of a quest of places with its distance, or the line of a route; "Show point/route" on the Quests tab flies there. Pins for every quest on the map were dropped in favour of the mock-up.
- One active quest is enforced by the backend: starting a quest abandons the one in progress together with its progress; completed quests stay. Why: the swap warning promises it, and the client alone could not keep it across devices.
- Available quests are listed nearest first within their group; the distance itself is not shown, as in the mock-up.
- The backend has no levels yet: the level is a placeholder and the XP is the profile's total points.
- Product decisions from the mock-up: one active quest at a time, its next point is shown on the map without navigation; friends are added by exact nickname, without suggestions; the profile has no map; the "passing through" feature is dropped.
- Quests tab from the mock-up: the active quest card on top (points as steps, a route as a progress bar, an empty dashed card when none is active), below it the available quests grouped by type (places, routes) with no time estimates. A quest opens into a map preview with one button that starts it, or swaps it in after a warning that the active quest and its progress are lost. Completed quests are not listed; the level row opens their history.

**Open questions:**
- Guest data after signing in: the fog stays (it is per installation), but should points recorded as a guest be uploaded to the new account? For now leaving guest mode keeps them in the upload queue, so the first sync after signing in sends them.

**Ideas:**
- **Configurable profile widgets:** the profile (own and a friend's) is assembled from widgets the user picks and orders. Candidates from the mock-up: metric tiles, discovery per month chart, cities with % rings, countries with km² bars, completed quests carousel. The mock-up keeps a fixed layout until then.

---

## Statistics & administrative boundaries (In progress, branch `feat/25-stats-screens`)

**Why:** With fog computed as local bitmap tiles, backend polygon intersections (`ST_Intersection`) are obsolete, slow, and offline-incompatible. Statistics are computed directly on the device from fog tiles.

**Decisions:**
- Administrative boundaries for the whole world (countries, states, counties, cities/municipalities, major city districts) are bundled in the app as a compact read-only SQLite database with R-Tree spatial indexing (`regions_world.db`, ~55 MB).
- Fog tiles at zoom 15 map to regions by tile centroid. Area increments are attributed to the leaf city and rolled up to county, state, and country. No runtime polygon clipping.
- Rebuildable: clearing or recalculating statistics replays all stored fog tiles against the local boundary index in under 200 ms.
- Dual streaks are tracked in local SQLite: app open streak (daily app launches) and recording streak (daily track recordings with distance/area).
- Streets count is tracked per city by recording unique traversed OpenStreetMap road names matched from vector road tiles.
- Backend statistics ingestion & dual streaks: backend accepts StatisticsSyncDto (scalar area, countries, dual streaks, and region percentage breakdowns resolved by name and code) on /api/map/sync avoiding heavy PostGIS spatial calculations on sync; statistics screen displays both app open streak and recording streak with current and max day counts in neumorphic styling. Expired streaks reset to zero; fog rebuilds isolate replay to prevent artificial spikes in daily exploration and personal records.
- Screens follow the Neo Neumorphic design (`globetrotttr-neo-neumorphic.html`): `Neo · Statystyki`, `Neo · Kraje`, `Neo · Region`, and `Neo · Miasto`. Reusable components built under `lib/features/statistics/screens/widgets/` (`StatsPeriodTabs`, `StatsDateNavigator`, `StatsMetricTile`, `StatsWeeklyChart`, `StatsCountriesBanner`, `StatsActivitySection`, `StatsRecordsGrid`, `StatsDiscoveryCard`, `StatsMostVisitedCard`, `StatsDetailProgressCard`, `StatsMetricsRow`, `StatsMetadataCard`, `CountryFlagChip`, `CountryAccordionCard`).
- Dual Polish and English localization across all statistics screens and sub-pages.
- GoRouter navigation registered under `/profile/statistics`, `/profile/statistics/countries`, `/profile/statistics/region/:id`, and `/profile/statistics/city/:id`.
- Wired to live data: all statistics screens and sub-pages read directly from local `stats.db` and `regions_world.db`. Fog tile flushes emit area deltas to `StatisticsTracker` to update daily exploration ledgers, region progress, and personal records without mock data. Missing data shows neutral placeholders.
- Map pill & region seeding: map status pill wired to live session new area, player motion, and current district progress; boundary database seeder automatically populates initial world and Polish administrative hierarchies into `regions_world.db`; automatic startup and on-screen backfill reconstructs stats from existing `fog.db` tiles using codec decoding, with localized period labels and activity metrics.
- Accurate boundaries & spatial query portability: boundary database contains exact simplified polygon rings (242 countries with collision-free ISO 3166-1 alpha-2 codes, 4,596 states, 2,477 Polish cities and gminas from GUGiK, Krakow municipal districts) with ray-casting point-in-polygon verification in Region.containsPoint; queries use standard B-tree bounding box indexing instead of SQLite R-Tree virtual tables which are absent from Android system SQLite.
- True spherical geometry area summation across all MultiPolygon exterior rings minus interior holes (`build_accurate_regions_db.py`), correcting deflated land areas for fragmented municipalities (e.g. Kamienica 95.3 km²) and countries.
- Strict geographic ancestor containment: world cities linked to containing states via ADM1NAME, Australian states linked directly to Australia, and Kraków districts linked to Kraków.
- Backend region resolution by name and code (`V7__add_code_to_regions.sql`): `StatisticsSyncService` resolves client region updates by both name and ISO/ADM code (or unique code/name), eliminating fragile local SQLite ID matching.
- Dynamic subregion header localization on Region Detail Screen adapting between districts, gminas, and counties.

---

## Base map (Done)

**Decisions:**
- Vector tiles from OpenFreeMap drawn with our own style built from the map palette. Why: no API key, no cost and full control of the look, so the map fits the app. Rejected: Carto raster tiles (fixed look).
- The tile URL names a data release and is read from the OpenFreeMap TileJSON, and read again periodically, because old releases are removed. Own tile provider instead of the package's, which takes a fixed URL and has no timeout.
- Labels are in the app language, with the local name where the map data has no translation.
- The map palette switches at once instead of blending during a theme animation, because every new style redraws all tiles.

**Planned:**
- **Attribution (Planned, required before the app is given to anyone outside the team):** the map must credit OpenFreeMap, OpenMapTiles and OpenStreetMap contributors (ODbL), for example with a collapsible attribution button that fits the mock-up.
- **Dark map palette (Planned):** together with the dark mode of the app.

---

## Map views (Planned)

Besides the classic fog, the user can switch between several views of what they have discovered.

**Views:**
- **Classic:** the current fog, revealed within the vision radius.
- **Streets:** only the road network; the parts of roads actually travelled are marked, nothing else.
- **Heatmap:** how often places were visited.
- **Voronoi:** every road segment between two intersections owns the area closer to it than to any other segment (a Voronoi cell). Travelling along a segment progressively reveals its cell: in a city a strip up to the middle of each block, in the countryside possibly a whole forest.

**Decisions:**
- Every view is up to date while recording; switching views is instant. All views are computed continuously in the background from the same stream of new points; the active view only decides what is drawn.
- Every view is a derived layer of the track log, like the fog: its own storage, the id of the last log point it has applied, an algorithm version (a change triggers a rebuild) and a rebuild from scratch. Each layer has an incremental mode (point by point while recording) and a batch mode (rebuild in isolates). `FogStore` is the model to generalize before the second view is built.
- Streets and Voronoi need the road network, from OpenStreetMap, preprocessed on the server into tiles: road segments with stable ids, plus precomputed Voronoi cells. Tiles are downloaded where the user goes (prefetched around the position and direction of travel, optionally a region in advance) and cached. The road data is versioned; a new version re-matches the affected tiles from the track log. The phone and the server must use the same version if friends are to see these views.
- Matching points to roads (map matching) runs incrementally with a short delay over a sliding window; the last stretch can be shown provisionally and is corrected once decided, and the whole session is re-checked when recording stops. The result is the list of travelled ranges per road segment.
- Voronoi reveals progressively: segments are split into short pieces (tens of metres) with their own cells, grouped by segment; a cell piece is revealed when its piece of road is travelled.
- Heatmap counts each place at most once per session, so standing still or going back and forth does not inflate it.
- Offline: classic and heatmap always work; streets and Voronoi wait for missing road tiles and catch up from the track log later.
- Classic, heatmap and Voronoi can be drawn as bitmap tiles with the existing renderer; streets as vectors or tiles. A common tile source interface (also needed for friends' fog) serves all of them.

**Open questions:**
- Heatmap intensity: distinct days or sessions per place (recommended), time spent, or number of passes?
- Which roads count: public roads only, also footpaths and cycle paths, also field and forest tracks?
- Should trains and flights count? If not, they must be filtered out (a railway along a road can match the road).
- Initial coverage of the road data: Poland or the whole world?
- Which views friends can see.
