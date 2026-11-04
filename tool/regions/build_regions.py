#!/usr/bin/env python3
"""Builds the app's administrative boundary databases from Overture Maps.

`fetch` reads the Overture `divisions` theme once from its public S3 bucket
and keeps a local cache (geometry pre-simplified to about 10 m). `build`
turns the cache into the SQLite files the app bundles:

- `regions_world.db`: countries, states and counties of the whole world,
- `regions/regions_<ISO2>.db`: the cities and city districts of one country,
- `regions/index.json`: the country files and their sizes.

Data: Overture Maps Foundation, OpenStreetMap contributors (ODbL).
"""

import argparse
import json
import sqlite3
import sys
from pathlib import Path

RELEASE = "2026-10-21.0"
DB_VERSION = 2

# Coordinates are stored as integers of 1e-5 degree (about 1.1 m).
COORD_SCALE = 100_000

CACHE_TOLERANCE = 0.0001

# Simplification in degrees per level (0.001 is about 100 m). Only the leaf
# level decides where a cell goes, so the levels above it can be coarser.
DETAIL = {
    "accurate": {"country": 0.002, "state": 0.001, "county": 0.0006, "city": 0.0003, "district": 0.0003},
    "balanced": {"country": 0.01, "state": 0.004, "county": 0.002, "city": 0.0006, "district": 0.0005},
    "compact": {"country": 0.02, "state": 0.008, "county": 0.004, "city": 0.0015, "district": 0.001},
}
TOLERANCE = DETAIL["compact"]

BASE_TYPES = ("country", "state", "county")
PACK_TYPES = ("city", "district")

PASS_THROUGH = ("macroregion", "macrocounty")
AREA_SUBTYPES = (
    "country",
    "dependency",
    "region",
    "county",
    "localadmin",
    "locality",
    "borough",
    "macrohood",
)
META_SUBTYPES = AREA_SUBTYPES + PASS_THROUGH

S3 = "s3://overturemaps-us-west-2/release/{release}/theme=divisions/type={type}/*.parquet"

SCHEMA = """
CREATE TABLE regions (
  id INTEGER PRIMARY KEY,
  parent_id INTEGER,
  name TEXT NOT NULL,
  name_en TEXT,
  name_pl TEXT,
  type TEXT NOT NULL,
  code TEXT,
  total_area_km2 REAL NOT NULL,
  min_lat REAL NOT NULL,
  max_lat REAL NOT NULL,
  min_lon REAL NOT NULL,
  max_lon REAL NOT NULL,
  geometry BLOB NOT NULL
);
CREATE INDEX idx_regions_bbox ON regions (min_lon, max_lon, min_lat, max_lat);
CREATE INDEX idx_regions_parent ON regions (parent_id);
CREATE INDEX idx_regions_type ON regions (type);
"""

PACK_ID_STRIDE = 1_000_000


def localadmins_are_cities(localadmins, localities_below):
    """Whether a country's `localadmin` level is its municipalities (Czech
    obce, with a few town parts below them) or a middle level with the
    municipalities below it (French arrondissements over communes)."""
    return localities_below <= 3 * localadmins


def app_type(subtype, cls, parent_type, localadmin_is_city=True):
    """The app's region type of an Overture division, or None when the app
    does not use it. Macro levels, and a localadmin level that sits above
    the municipalities, pass their parent's type through, so a region under
    a macroregion is still a state."""
    if subtype in ("country", "dependency"):
        return "country"
    if subtype in PASS_THROUGH:
        return parent_type
    if subtype == "localadmin" and not localadmin_is_city:
        return parent_type
    if subtype == "region":
        return "state"
    if subtype == "county":
        return "county"
    if subtype in ("locality", "localadmin"):
        if parent_type in BASE_TYPES:
            return "city"
        if parent_type == "city" and subtype == "locality" and cls is None:
            return "district"
        return None
    if subtype in ("borough", "macrohood"):
        return "district" if parent_type == "city" else None
    return None


