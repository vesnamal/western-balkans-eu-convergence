# Data Dictionary — Western Balkans → EU Convergence

Centralized reference for all project-owned objects in schema `s_vesnamalenica`. 
All objects are prefixed `wb_` for collision-safety in the shared schema; layer is indicated by prefix
(`wb_raw_` / `wb_stg_` / `wb_int_` / `wb_fct_`).

**Pipeline:** raw (Python ingestion) → staging (dbt views) → intermediate
(dbt view) → marts (dbt tables). Seeds are static reference CSVs loaded by dbt.

**Analysis window:** 2008–2024. **Country set:** 34 entities (6 Western Balkan,
EU-27, EUU benchmark aggregate; overlaps deduplicated).

---

## 1. Raw layer (tables — landed by Python ingestion)

Append-only. No primary key (dedup is a staging job). Null `value` rows are
**kept**: a null records "queried, returned nothing" = coverage information.

### `wb_raw_wdi` — World Bank WDI indicators (economic)
Source: World Bank WDI API (db=2) via `wbgapi`. Loaded by `ingestion/pull_wdi.py`.

| Column | Type | Description |
|---|---|---|
| `source` | text | Constant `'WDI'`. Provenance tag. |
| `indicator_code` | text | World Bank indicator code (e.g. `NY.GDP.PCAP.PP.KD`). |
| `country_iso3` | text | ISO3 country/entity code (e.g. `ALB`, `EUU`). |
| `year` | integer | Observation year (2008–2024). |
| `value` | double precision | Indicator value; **nullable** (null = no data for that country-year). |
| `ingested_at` | timestamptz | Row load timestamp (default `now()`). |
| `batch_id` | text | Ingestion batch ID (e.g. `wdi_20260630T093401Z`). Distinguishes pulls. |

### `wb_raw_wgi` — World Bank WGI governance scores
Source: World Bank WGI API (source=3) via raw `requests` (wbgapi cannot reach source=3). Loaded by `ingestion/pull_wgi.py`. Scores are absolute 0–100.

| Column | Type | Description |
|---|---|---|
| `source` | text | Constant `'WGI'`. Provenance tag. |
| `indicator_code` | text | WGI score code (`GOV_WGI_RL.SC`, `GOV_WGI_CC.SC`, `GOV_WGI_GE.SC`). |
| `country_iso3` | text | ISO3 code. `EUU` absent (WGI rates countries, not aggregates). |
| `year` | integer | Observation year (2008–2024). |
| `value` | double precision | Governance score 0–100; nullable. |
| `ingested_at` | timestamptz | Row load timestamp. |
| `batch_id` | text | Ingestion batch ID. |

---

## 2. Seeds (tables — static reference, loaded via `dbt seed`)

### `wb_country_roles` — country segmentation mapping
Theory-driven cohort assignment (NOT clustering). 34 rows.
Edited as a CSV (`seeds/wb_country_roles.csv`), the single editable source for roles and flags.

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | ISO3 code (primary key). |
| `country_name` | text | Readable country name. |
| `role` | text | Primary cohort: `western_balkan`, `recent_entrant`, `success_case`, `eu_core`, `eu_benchmark`. |
| `ex_yugoslav` | boolean | True for BIH, XKX, MNE, MKD, SRB, HRV, SVN. False for ALB (Western Balkan but never Yugoslav) and all others. |
| `eu_member` | boolean | True for all 27 EU members (incl. HRV/BGR/ROU as recent_entrant, SVN as success_case). False for the 6 WB and EUU. |

**Note on EUU:** included so every ISO3 in the data has a dimension row (avoids orphan join keys), but its boolean flags are `false` as a safe default and are treated as not-applicable in analysis (EUU is an aggregate, not a country).

### `wb_indicator_meta` — indicator classification
Tags each WDI indicator by how it should be read. 8 rows. CSV:
`seeds/wb_indicator_meta.csv`.

| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | World Bank indicator code (primary key). |
| `friendly_name` | text | Human-readable label. |
| `bucket` | text | Interpretation class: `convergence`, `context`, or `context_inverted`. |

**Bucket meanings:**
- `convergence` — level/ratio-scaled (GDP per capita, productivity). Gap-to-EU is a true convergence measure.
- `context` — already a share/percentage (investment, FDI, trade, labour participation). Gap-to-EU is descriptive context, not convergence.
- `context_inverted` — unemployment, youth unemployment. Descriptive, **and lower is better** (gap shrinking toward EU = improving).

