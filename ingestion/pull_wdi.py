"""Pull WDI indicators (db=2) via wbgapi, land long rows into wb_raw_wdi.
Append-only. Logs one line per indicator: source, code, row count, timestamp.
"""
from datetime import datetime, timezone
import pandas as pd
import wbgapi as wb

from config import load_config, get_window, get_countries, get_wdi_indicators
from db import get_engine

SCHEMA = "s_vesnamalenica"
TABLE = "wb_raw_wdi"
SOURCE = "WDI"


def pull_wdi():
    cfg = load_config()
    start, end = get_window(cfg)
    countries = get_countries(cfg)
    indicators = get_wdi_indicators(cfg)
    years = range(start, end + 1)

    batch_id = f"wdi_{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
    engine = get_engine()

    print(f"=== WDI pull | batch {batch_id} ===")
    total_rows = 0

    for ind in indicators:
        code = ind["code"]
        records = []
        # fetch() yields one dict per country-year, including missing values
        # as None. Keeping them: a null row records "asked, got nothing" —
        # which is the documented coverage gap (e.g. Kosovo productivity).
        for row in wb.data.fetch(code, economy=countries, time=years):
            val = row.get("value")
            econ = row.get("economy")
            yr = row.get("time")
            # wbgapi returns time like 'YR2008'; strip to int
            if isinstance(yr, str) and yr.startswith("YR"):
                yr = int(yr[2:])
            records.append({
                "source": SOURCE,
                "indicator_code": code,
                "country_iso3": econ,
                "year": yr,
                "value": val,
                "batch_id": batch_id,
            })

        if not records:
            print(f"  WARN {code}: 0 rows returned")
            continue

        df = pd.DataFrame(records)
        df.to_sql(TABLE, engine, schema=SCHEMA, if_exists="append", index=False)
        ts = datetime.now(timezone.utc).isoformat()
        print(f"  {SOURCE} {code}: {len(df)} rows @ {ts}")
        total_rows += len(df)

    print(f"=== WDI pull complete: {total_rows} rows total ===")


if __name__ == "__main__":
    pull_wdi()