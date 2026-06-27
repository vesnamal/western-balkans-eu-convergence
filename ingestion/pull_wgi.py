"""Pull WGI governance scores (source=3) via raw requests, land into wb_raw_wgi.
wbgapi cannot reach source=3, so we hand-build the WB Indicators API v2 call.
Append-only. Logs one line per response: source, codes, row count, timestamp.
"""
from datetime import datetime, timezone
import requests
import pandas as pd

from config import load_config, get_window, get_countries, get_wgi_indicators
from db import get_engine

SCHEMA = "s_vesnamalenica"
TABLE = "wb_raw_wgi"
SOURCE = "WGI"
BASE = "https://api.worldbank.org/v2"


def pull_wgi():
    cfg = load_config()
    start, end = get_window(cfg)
    countries = get_countries(cfg)
    indicators = get_wgi_indicators(cfg)
    codes = [i["code"] for i in indicators]

    batch_id = f"wgi_{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
    engine = get_engine()

    country_path = ";".join(countries)
    code_path = ";".join(codes)
    url = f"{BASE}/country/{country_path}/indicator/{code_path}"
    params = {
        "source": 3,                 # mandatory for WGI
        "format": "json",
        "date": f"{start}:{end}",     # explicit window, not mrv (avoids sliding panel)
        "per_page": 20000,            # high enough to avoid pagination for this volume
    }

    print(f"=== WGI pull | batch {batch_id} ===")
    resp = requests.get(url, params=params, timeout=60)
    resp.raise_for_status()
    payload = resp.json()

    # WB returns [metadata, [rows]]. On a bad param it returns [{'message': ...}]
    # with no second element — guard before touching payload[1].
    if not isinstance(payload, list) or len(payload) < 2 or payload[1] is None:
        print(f"  ERROR: unexpected response. Head: {payload[0]}")
        return

    meta = payload[0]
    rows = payload[1]
    pages = meta.get("pages", 1)
    if pages and pages > 1:
        print(f"  WARN: {pages} pages exist but only page 1 fetched. "
              f"Raise per_page or add pagination.")

    records = []
    for row in rows:
        records.append({
            "source": SOURCE,
            "indicator_code": row["indicator"]["id"],
            "country_iso3": row.get("countryiso3code"),
            "year": int(row["date"]) if row.get("date") else None,
            "value": row.get("value"),
            "batch_id": batch_id,
        })

    if not records:
        print("  WARN: 0 rows returned")
        return

    df = pd.DataFrame(records)
    df.to_sql(TABLE, engine, schema=SCHEMA, if_exists="append", index=False)
    ts = datetime.now(timezone.utc).isoformat()
    print(f"  {SOURCE} {len(codes)} codes x {len(countries)} countries: "
          f"{len(df)} rows @ {ts}")
    print(f"=== WGI pull complete: {len(df)} rows total ===")


if __name__ == "__main__":
    pull_wgi()