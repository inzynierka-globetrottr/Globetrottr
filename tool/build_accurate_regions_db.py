import json
import math
import os
import sqlite3
import struct
import time

OUTPUT_DB = "globetrottr_front/assets/data/regions_world.db"

def rdp(points, epsilon):
    if len(points) < 3:
        return points
    dmax = 0.0
    index = 0
    x1, y1 = points[0]
    x2, y2 = points[-1]
    dx = x2 - x1
    dy = y2 - y1
    dist_sq = dx*dx + dy*dy
    inv_len = 1.0 / math.sqrt(dist_sq) if dist_sq > 0 else 0.0
    for i in range(1, len(points) - 1):
        x0, y0 = points[i]
        if dist_sq == 0:
            d = math.hypot(x0 - x1, y0 - y1)
        else:
            d = abs(dy*x0 - dx*y0 + x2*y1 - y2*x1) * inv_len
        if d > dmax:
            index = i
            dmax = d
    if dmax > epsilon:
        rec1 = rdp(points[:index+1], epsilon)
        rec2 = rdp(points[index:], epsilon)
        return rec1[:-1] + rec2
    else:
        return [points[0], points[-1]]

def get_bbox(rings):
    min_lon, max_lon = 180.0, -180.0
    min_lat, max_lat = 90.0, -90.0
    for ring in rings:
        for pt in ring:
            lon, lat = pt[0], pt[1]
            if lon < min_lon: min_lon = lon
            if lon > max_lon: max_lon = lon
            if lat < min_lat: min_lat = lat
            if lat > max_lat: max_lat = lat
    return min_lat, max_lat, min_lon, max_lon

def polygon_area_km2(rings):
    if not rings or not rings[0]:
        return 0.0
    outer = rings[0]
    area = 0.0
    R = 6371.0
    rad = math.pi / 180.0
    for i in range(len(outer) - 1):
        p1 = outer[i]
        p2 = outer[i+1]
        area += (p2[0] - p1[0]) * rad * (2.0 + math.sin(p1[1] * rad) + math.sin(p2[1] * rad))
    area = abs(area * R * R / 2.0)
    return round(area, 1)

def encode_geometry(rings, epsilon=0.0008):
    buf = bytearray()
    valid_rings = []
    for ring in rings:
        simplified = rdp(ring, epsilon)
        if len(simplified) >= 3:
            valid_rings.append(simplified)
    if not valid_rings:
        return None
    buf.extend(struct.pack('<H', len(valid_rings)))
    for ring in valid_rings:
        buf.extend(struct.pack('<H', len(ring)))
        for lon, lat in ring:
            buf.extend(struct.pack('<ff', float(lon), float(lat)))
    return bytes(buf)

def extract_rings(geom):
    gtype = geom["type"]
    coords = geom["coordinates"]
    if gtype == "Polygon":
        return coords
    elif gtype == "MultiPolygon":
        return [ring for poly in coords for ring in poly]
    return []

