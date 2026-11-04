import json
import random
import sqlite3
from pathlib import Path

import pytest

import build_regions as br

ASSETS = Path(__file__).resolve().parents[2] / "globetrottr_front" / "assets" / "data"
BASE_DB = ASSETS / "regions_world.db"
PL_DB = ASSETS / "regions" / "regions_PL.db"


def random_ring(n, seed=1):
    rng = random.Random(seed)
    lon, lat = 19.9, 50.06
    ring = []
    for _ in range(n):
        lon += rng.uniform(-0.01, 0.01)
        lat += rng.uniform(-0.01, 0.01)
        ring.append((lon, lat))
    ring.append(ring[0])
    return ring


def test_geometry_round_trip_keeps_a_ring_of_70000_points():
    ring = random_ring(70_000)
    decoded = br.decode_geometry(br.encode_geometry([ring]))

    assert len(decoded) == 1
    assert len(decoded[0]) == len(ring)
    for (x, y), (dx, dy) in zip(ring, decoded[0]):
        assert abs(x - dx) <= 0.5 / br.COORD_SCALE + 1e-12
        assert abs(y - dy) <= 0.5 / br.COORD_SCALE + 1e-12


def test_geometry_round_trip_keeps_western_and_southern_coordinates():
    ring = [(-70.5, -33.4), (-70.4, -33.4), (-70.4, -33.3), (-70.5, -33.4)]

    decoded = br.decode_geometry(br.encode_geometry([ring, ring]))

    assert decoded == [ring, ring]


def test_geometry_is_much_smaller_than_float_pairs():
    ring = random_ring(10_000)

    assert len(br.encode_geometry([ring])) < 10_000 * 8 / 2


@pytest.mark.parametrize(
    "subtype, cls, parent_type, expected",
    [
        ("country", None, None, "country"),
        ("dependency", None, None, "country"),
        ("region", None, "country", "state"),
        ("county", None, "state", "county"),
        ("locality", "city", "county", "city"),
        ("localadmin", None, "county", "city"),
        ("locality", "town", "state", "city"),
        ("locality", "village", "city", None),
        ("locality", "hamlet", "city", None),
        ("locality", None, "city", "district"),
        ("macrohood", None, "city", "district"),
        ("borough", None, "city", "district"),
        ("macrohood", None, "county", None),
        ("locality", "village", None, None),
        ("neighborhood", None, "city", None),
        ("microhood", None, "district", None),
    ],
)
def test_app_type(subtype, cls, parent_type, expected):
    assert br.app_type(subtype, cls, parent_type) == expected


def test_localadmin_is_a_city_when_localities_below_it_are_few():
    assert br.localadmins_are_cities(localadmins=6257, localities_below=1104)


def test_localadmin_is_a_middle_level_when_cities_sit_below_it():
    assert not br.localadmins_are_cities(localadmins=320, localities_below=36000)


def test_a_middle_localadmin_passes_its_parent_type_to_the_cities_below():
    middle = br.app_type("localadmin", None, "county", localadmin_is_city=False)

    assert middle == "county"
    assert br.app_type("locality", "village", middle) == "city"


def test_macro_levels_pass_their_parent_type_through():
    assert br.app_type("macroregion", None, "country") == "country"
    assert br.app_type("macrocounty", None, "state") == "state"


def test_polish_voivodeship_names_use_the_plain_alternate_name():
    rules = [("alternate", "br", "Voivodiezh"), ("alternate", None, "Dolnośląskie")]

    assert br.clean_name("PL", "state", "Woj Dolnoslaskie", rules) == "Dolnośląskie"


def test_polish_voivodeship_names_without_rules_lose_the_prefix():
    assert br.clean_name("PL", "state", "Woj Małopolskie", []) == "Małopolskie"


def test_polish_county_names_are_the_lowercase_adjective():
    assert br.clean_name("PL", "county", "Powiat Krakowski", []) == "krakowski"
    assert br.clean_name("PL", "county", "Kraków", []) == "Kraków"


def test_other_names_are_kept():
    assert br.clean_name("PL", "city", "Woj Małopolskie", []) == "Woj Małopolskie"
    assert br.clean_name("CZ", "state", "Jihomoravský kraj", []) == "Jihomoravský kraj"


built = pytest.mark.skipif(
    not (BASE_DB.exists() and PL_DB.exists()),
    reason="boundary databases not built",
)


def rows(db, sql, *args):
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    try:
        return con.execute(sql, args).fetchall()
    finally:
        con.close()


@built
def test_poland_has_its_administrative_levels():
    poland = rows(BASE_DB, "SELECT id FROM regions WHERE type='country' AND code='PL'")
    assert len(poland) == 1
    states = rows(BASE_DB, "SELECT id FROM regions WHERE type='state' AND parent_id=?", poland[0][0])
    assert len(states) == 16
    counties = rows(
        BASE_DB,
        "SELECT COUNT(*) FROM regions WHERE type='county' AND parent_id IN "
        "(SELECT id FROM regions WHERE type='state' AND parent_id=?)",
        poland[0][0],
    )
    assert counties[0][0] == 380
    cities = rows(PL_DB, "SELECT COUNT(*) FROM regions WHERE type='city'")[0][0]
    assert 2470 <= cities <= 2485


@built
def test_krakow_has_18_districts_covering_the_city():
    krakow = rows(PL_DB, "SELECT id, total_area_km2 FROM regions WHERE type='city' AND name='Kraków'")
    assert len(krakow) == 1
    districts = rows(
        PL_DB,
        "SELECT COUNT(*), SUM(total_area_km2) FROM regions WHERE type='district' AND parent_id=?",
        krakow[0][0],
    )
    assert districts[0][0] == 18
    assert districts[0][1] == pytest.approx(krakow[0][1], rel=0.02)


@built
def test_polish_states_cover_poland():
    poland = rows(BASE_DB, "SELECT id, total_area_km2 FROM regions WHERE type='country' AND code='PL'")[0]
    total = rows(BASE_DB, "SELECT SUM(total_area_km2) FROM regions WHERE parent_id=?", poland[0])[0][0]
    assert total == pytest.approx(poland[1], rel=0.02)


@built
def test_every_region_has_a_geometry_and_a_known_parent():
    for db in [BASE_DB, PL_DB]:
        assert rows(db, "SELECT COUNT(*) FROM regions WHERE geometry IS NULL")[0][0] == 0
        assert rows(db, "PRAGMA user_version")[0][0] == br.DB_VERSION
    base_ids = {r[0] for r in rows(BASE_DB, "SELECT id FROM regions")}
    pl_ids = {r[0] for r in rows(PL_DB, "SELECT id FROM regions")}
    assert not base_ids & pl_ids
    for db, known in [(BASE_DB, base_ids), (PL_DB, base_ids | pl_ids)]:
        parents = {r[0] for r in rows(db, "SELECT parent_id FROM regions WHERE parent_id IS NOT NULL")}
        assert parents <= known


@built
def test_index_lists_poland():
    index = json.loads((ASSETS / "regions" / "index.json").read_text())
    assert index["version"] == br.DB_VERSION
    poland = [p for p in index["packs"] if p["country"] == "PL"]
    assert poland and poland[0]["file"] == "regions_PL.db"
    assert poland[0]["bytes"] == PL_DB.stat().st_size
