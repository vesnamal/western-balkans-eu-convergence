# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring **real economic convergence** of the six
Western Balkan economies toward the EU, and identifying where each is **stuck**.

> **Status:** Sprint 0 (setup & verification) complete. Pipeline not yet built.

## Question
Are the Western Balkans converging toward the EU at the country level, and on which
dimensions is each economy stuck (gap to EU flat or widening over the recent 10 years)?

## Countries
Albania, Bosnia & Herzegovina, Kosovo, Montenegro, North Macedonia, Serbia.
Benchmarks: EU aggregate (`EUU`) + recent entrants Croatia, Bulgaria, Romania.

## Data
- **World Bank API** (backbone) — economic, trade, labour indicators via `wbgapi` (WDI, db=2).
- **Worldwide Governance Indicators** (source=3) — governance, descriptive only, via raw requests.
- **Eurostat** (planned, Sprint 3) — EU27=100 cross-validation.

The frozen, verified indicator basket lives in [`config/indicators.yml`](config/indicators.yml)
(single source of truth). Verification record: [`notebooks/00_verify_codes.ipynb`](notebooks/00_verify_codes.ipynb).

## Analysis window
**2008–2024**, common across all six (Kosovo data begins ~2008). See notebook Step 2.

## Stack
Python (ingestion) → PostgreSQL (raw/staging/marts) → dbt (transform + tests) → Tableau (dashboard).

## Repo layout
​```
config/        indicators.yml — single source of truth
ingestion/     per-source Python (Sprint 1)
dbt/           staging / intermediate / marts (Sprint 1+)
sql/           raw schema setup
tableau/       packaged workbook
docs/          proposal, methodology, limitations
notebooks/     verification & exploration
​```

## Setup
*(To be completed in Sprint 1 — DB, env, dbt, run order.)*

## Key methodology notes
- Labour: **national** estimates, not modeled-ILO (modeled is empty for Kosovo).
- Productivity: 5-country (Kosovo absent); excluded from 6-country dispersion.
- Governance: absolute 0–100 score (2025 WGI revision; old `*.PER.RNK` codes retired),
  descriptive only — no gap-to-EU / years-to-close / sigma.
- Innovation dimension dropped: unmeasurable for Kosovo on comparable data (documented).