def clean_name(country, region_type, name, rules):
    """Overture names Polish voivodeships "Woj Dolnoslaskie" and counties
    "Powiat Krakowski"; the app shows "Dolnośląskie" and "krakowski"."""
    if country == "PL" and region_type == "state" and name.startswith("Woj "):
        for variant, language, value in rules:
            if variant == "alternate" and language is None and not value.lower().startswith("woj"):
                return value
        return name[len("Woj "):]
    if country == "PL" and region_type == "county" and name.startswith("Powiat "):
        rest = name[len("Powiat "):]
        return rest[:1].lower() + rest[1:]
    return name


def _write_varint(out, value):
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return


def _read_varint(data, offset):
    result = 0
    shift = 0
    while True:
        byte = data[offset]
        offset += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, offset
        shift += 7


def _zigzag(value):
    return (value << 1) ^ (value >> 63)


def _unzigzag(value):
    return (value >> 1) ^ -(value & 1)


def encode_geometry(rings):
    """Geometry format v2: varint ring count; per ring a varint point count,
    then zigzag varint deltas of lon and lat in 1e-5 degree, starting from 0
    in every ring. Point-in-polygon uses the even-odd rule over all rings, so
    holes and multipolygons need no further structure."""
    out = bytearray()
    _write_varint(out, len(rings))
    for ring in rings:
        _write_varint(out, len(ring))
        px = py = 0
        for lon, lat in ring:
            x = round(lon * COORD_SCALE)
            y = round(lat * COORD_SCALE)
            _write_varint(out, _zigzag(x - px))
            _write_varint(out, _zigzag(y - py))
            px, py = x, y
    return bytes(out)


def decode_geometry(blob):
    rings = []
    count, offset = _read_varint(blob, 0)
    for _ in range(count):
        points, offset = _read_varint(blob, offset)
        x = y = 0
        ring = []
        for _ in range(points):
            dx, offset = _read_varint(blob, offset)
            dy, offset = _read_varint(blob, offset)
            x += _unzigzag(dx)
            y += _unzigzag(dy)
            ring.append((x / COORD_SCALE, y / COORD_SCALE))
        rings.append(ring)
    return rings


def extract_rings(geometry):
    from shapely.geometry import GeometryCollection, MultiPolygon, Polygon

    if isinstance(geometry, Polygon):
        polygons = [geometry]
    elif isinstance(geometry, (MultiPolygon, GeometryCollection)):
        polygons = [g for g in geometry.geoms if isinstance(g, Polygon)]
    else:
        polygons = []
    rings = []
    for polygon in polygons:
        if polygon.is_empty:
            continue
        rings.append(list(polygon.exterior.coords))
        rings.extend(list(hole.coords) for hole in polygon.interiors)
    return [r for r in rings if len(r) >= 4]


def _duckdb():
    import duckdb

    con = duckdb.connect()
    con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial;")
    con.execute("SET s3_region = 'us-west-2'; SET geometry_always_xy = true;")
    return con


