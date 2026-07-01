# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring real economic convergence of the six Western Balkan economies toward the EU, and identifying where each is stuck.

Status: Pipeline built end-to-end and producing results. Raw ingestion (WDI + WGI, 34 entities) landed in PostgreSQL and verified; dbt staging, intermediate, and the first mart models (`wb_fct_gap_to_eu`, `wb_fct_stuck_matrix`) built and tested in `s_vesnamalenica`; analysis notebook (`notebooks/01_analysis.ipynb`) produces the convergence findings and visualizations. Remaining work: additional KPI marts (sigma-convergence, years-to-close), a governance descriptive view, and the Tableau dashboard.

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

2008–2024, common across all six (Kosovo data begins ~2008). See the notebook's scope section.

## Stack

Python (ingestion) → PostgreSQL (raw/staging/marts) → dbt (transform + tests) → Tableau (dashboard).

## Repo layout

    config/          indicators.yml — single source of truth
    ingestion/       per-source Python ingestion (WDI, WGI)
    models/          dbt: staging / intermediate / marts
    macros/          dbt: generate_schema_name guardrail + helpers
    seeds/           dbt: reference CSVs (country roles, indicator meta)
    dbt_project.yml  dbt project config (root-level)
    sql/             raw schema DDL + coverage checks
    docs/            data_dictionary.md
    notebooks/       00_verify_codes (indicator verification), 01_analysis (findings)
    tableau/         packaged workbook (in progress)

The dbt project is initialized at the repo root (not in a subdirectory). All models use a `wb_` name prefix for collision-safety in the shared course schema; a `generate_schema_name` macro override forces all output into the single target schema `s_vesnamalenica`.

## Setup

1. Create and activate a virtual environment, then `pip install -r requirements.txt`.
2. Copy `.env.example` to `.env` and fill in PostgreSQL credentials (`.env` is gitignored).
3. Create the raw tables: run `sql/raw_ddl.sql` against the database once.
4. Land the raw data: `python ingestion/pull_wdi.py` then `python ingestion/pull_wgi.py`.
5. Build the dbt models: from the project root, `dbt seed` (loads the reference CSVs), then `dbt build` (runs and tests staging → intermediate → marts). Output lands in schema `s_vesnamalenica`.
6. Run the analysis: open `notebooks/01_analysis.ipynb` and run all cells. It reads the marts directly from the database and produces the findings and charts.

## Reproducibility notes

This is an open-data pipeline — every source is publicly accessible via API — but a few things a re-runner needs are, by design, not in the repo:

* **Database.** Development used a shared course PostgreSQL instance. Access to that instance is temporary; to reproduce independently, point `.env` at any PostgreSQL database (local or hosted). The pipeline is warehouse-agnostic PostgreSQL — no instance-specific features are used.
* **Credentials.** `.env` (database connection) is gitignored and never committed. Use `.env.example` as the template.
* **dbt.** Models were developed in dbt Cloud, but the project is standard dbt and runs identically under dbt Core (`dbt build` from the repo root) against any connected PostgreSQL — dbt Cloud is not required to reproduce the transformations.
* **Source APIs.** Ingestion depends on the World Bank WDI/WGI APIs being reachable at run time. The frozen indicator basket (`config/indicators.yml`) fixes *what* is pulled; the APIs supply the values.

## Key methodology notes

* Labour: national estimates, not modeled-ILO (modeled is empty for Kosovo).
* Productivity: 5-country (Kosovo absent); excluded from 6-country dispersion.
* Governance: absolute 0–100 score (2025 WGI revision; old `*.PER.RNK` codes retired), descriptive only — no gap-to-EU / years-to-close / sigma.
* Innovation dimension dropped: unmeasurable for Kosovo on comparable data (documented).