# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring **real economic convergence** of the six
Western Balkan economies toward the EU, and identifying where each is **stuck**.

> **Status:** Sprint 1 in progress. Raw ingestion layer built and verified
> (World Bank WDI + WGI landed in PostgreSQL). Staging/marts next.

## Question
Are the Western Balkans converging toward the EU at the country level, and on which
dimensions is each economy stuck (gap to EU flat or widening over the recent 10 years)?

## Countries
Albania, Bosnia & Herzegovina, Kosovo, Montenegro, North Macedonia, Serbia.
Benchmarks: EU aggregate (`EUU`) + recent entrants Croatia, Bulgaria, Romania.
Regional success case: Slovenia — the ex-Yugoslav economy that completed
convergence and EU/eurozone accession; included on its own analytical axis as a
trajectory endpoint, not a peer comparator.

## Data
- **World Bank API** (backbone) — economic, trade, labour indicators via `wbgapi` (WDI, db=2).
- **Worldwide Governance Indicators** (source=3) — governance, descriptive only, via raw requests.
- **Eurostat** (planned, Sprint 3) — EU27=100 cross-validation.

The frozen, verified indicator basket lives in [`config/indicators.yml`](config/indicators.yml)
(single source of truth). Verification record: [`notebooks/00_verify_codes.ipynb`](notebooks/00_verify_codes.ipynb).

### Coverage (raw layer, verified 2026-06-27)
- **WDI** (`wb_raw_wdi`): 8 indicators × 11 economies × 17 years. Missing
  observations kept as `NULL` rows, not dropped — a null records "queried,
  returned nothing," which is itself coverage information. Check:
  [`sql/wb_raw_coverage_check.sql`](sql/wb_raw_coverage_check.sql).
- **WGI** (`wb_raw_wgi`): 3 scores × 10 economies × 17 years, fully balanced
  (zero nulls). `EUU` is absent (WGI rates countries, not aggregates) — expected.
  Check: [`sql/wb_raw_wgi_coverage_check.sql`](sql/wb_raw_wgi_coverage_check.sql).

**Kosovo (XKX) is asymmetric:** thin on economics (productivity entirely absent →
five-country only, excluded from six-country sigma) but *complete* on governance
(full 17-year coverage, no caveat). The economic and governance panels treat
Kosovo differently for this reason.

## Analysis window
**2008–2024**, common across all six (Kosovo data begins ~2008). See notebook Step 2.

## Stack
Python (ingestion) → PostgreSQL (raw/staging/marts) → dbt (transform + tests) → Tableau (dashboard).

## Repo layout
​```
config/        indicators.yml — single source of truth
ingestion/     per-source Python (Sprint 1)
dbt/           staging / intermediate / marts (Sprint 1+)
sql/           raw schema + coverage checks
tableau/       packaged workbook
docs/          proposal, methodology, limitations
notebooks/     verification & exploration
​```

## Setup

1. Create and activate a virtual environment, then `pip install -r requirements.txt`.
2. Copy `.env.example` to `.env` and fill in PostgreSQL credentials (`.env` is gitignored).
3. Create the raw tables: run [`sql/raw_ddl.sql`](sql/raw_ddl.sql) against the database once.
4. Land the raw data: `python ingestion/pull_wdi.py` then `python ingestion/pull_wgi.py`.
5. *(dbt transform + Tableau steps — to come.)*

## Key methodology notes
- Labour: **national** estimates, not modeled-ILO (modeled is empty for Kosovo).
- Productivity: 5-country (Kosovo absent); excluded from 6-country dispersion.
- Governance: absolute 0–100 score (2025 WGI revision; old `*.PER.RNK` codes retired),
  descriptive only — no gap-to-EU / years-to-close / sigma.
- Innovation dimension dropped: unmeasurable for Kosovo on comparable data (documented).