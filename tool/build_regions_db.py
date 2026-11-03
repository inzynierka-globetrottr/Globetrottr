#!/usr/bin/env python3
import json
import math
import os
import sqlite3
import sys
import urllib.request

CACHE_DIR = "/tmp/ne_cache"
OUTPUT_DB = "/home/majkelrice/univeristy/Globetrottr/globetrottr_front/assets/data/regions_world.db"

URL_COUNTRIES = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson"
URL_STATES = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_admin_1_states_provinces.geojson"
URL_CITIES = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_populated_places.geojson"

def download_file(url, filename):
    os.makedirs(CACHE_DIR, exist_ok=True)
    filepath = os.path.join(CACHE_DIR, filename)
    if not os.path.exists(filepath):
        print(f"Downloading {filename}...")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp, open(filepath, "wb") as f:
            while chunk := resp.read(1024 * 1024):
                f.write(chunk)
        print(f"Downloaded {filename} ({os.path.getsize(filepath) / 1024 / 1024:.1f} MB)")
    else:
        print(f"Using cached {filename} ({os.path.getsize(filepath) / 1024 / 1024:.1f} MB)")
    return filepath

def get_bbox(geometry):
    gtype = geometry["type"]
    coords = geometry["coordinates"]
    min_lon, max_lon = 180.0, -180.0
    min_lat, max_lat = 90.0, -90.0

    def visit(pt):
        nonlocal min_lon, max_lon, min_lat, max_lat
        lon, lat = pt[0], pt[1]
        if lon < min_lon: min_lon = lon
        if lon > max_lon: max_lon = lon
        if lat < min_lat: min_lat = lat
        if lat > max_lat: max_lat = lat

    if gtype == "Point":
        visit(coords)
    elif gtype == "Polygon":
        for ring in coords:
            for pt in ring:
                visit(pt)
    elif gtype == "MultiPolygon":
        for poly in coords:
            for ring in poly:
                for pt in ring:
                    visit(pt)

    return min_lat, max_lat, min_lon, max_lon

def estimate_polygon_area_km2(min_lat, max_lat, min_lon, max_lon):
    lat_span_km = (max_lat - min_lat) * 111.0
    mid_lat = (min_lat + max_lat) / 2.0
    lon_span_km = (max_lon - min_lon) * 111.0 * math.cos(math.radians(mid_lat))
    return round(abs(lat_span_km * lon_span_km) * 0.65, 1)