def fetch(release, cache):
    """Reads the divisions once and writes the local cache."""
    out = cache / release
    out.mkdir(parents=True, exist_ok=True)
    area = S3.format(release=release, type="division_area")
    division = S3.format(release=release, type="division")
    subtypes = ", ".join(f"'{s}'" for s in META_SUBTYPES)
    con = _duckdb()
    print("reading area ids", flush=True)
    con.execute(
        f"CREATE TABLE area_ids AS SELECT DISTINCT division_id FROM read_parquet('{area}') "
        f"WHERE is_land AND subtype IN ('locality', 'localadmin', 'borough', 'macrohood')"
    )
    print("reading divisions", flush=True)
    con.execute(
        f"""
        CREATE TABLE divisions AS
        SELECT id, subtype, class, parent_division_id AS parent, country, region,
               names.primary AS name, names.common['en'] AS name_en,
               names.common['pl'] AS name_pl,
               CASE WHEN country = 'PL' AND subtype = 'region'
                    THEN [{{'variant': r.variant, 'language': r.language, 'value': r.value}}
                          FOR r IN names.rules] END AS rules
        FROM read_parquet('{division}')
        WHERE subtype IN ({subtypes})
          AND (subtype NOT IN ('locality', 'localadmin', 'borough', 'macrohood')
               OR id IN (SELECT division_id FROM area_ids))
        """
    )
    con.execute(f"COPY divisions TO '{out / 'divisions.parquet'}' (FORMAT parquet)")
    print("reading areas (the long part)", flush=True)
    con.execute(
        f"""
        COPY (
          SELECT a.division_id, a.country,
                 ST_Area_Spheroid(a.geometry) / 1e6 AS area_km2,
                 ST_AsWKB(ST_SimplifyPreserveTopology(a.geometry, {CACHE_TOLERANCE})) AS wkb
          FROM read_parquet('{area}') a
          JOIN divisions d ON d.id = a.division_id
          LEFT JOIN divisions p ON p.id = d.parent
          WHERE a.is_land AND a.country IS NOT NULL
            AND a.subtype IN ({", ".join(f"'{s}'" for s in AREA_SUBTYPES)})
            AND NOT (a.subtype = 'locality'
                     AND coalesce(d.class, '') IN ('village', 'hamlet', 'town', 'city')
                     AND p.subtype = 'locality')
        ) TO '{out / 'areas'}' (FORMAT parquet, PARTITION_BY (country), OVERWRITE_OR_IGNORE)
        """
    )
    print("cache written to", out, flush=True)


def _load_divisions(con, path):
    divisions = {}
    for row in con.execute(f"SELECT * FROM read_parquet('{path}')").fetchall():
        (id_, subtype, cls, parent, country, region, name, name_en, name_pl, rules) = row
        divisions[id_] = {
            "subtype": subtype,
            "class": cls,
            "parent": parent,
            "country": country,
            "region": region,
            "name": name,
            "name_en": name_en,
            "name_pl": name_pl,
            "rules": [(r["variant"], r["language"], r["value"]) for r in rules or []],
        }
    return divisions


def _localadmin_roles(divisions):
    localadmins = {}
    below = {}
    for d in divisions.values():
        if d["subtype"] == "localadmin":
            localadmins[d["country"]] = localadmins.get(d["country"], 0) + 1
        elif d["subtype"] == "locality":
            parent = divisions.get(d["parent"])
            if parent is not None and parent["subtype"] == "localadmin":
                below[d["country"]] = below.get(d["country"], 0) + 1
    return {c: localadmins_are_cities(n, below.get(c, 0)) for c, n in localadmins.items()}


def _is_middle(d, roles):
    return d["subtype"] in PASS_THROUGH or (
        d["subtype"] == "localadmin" and not roles.get(d["country"], True)
    )


def _types(divisions, roles):
    types = {}

    def type_of(id_, depth=0):
        if id_ is None or id_ not in divisions or depth > 20:
            return None
        if id_ in types:
            return types[id_]
        d = divisions[id_]
        parent_type = None if d["subtype"] in ("country", "dependency") else type_of(d["parent"], depth + 1)
        types[id_] = app_type(
            d["subtype"], d["class"], parent_type, roles.get(d["country"], True)
        )
        return types[id_]

    for id_ in divisions:
        type_of(id_)
    return types


def _output_parent(divisions, types, output, id_):
    parent = divisions[id_]["parent"]
    while parent is not None and parent in divisions:
        if parent in output:
            return parent
        parent = divisions[parent]["parent"]
    return None


