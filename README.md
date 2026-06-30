# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring real economic convergence of the six Western Balkan economies toward the EU, and identifying where each is stuck.

Status: Sprint 1 in progress. Raw ingestion layer complete and verified across both sources at the full 34-entity country set (World Bank WDI + WGI landed in PostgreSQL). dbt Cloud connected to the RDS, project initialized and configured. Staging models next.

## Question

Are the Western Balkans converging toward the EU at the country level, and on which dimensions is each economy stuck (gap to EU flat or widening over the recent 10 years)?

## Countries

Albania, Bosnia & Herzegovina, Kosovo, Montenegro, North Macedonia, Serbia. Benchmarks: EU aggregate (`EUU`) + recent entrants Croatia, Bulgaria, Romania. Regional success case: Slovenia — the ex-Yugoslav economy that completed convergence and EU/eurozone accession; included on its own analytical axis as a trajectory endpoint, not a peer comparator.

The full EU-27 is included as a comparator backdrop (entity-count robustness and a distributional story — the six sit in the bottom tail of the EU distribution), **not** as part of the six-country sigma. The 23 EU members not already listed above live under `eu_members` in the config; the `eu_member` flag for all 27 is applied in the dbt country dimension, not the ingestion manifest.

## Data

* World Bank API (backbone) — economic, trade, labour indicators via `wbgapi` (WDI, db=2).
* Worldwide Governance Indicators (source=3) — governance, descriptive only, via raw requests.
* Eurostat (planned, Sprint 3) — EU27=100 cross-validation.

The frozen, verified indicator basket lives in `config/indicators.yml` (single source of truth). Verification record: `notebooks/00_verify_codes.ipynb`.

## Coverage (raw layer, verified 2026-06-30)

* WDI (`wb_raw_wdi`): 8 indicators × 34 entities × 17 years. Missing observations kept as `NULL` rows, not dropped — a null records "queried, returned nothing," which is itself coverage information. Verified gaps are confined to the Western Balkans: Kosovo productivity entirely absent (17/17 null), plus minor scattered labour-series gaps for Kosovo and Montenegro. All 27 EU members are fully populated across all 8 indicators. Check: `sql/wb_raw_coverage_check.sql`.
* WGI (`wb_raw_wgi`): 3 scores × 33 entities × 17 years, fully balanced (zero nulls). `EUU` is absent (WGI rates countries, not aggregates) — expected and harmless for a country-level governance story. Check: `sql/wb_raw_wgi_coverage_check.sql`.

Kosovo (XKX) is asymmetric: thin on economics (productivity entirely absent → five-country only, excluded from six-country sigma) but complete on governance (full 17-year coverage, no caveat). The economic and governance panels treat Kosovo differently for this reason.

## Analysis window

2008–2024, common across all six (Kosovo data begins ~2008). See notebook Step 2.

## Stack

Python (ingestion) → PostgreSQL (raw/staging/marts) → dbt (transform + tests) → Tableau (dashboard).

## Repo layout

    config/          indicators.yml — single source of truth
    ingestion/       per-source Python (Sprint 1)
    models/          dbt: staging / intermediate / marts (Sprint 1+)
    macros/          dbt: generate_schema_name guardrail + helpers
    dbt_project.yml  dbt project config (root-level)
    sql/             raw schema + coverage checks
    tableau/         packaged workbook
    docs/            proposal, methodology, limitations
    notebooks/       verification & exploration

The dbt project is initialized at the repo root (not in a subdirectory). All models use a `wb_` name prefix for collision-safety in the shared course schema; a `generate_schema_name` macro override forces all output into the single target schema `s_vesnamalenica` (no CREATE SCHEMA rights on the shared RDS).

## Setup

1. Create and activate a virtual environment, then `pip install -r requirements.txt`.
2. Copy `.env.example` to `.env` and fill in PostgreSQL credentials (`.env` is gitignored).
3. Create the raw tables: run `sql/raw_ddl.sql` against the database once.
4. Land the raw data: `python ingestion/pull_wdi.py` then `python ingestion/pull_wgi.py`.
5. (dbt transform + Tableau steps — to come.)

## Key methodology notes

* Labour: national estimates, not modeled-ILO (modeled is empty for Kosovo).
* Productivity: 5-country (Kosovo absent); excluded from 6-country dispersion.
* Governance: absolute 0–100 score (2025 WGI revision; old `*.PER.RNK` codes retired), descriptive only — no gap-to-EU / years-to-close / sigma.
* Innovation dimension dropped: unmeasurable for Kosovo on comparable data (documented).