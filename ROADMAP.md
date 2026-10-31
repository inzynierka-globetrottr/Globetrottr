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
- The fog is a set of Web Mercator tiles with 8-bit coverage per pixel, base level z16, plus a pyramid of coarser levels for zoomed-out views. Merging is a per-pixel `max`; drawing cost does not depend on how much has been discovered.
- Each pair of consecutive points of one session reveals a stadium with a 50 m radius (`MapConfig.defaultVisionRadius`); points of different sessions are never connected.
- A gap over 350 m between two points of a session breaks the path (the later point is a lone disc). Why: a long jump drew a strip across the whole distance and ran the app out of memory. A flat distance limit was chosen over a speed or time test: it needs no timestamps (about 1200 km/h at one fix per second; GPS lag is ignored).
- Smooth edges are stored in the data (anti-aliased rim), not computed while drawing. No custom GPU shaders.
- Rejected: polygons with `clipper2`, base level z17 (twice the storage), binary tiles with a GPU edge shader (kept in `git stash` "exp: binary fog tiles and GPU edge shader"), simplifying old sessions of the track log.

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

- **Friends' fog as tiles:** the client uploads tiles up to z15 changed since the last synced revision; the server stores them per user and serves them on demand to accepted friends. The friend's map uses the same renderer with a network tile source. Then the polygon friends' fog is removed.
- **Backend stops computing the fog:** raw routes are still uploaded and persisted for statistics; quests and statistics move to the bitmap fog (computed on the device, or the same rasterization on the server; to be decided).
- **Restore on a new device:** from server tiles (lower resolution) or by syncing the track log and rebuilding locally; to be decided with the backend work.
- **Store resilience after an out-of-memory (Done, one part open):** a tile cap per path and a replay that retries a failing step small and then skips it keep a bad stretch of the log from blocking every start; skipped entries show in the dev panel and a rebuild redraws them. Still to investigate: after an OOM the store queues did not recover (Clear fog / Clear track log did nothing).
- **New fog as a vector trail (Done):** points waiting for a flush and the stretch to the player are drawn as vectors over the tiles, which take over when their images are ready. Why: the same result on every zoom without live pyramid updates. Rejected: refreshing the shown pyramid level with every point (more code, flicker when changing zoom).
- **Fog migration for production (Planned):** a changed `drawVersion`, format or base level now just clears the tiles and rebuilds them from the track log.
- **Gap limit that follows time (Idea):** `min(ceiling, v_max * dt)` instead of a flat 350 m, so tunnels and metro rides get revealed.
- **Verify on phones:** smoothness while panning, zooming and rotating; import time of very long journeys; recording and crash recovery.

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