def build(release, cache, out_dir, countries=None, tolerance=TOLERANCE):
    import shapely

    src = cache / release
    con = _duckdb()
    divisions = _load_divisions(con, src / "divisions.parquet")
    roles = _localadmin_roles(divisions)
    types = _types(divisions, roles)
    print(f"{len(divisions)} divisions", flush=True)

    area_files = sorted((src / "areas").glob("country=*"))
    all_countries = sorted(p.name.split("=", 1)[1] for p in area_files)
    if countries:
        all_countries = [c for c in all_countries if c in countries]

    records = {}
    for country in all_countries:
        part = src / "areas" / f"country={country}"
        for id_, area_km2, wkb in con.execute(
            f"SELECT division_id, area_km2, wkb FROM read_parquet('{part}/*.parquet')"
        ).fetchall():
            d = divisions.get(id_)
            region_type = types.get(id_)
            if d is None or region_type is None or _is_middle(d, roles):
                continue
            records[id_] = (country, region_type, area_km2, bytes(wkb))
    print(f"{len(records)} areas", flush=True)

    ids = {}
    base_rows = sorted(
        (r[0], BASE_TYPES.index(r[1]), divisions[i]["name"] or "", i)
        for i, r in records.items()
        if r[1] in BASE_TYPES
    )
    for n, (*_, i) in enumerate(base_rows, start=1):
        ids[i] = n
    packs = {}
    for pack_index, country in enumerate(all_countries, start=1):
        members = sorted(
            (PACK_TYPES.index(r[1]), divisions[i]["name"] or "", i)
            for i, r in records.items()
            if r[0] == country and r[1] in PACK_TYPES
        )
        for n, (*_, i) in enumerate(members, start=1):
            ids[i] = pack_index * PACK_ID_STRIDE + n
        if members:
            packs[country] = [m[-1] for m in members]

    def row(i):
        country, region_type, area_km2, wkb = records[i]
        d = divisions[i]
        geometry = shapely.from_wkb(wkb)
        geometry = shapely.simplify(geometry, tolerance[region_type], preserve_topology=True)
        rings = extract_rings(geometry)
        if not rings:
            return None
        min_lon, min_lat, max_lon, max_lat = geometry.bounds
        name = clean_name(country, region_type, d["name"] or "", d["rules"])
        name_en = d["name_en"] and clean_name(country, region_type, d["name_en"], d["rules"])
        name_pl = d["name_pl"] and clean_name(country, region_type, d["name_pl"], d["rules"])
        parent = _output_parent(divisions, types, records, i) if region_type != "country" else None
        code = country if region_type == "country" else d["region"] if region_type == "state" else None
        return (
            ids[i],
            ids.get(parent),
            name,
            name_en if name_en != name else None,
            name_pl if name_pl != name else None,
            region_type,
            code,
            round(area_km2, 3),
            min_lat,
            max_lat,
            min_lon,
            max_lon,
            encode_geometry(rings),
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "regions").mkdir(exist_ok=True)
    _write_db(out_dir / "regions_world.db", [row(r[-1]) for r in base_rows])
    index = {"version": DB_VERSION, "release": release, "packs": []}
    for country, members in packs.items():
        path = out_dir / "regions" / f"regions_{country}.db"
        _write_db(path, [row(i) for i in members])
        index["packs"].append({"country": country, "file": path.name, "bytes": path.stat().st_size})
    (out_dir / "regions" / "index.json").write_text(json.dumps(index, indent=1) + "\n")
    print("written to", out_dir, flush=True)


def _write_db(path, rows):
    if path.exists():
        path.unlink()
    db = sqlite3.connect(path)
    db.executescript(SCHEMA)
    db.executemany(
        "INSERT INTO regions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [r for r in rows if r is not None],
    )
    db.execute(f"PRAGMA user_version = {DB_VERSION}")
    db.commit()
    db.execute("VACUUM")
    db.close()


def main(argv=None):
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("step", choices=["fetch", "build", "all"])
    parser.add_argument("--release", default=RELEASE)
    parser.add_argument("--cache", type=Path, default=here / "cache")
    parser.add_argument(
        "--out",
        type=Path,
        default=here.parents[1] / "globetrottr_front" / "assets" / "data",
    )
    parser.add_argument("--countries", help="comma-separated ISO codes, for trial builds")
    parser.add_argument("--detail", choices=sorted(DETAIL), default="compact")
    args = parser.parse_args(argv)
    countries = set(args.countries.split(",")) if args.countries else None
    if args.step in ("fetch", "all"):
        fetch(args.release, args.cache)
    if args.step in ("build", "all"):
        build(args.release, args.cache, args.out, countries, DETAIL[args.detail])


if __name__ == "__main__":
    sys.exit(main())