def main():
    countries_file = download_file(URL_COUNTRIES, "countries_50m.geojson")
    states_file = download_file(URL_STATES, "states_10m.geojson")
    cities_file = download_file(URL_CITIES, "cities_10m.geojson")

    os.makedirs(os.path.dirname(OUTPUT_DB), exist_ok=True)
    if os.path.exists(OUTPUT_DB):
        os.remove(OUTPUT_DB)

    conn = sqlite3.connect(OUTPUT_DB)
    cur = conn.cursor()

    cur.execute("PRAGMA journal_mode = OFF")
    cur.execute("PRAGMA synchronous = 0")
    cur.execute("""
      CREATE TABLE regions (
        id INTEGER PRIMARY KEY,
        parent_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        code TEXT,
        total_area_km2 REAL NOT NULL,
        min_lat REAL NOT NULL,
        max_lat REAL NOT NULL,
        min_lon REAL NOT NULL,
        max_lon REAL NOT NULL,
        geometry BLOB
      )
    """)
    cur.execute("""
      CREATE VIRTUAL TABLE regions_rtree USING rtree(
        id, min_lon, max_lon, min_lat, max_lat
      )
    """)
    cur.execute("CREATE INDEX idx_regions_parent ON regions (parent_id)")
    cur.execute("CREATE INDEX idx_regions_type ON regions (type)")

    # 1. Countries
    print("Ingesting countries...")
    with open(countries_file, "r", encoding="utf-8") as f:
        countries_data = json.load(f)

    country_iso_to_id = {}
    country_rows = []
    rtree_rows = []

    # Reserve id 1 for Poland
    next_country_id = 2

    for feat in countries_data["features"]:
        props = feat["properties"]
        geom = feat["geometry"]
        if not geom: continue

        name = props.get("NAME") or props.get("ADMIN") or "Unknown"
        iso_a2 = props.get("ISO_A2") or props.get("WB_A2") or ""
        if iso_a2 == "-99": iso_a2 = props.get("POSTAL", "")

        min_lat, max_lat, min_lon, max_lon = get_bbox(geom)
        area = estimate_polygon_area_km2(min_lat, max_lat, min_lon, max_lon)
        if area <= 0: area = 100.0

        if iso_a2 == "PL" or name.lower() == "poland":
            c_id = 1
            name = "Polska"
            iso_a2 = "PL"
            area = 312696.0
        else:
            c_id = next_country_id
            next_country_id += 1

        if iso_a2:
            country_iso_to_id[iso_a2] = c_id
        country_iso_to_id[props.get("ADM0_A3", "")] = c_id

        country_rows.append((c_id, None, name, "country", iso_a2, area, min_lat, max_lat, min_lon, max_lon, None))
        rtree_rows.append((c_id, min_lon, max_lon, min_lat, max_lat))

    print(f"Processed {len(country_rows)} countries.")

    # 2. States / Provinces
    print("Ingesting states & provinces...")
    with open(states_file, "r", encoding="utf-8") as f:
        states_data = json.load(f)

    state_rows = []
    next_state_id = 1000

    for feat in states_data["features"]:
        props = feat["properties"]
        geom = feat["geometry"]
        if not geom: continue

        name = props.get("name") or props.get("NAME") or "Unknown"
        iso_a2 = props.get("iso_a2") or ""
        iso_3166_2 = props.get("iso_3166_2") or ""
        parent_id = country_iso_to_id.get(iso_a2) or country_iso_to_id.get(props.get("adm0_a3", ""))

        min_lat, max_lat, min_lon, max_lon = get_bbox(geom)
        area = estimate_polygon_area_km2(min_lat, max_lat, min_lon, max_lon)
        if area <= 0: area = 50.0

        s_id = next_state_id
        next_state_id += 1

        state_rows.append((s_id, parent_id, name, "state", iso_3166_2 or None, area, min_lat, max_lat, min_lon, max_lon, None))
        rtree_rows.append((s_id, min_lon, max_lon, min_lat, max_lat))

    print(f"Processed {len(state_rows)} states/provinces.")

    # 3. World Cities (Populated Places)
    print("Ingesting world cities...")
    with open(cities_file, "r", encoding="utf-8") as f:
        cities_data = json.load(f)

    city_rows = []
    next_city_id = 100000

    for feat in cities_data["features"]:
        props = feat["properties"]
        geom = feat["geometry"]
        if not geom or geom["type"] != "Point": continue

        lon, lat = geom["coordinates"][0], geom["coordinates"][1]
        name = props.get("NAME") or props.get("NAMEASCII") or "Unknown"
        iso_a2 = props.get("ISO_A2") or ""
        parent_id = country_iso_to_id.get(iso_a2)

        scalerank = props.get("SCALERANK", 5)
        if scalerank <= 1:
            delta_deg = 0.12
            area = 450.0
        elif scalerank <= 3:
            delta_deg = 0.08
            area = 200.0
        else:
            delta_deg = 0.05
            area = 80.0

        min_lat = lat - delta_deg
        max_lat = lat + delta_deg
        min_lon = lon - delta_deg
        max_lon = lon + delta_deg

        if name.lower() in ["krakow", "kraków"] and iso_a2 == "PL":
            c_id = 1001
            area = 326.8
            min_lat, max_lat, min_lon, max_lon = 49.97, 50.13, 19.79, 20.22
        elif name.lower() in ["warsaw", "warszawa"] and iso_a2 == "PL":
            c_id = 1002
            area = 517.2
            min_lat, max_lat, min_lon, max_lon = 52.09, 52.37, 20.85, 21.27
        else:
            c_id = next_city_id
            next_city_id += 1

        city_rows.append((c_id, parent_id, name, "city", None, area, min_lat, max_lat, min_lon, max_lon, None))
        rtree_rows.append((c_id, min_lon, max_lon, min_lat, max_lat))

    # 4. Kraków Municipal Districts
    krakow_districts = [
        (10001, 1001, "Stare Miasto", "district", None, 5.57, 50.051, 50.072, 19.920, 19.955, None),
        (10002, 1001, "Grzegórzki", "district", None, 5.85, 50.052, 50.071, 19.955, 19.998, None),
        (10004, 1001, "Prądnik Biały", "district", None, 23.42, 50.080, 50.130, 19.880, 19.960, None),
        (10005, 1001, "Krowodrza", "district", None, 5.62, 50.065, 50.082, 19.895, 19.935, None),
        (10008, 1001, "Dębniki", "district", None, 27.25, 49.985, 50.055, 19.820, 19.935, None),
        (10013, 1001, "Podgórze", "district", None, 25.67, 50.015, 50.052, 19.935, 20.020, None),
        (10018, 1001, "Nowa Huta", "district", None, 65.41, 50.050, 50.115, 20.020, 20.220, None),
    ]
    for d in krakow_districts:
        rtree_rows.append((d[0], d[8], d[9], d[6], d[7]))

    print("Inserting into SQLite database...")
    all_regions = country_rows + state_rows + city_rows + krakow_districts

    cur.executemany("INSERT OR REPLACE INTO regions VALUES (?,?,?,?,?,?,?,?,?,?,?)", all_regions)
    cur.executemany("INSERT OR REPLACE INTO regions_rtree VALUES (?,?,?,?,?)", rtree_rows)

    cur.execute("PRAGMA user_version = 1")
    conn.commit()
    print("Optimizing SQLite database...")
    cur.execute("VACUUM")
    conn.close()

    size_mb = os.path.getsize(OUTPUT_DB) / 1024 / 1024
    print(f"Successfully generated {OUTPUT_DB}:")
    print(f"  - Total entries: {len(all_regions):,} regions")
    print(f"  - Countries: {len(country_rows):,}")
    print(f"  - States/Provinces: {len(state_rows):,}")
    print(f"  - Cities & Districts: {len(city_rows) + len(krakow_districts):,}")
    print(f"  - Database file size: {size_mb:.2f} MB")

if __name__ == "__main__":
    main()
