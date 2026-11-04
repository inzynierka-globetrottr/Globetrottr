# Administrative boundaries for the app

`build_regions.py` turns the Overture Maps `divisions` theme into the SQLite
files the app bundles under `globetrottr_front/assets/data/`:

- `regions_world.db`: countries, states and counties of the whole world,
- `regions/regions_<ISO2>.db`: the cities and city districts of one country,
  copied into the local database the first time the user records there,
- `regions/index.json`: the country files and their sizes.

Data: Overture Maps Foundation and OpenStreetMap contributors, ODbL. The app
shows the attribution under the statistics screens that use the boundaries.

## Run

```bash
uv venv tool/regions/.venv
uv pip install --python tool/regions/.venv/bin/python -r tool/regions/requirements.txt
tool/regions/.venv/bin/python tool/regions/build_regions.py fetch
tool/regions/.venv/bin/python tool/regions/build_regions.py build
tool/regions/.venv/bin/python -m pytest tool/regions
```

`fetch` reads the Overture release (`RELEASE` in the script) from its public
S3 bucket once, about 4.6 GB, and keeps a cache of about 1.5 GB in
`tool/regions/cache/` (git-ignored). `build` needs only the cache and takes
about 20 minutes on a 12-core laptop. `--countries PL,CZ` builds a subset for trials;
`--detail accurate|balanced|compact` picks the simplification.

A new build must raise `DB_VERSION` in the script and
`kBundledRegionsDbVersion` in the app together: region ids change between
builds, so the app replaces its copy and rebuilds the statistics from the
fog tiles.

## Levels

| App type | Overture division |
| --- | --- |
| country | `country`, `dependency` |
| state | `region` |
| county | `county` |
| city | `locality` or `localadmin` directly below a county, state or country |
| district | `borough`, `macrohood`, or a `locality` without a class, below a city |

`macroregion`, `macrocounty` and, where most localities sit below it (France),
`localadmin` are skipped and pass their parent on. Villages and hamlets below
a city are not regions of their own.

## Size

Compact detail (the shipped profile): city and district borders within about
150 m, counties about 400 m, states about 800 m, countries about 2 km (the
coarser levels only matter where no city covers a place).

| Profile | Base DB | All countries | Zip total |
| --- | --- | --- | --- |
| accurate (30 m cities) | 82 MB | 199 MB | 200 MB |
| balanced (60 m) | 44 MB | 160 MB | 146 MB |
| compact (150 m), shipped | 31 MB | 130 MB | 113 MB |

Release 2026-10-21.0: 272 countries, 3,929 states, 38,935 counties, 357,637
cities and 70,123 districts. Poland: 16 voivodeships, 380 powiats,
2,479 gminas, Kraków with its 18 districts.