---

## 3. Staging layer (views — dbt, cleaned/filtered)

One row per country-indicator-year. Latest batch only (filtered via `MAX(batch_id)`; 34-entity batch is a complete superset of the prior 11-entity one). Nulls kept. No joins, no metrics, no type casts (raw types
already clean).

### `wb_stg_wdi` — staged WDI
Built from `wb_raw_wdi`. 34 entities × 8 indicators × 17 years = 4,624 rows.

| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | World Bank indicator code. |
| `country_iso3` | text | ISO3 code. |
| `year` | integer | Observation year. |
| `value` | double precision | Indicator value; nullable. |

### `wb_stg_wgi` — staged WGI
Built from `wb_raw_wgi`. 33 entities × 3 scores × 17 years = 1,683 rows.

| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | WGI score code. |
| `country_iso3` | text | ISO3 code. |
| `year` | integer | Observation year. |
| `value` | double precision | Governance score 0–100; nullable. |

---

## 4. Intermediate layer (view — dbt, conformed dimension)

### `wb_int_country_dim` — conformed country dimension
The backbone everything downstream joins to. One row per entity (34), sourced from `wb_country_roles`. Roles/flags assigned in the seed, presented here as the conformed layer.

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | ISO3 code (join key). |
| `country_name` | text | Readable country name. |
| `role` | text | Cohort role (see `wb_country_roles`). |
| `ex_yugoslav` | boolean | Ex-Yugoslav flag. |
| `eu_member` | boolean | EU member flag. |

---

## 5. Marts layer (tables — dbt, analysis-ready)

### `wb_fct_gap_to_eu` — gap-to-EU fact
One row per country-indicator-year. Computes each entity's value as a percentage of the EUU benchmark (WB-derived; Eurostat EU27=100 cross-check deferred to a later sprint). Joins staging + country dimension + indicator meta.

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | ISO3 code. |
| `country_name` | text | Readable name (from dimension). |
| `role` | text | Cohort role. |
| `ex_yugoslav` | boolean | Ex-Yugoslav flag. |
| `eu_member` | boolean | EU member flag. |
| `indicator_code` | text | World Bank indicator code. |
| `friendly_name` | text | Indicator label (from meta). |
| `bucket` | text | Interpretation class (from meta). |
| `year` | integer | Observation year. |
| `value` | double precision | Country indicator value; nullable. |
| `eu_value` | double precision | EUU benchmark value for that indicator-year. |
| `gap_to_eu` | numeric | `value / eu_value × 100`, rounded to 2dp. Null if benchmark missing/zero. EUU rows = 100 by construction. |

### `wb_fct_stuck_matrix` — convergence status classification
One row per country-indicator. Classifies movement in `gap_to_eu` over 2014-2024 as `catching_up` / `stuck` / `falling_behind` / `no_data`.
Threshold: ±2 points over the decade (documented choice, tunable).
Bucket-aware: `convergence`/`context` treat rising gap as catch-up; `context_inverted` (unemployment) is **flipped** — a falling gap toward EU is catch-up. Null in either year: `no_data` (no forced classification).

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | ISO3 code. |
| `country_name` | text | Readable name. |
| `role` | text | Cohort role. |
| `ex_yugoslav` | boolean | Ex-Yugoslav flag. |
| `eu_member` | boolean | EU member flag. |
| `indicator_code` | text | World Bank indicator code. |
| `friendly_name` | text | Indicator label. |
| `bucket` | text | Interpretation class. |
| `gap_2014` | numeric | Gap-to-EU in 2014. |
| `gap_2024` | numeric | Gap-to-EU in 2024. |
| `gap_change` | numeric | `gap_2024 − gap_2014` (points). |
| `status` | text | `catching_up` / `stuck` / `falling_behind` / `no_data`. |

---

## Known coverage notes

- **Kosovo (XKX)** is asymmetric: productivity (`SL.GDP.PCAP.EM.KD`) entirely absent (17/17 null): excluded from the 6-country productivity analysis; but **complete on governance** (full 17-year WGI coverage). Treated differently in economic vs governance panels by design.
- Minor scattered labour-series gaps for Kosovo and Montenegro (2–4 years each).
- All 27 EU members are fully populated across all 8 WDI indicators.
- `EUU` has no WGI governance score (aggregate, not a country). This is expected.
- **Governance (WGI) is descriptive only:** absolute 0–100 scores, not ratio-scaled, so no gap-to-EU / years-to-close / sigma is applied to governance.