def main():
    t0 = time.time()
    print("Building accurate regions database...")

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
    cur.execute("CREATE INDEX idx_regions_parent ON regions (parent_id)")
    cur.execute("CREATE INDEX idx_regions_type ON regions (type)")
    cur.execute("CREATE INDEX idx_regions_bbox ON regions (min_lon, max_lon, min_lat, max_lat)")

    # 1. Countries (IDs 1..999)
    print("Processing countries...")
    with open('globetrottr_backend/src/main/resources/data/countries.geojson', 'r', encoding='utf-8') as f:
        countries_data = json.load(f)

    country_iso_to_id = {}
    country_rows = []
    next_country_id = 300

    for feat in countries_data['features']:
        props = feat['properties']
        geom = feat['geometry']
        if not geom: continue
        rings = extract_rings(geom)
        if not rings: continue

        name = props.get('NAME') or props.get('ADMIN') or 'Unknown'
        iso_a2 = props.get('ISO_A2') or props.get('WB_A2') or ''
        if iso_a2 == '-99': iso_a2 = props.get('POSTAL', '')

        min_lat, max_lat, min_lon, max_lon = get_bbox(rings)
        area = polygon_area_km2(rings)
        if area <= 0: area = 100.0

        if iso_a2 == 'PL' or name.lower() == 'poland':
            c_id = 1
            name = 'Polska'
            iso_a2 = 'PL'
            area = 312696.0
        else:
            c_id = next_country_id
            next_country_id += 1

        if iso_a2:
            country_iso_to_id[iso_a2] = c_id
        country_iso_to_id[props.get('ADM0_A3', '')] = c_id
        country_iso_to_id[props.get('SOV_A3', '')] = c_id

        blob = encode_geometry(rings, epsilon=0.005)
        country_rows.append((c_id, None, name, "country", iso_a2, area, min_lat, max_lat, min_lon, max_lon, blob))

    print(f"Processed {len(country_rows)} countries.")

    # 2. States / Provinces
    # Polish Voivodeships (IDs 10..25)
    # Other world states (IDs 2000..9999)
    print("Processing states & provinces...")
    with open('build_cache/states_10m.geojson', 'r', encoding='utf-8') as f:
        states_data = json.load(f)

    state_rows = []
    pl_teryt_to_state_id = {}
    next_state_id = 2000

    voivodeship_map = {
        'PL-MA': ('Małopolskie', '12', 101),
        'PL-MZ': ('Mazowieckie', '14', 102),
        'PL-SL': ('Śląskie', '24', 103),
        'PL-DS': ('Dolnośląskie', '02', 104),
        'PL-WP': ('Wielkopolskie', '30', 105),
        'PL-PM': ('Pomorskie', '22', 106),
        'PL-LD': ('Łódzkie', '10', 107),
        'PL-LU': ('Lubelskie', '06', 108),
        'PL-PK': ('Podkarpackie', '18', 109),
        'PL-KP': ('Kujawsko-pomorskie', '04', 110),
        'PL-ZP': ('Zachodniopomorskie', '32', 111),
        'PL-WN': ('Warmińsko-mazurskie', '28', 112),
        'PL-SK': ('Świętokrzyskie', '26', 113),
        'PL-PD': ('Podlaskie', '20', 114),
        'PL-OP': ('Opolskie', '16', 115),
        'PL-LB': ('Lubuskie', '08', 116),
    }

    for feat in states_data['features']:
        props = feat['properties']
        geom = feat['geometry']
        if not geom: continue
        rings = extract_rings(geom)
        if not rings: continue

        name = props.get('name') or props.get('NAME') or 'Unknown'
        iso_a2 = props.get('iso_a2') or ''
        iso_3166_2 = props.get('iso_3166_2') or ''
        parent_id = country_iso_to_id.get(iso_a2) or country_iso_to_id.get(props.get('adm0_a3', ''))

        min_lat, max_lat, min_lon, max_lon = get_bbox(rings)
        area = polygon_area_km2(rings)
        if area <= 0: area = 50.0

        if (iso_a2 == 'PL' or props.get('adm0_a3') == 'POL') and iso_3166_2 in voivodeship_map:
            name, teryt_prefix, fixed_id = voivodeship_map[iso_3166_2]
            s_id = fixed_id
            parent_id = 1
            pl_teryt_to_state_id[teryt_prefix] = s_id
        else:
            s_id = next_state_id
            next_state_id += 1

        blob = encode_geometry(rings, epsilon=0.003)
        state_rows.append((s_id, parent_id, name, "state", iso_3166_2 or None, area, min_lat, max_lat, min_lon, max_lon, blob))

    print(f"Processed {len(state_rows)} states/provinces. Mapped {len(pl_teryt_to_state_id)} Polish voivodeships.")

    # 3. Polish Cities & Gminas (IDs 20000..29999, Kraków=1001, Warszawa=1002)
    print("Processing Polish cities and gminas...")
    with open('globetrottr_backend/src/main/resources/data/poland_cities.geojson', 'r', encoding='utf-8') as f:
        pl_cities_data = json.load(f)

    city_rows = []
    next_city_id = 20000

    krakow_state_id = pl_teryt_to_state_id.get('12', 101)
    warsaw_state_id = pl_teryt_to_state_id.get('14', 102)

    seen_city_names = set()
    for feat in pl_cities_data['features']:
        props = feat['properties']
        geom = feat['geometry']
        if not geom: continue
        rings = extract_rings(geom)
        if not rings: continue

        name = props.get('JPT_NAZWA_') or 'Unknown'
        kod = str(props.get('JPT_KOD_JE', ''))
        teryt_prefix = kod[:2]
        parent_id = pl_teryt_to_state_id.get(teryt_prefix, 1)

        min_lat, max_lat, min_lon, max_lon = get_bbox(rings)
        area = polygon_area_km2(rings)
        if area <= 0:
            area_ha = float(props.get('JPT_POWIER', 0))
            area = area_ha / 100.0 if area_ha > 0 else 50.0

        if name == 'Kraków':
            c_id = 1001
            parent_id = krakow_state_id
            area = 326.8
        elif name == 'Warszawa':
            c_id = 1002
            parent_id = warsaw_state_id
            area = 517.2
        else:
            c_id = next_city_id
            next_city_id += 1

        blob = encode_geometry(rings, epsilon=0.001)
        city_rows.append((c_id, parent_id, name, "city", None, area, min_lat, max_lat, min_lon, max_lon, blob))

    print(f"Processed {len(city_rows)} Polish cities/gminas.")

    # 4. Kraków Municipal Districts (10001..10018)
    print("Adding Kraków 18 districts...")
    krakow_districts = [
        (10001, 1001, "Stare Miasto", "district", None, 5.57, 50.051, 50.072, 19.920, 19.955, None),
        (10002, 1001, "Grzegórzki", "district", None, 5.85, 50.052, 50.071, 19.955, 19.998, None),
        (10003, 1001, "Prądnik Czerwony", "district", None, 6.44, 50.075, 50.105, 19.955, 20.005, None),
        (10004, 1001, "Prądnik Biały", "district", None, 23.42, 50.080, 50.130, 19.880, 19.960, None),
        (10005, 1001, "Krowodrza", "district", None, 5.62, 50.065, 50.082, 19.895, 19.935, None),
        (10006, 1001, "Bronowice", "district", None, 9.56, 50.068, 50.098, 19.850, 19.900, None),
        (10007, 1001, "Zwierzyniec", "district", None, 28.73, 50.040, 50.075, 19.810, 19.925, None),
        (10008, 1001, "Dębniki", "district", None, 27.25, 49.985, 50.055, 19.820, 19.935, None),
        (10009, 1001, "Łagiewniki-Borek Fałęcki", "district", None, 5.42, 50.005, 50.035, 19.910, 19.945, None),
        (10010, 1001, "Swoszowice", "district", None, 25.60, 49.970, 50.015, 19.900, 19.970, None),
        (10011, 1001, "Podgórze Duchackie", "district", None, 9.54, 50.005, 50.028, 19.940, 19.980, None),
        (10012, 1001, "Bieżanów-Prokocim", "district", None, 18.47, 49.995, 50.040, 19.980, 20.060, None),
        (10013, 1001, "Podgórze", "district", None, 25.67, 50.015, 50.052, 19.935, 20.020, None),
        (10014, 1001, "Czyżyny", "district", None, 12.26, 50.055, 50.085, 19.995, 20.055, None),
        (10015, 1001, "Mistrzejowice", "district", None, 5.59, 50.080, 50.108, 19.995, 20.040, None),
        (10016, 1001, "Bieńczyce", "district", None, 3.70, 50.075, 50.095, 20.015, 20.050, None),
        (10017, 1001, "Wzgórza Krzesławickie", "district", None, 23.82, 50.080, 50.125, 20.040, 20.125, None),
        (10018, 1001, "Nowa Huta", "district", None, 65.41, 50.050, 50.115, 20.020, 20.220, None),
    ]

    # 5. Major World Cities (IDs 30000..99999)
    print("Processing world cities...")
    with open('build_cache/cities_10m.geojson', 'r', encoding='utf-8') as f:
        world_cities = json.load(f)

    w_city_rows = []
    next_wcity_id = 30000
    for feat in world_cities['features']:
        props = feat['properties']
        geom = feat['geometry']
        if not geom or geom['type'] != 'Point': continue
        lon, lat = geom['coordinates'][0], geom['coordinates'][1]
        name = props.get('NAME') or props.get('NAMEASCII') or 'Unknown'
        iso_a2 = props.get('ISO_A2') or ''
        if iso_a2 == 'PL': continue

        parent_id = country_iso_to_id.get(iso_a2)
        rank = props.get('SCALERANK', 5)
        delta = 0.10 if rank <= 2 else (0.06 if rank <= 4 else 0.03)
        area = 300.0 if rank <= 2 else (150.0 if rank <= 4 else 60.0)

        c_id = next_wcity_id
        next_wcity_id += 1
        w_city_rows.append((c_id, parent_id, name, "city", None, area, lat - delta, lat + delta, lon - delta, lon + delta, None))

    print(f"Processed {len(w_city_rows)} world cities.")

    # Insert into SQLite
    all_regions = country_rows + state_rows + city_rows + krakow_districts + w_city_rows
    print(f"Writing {len(all_regions)} total regions to {OUTPUT_DB}...")
    seen = {}
    for r in all_regions:
        if r[0] in seen:
            print(f"DUPLICATE ID {r[0]}: current={r[2]} ({r[3]}), previous={seen[r[0]][2]} ({seen[r[0]][3]})")
        seen[r[0]] = r
    cur.executemany("INSERT INTO regions VALUES (?,?,?,?,?,?,?,?,?,?,?)", all_regions)

    cur.execute("PRAGMA user_version = 2")
    conn.commit()
    print("Vacuuming...")
    cur.execute("VACUUM")
    conn.close()

    size_mb = os.path.getsize(OUTPUT_DB) / 1024 / 1024
    print(f"Database generated successfully in {time.time()-t0:.1f}s!")
    print(f"Final file size: {size_mb:.2f} MB")

if __name__ == '__main__':
    main()
