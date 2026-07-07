# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring real economic convergence of the 6 Western Balkan economies toward the EU, and identifying where each is stuck.

## Status
Pipeline built end-to-end and producing results. Raw ingestion (WDI + WGI, 34 entities) landed in PostgreSQL and verified; dbt staging, intermediate, and 5 marts built in `s_vesnamalenica`: `wb_fct_gap_to_eu`, `wb_fct_stuck_matrix`, `wb_fct_sigma_convergence`, `wb_fct_years_to_close`, and `wb_fct_governance`. The analysis notebook (`notebooks/01_analysis.ipynb`) reads the marts and produces the convergence findings, including the governance descriptive panel.

Testing is partial: `wb_fct_governance` has schema tests (not_null, accepted_values) plus a grain-uniqueness test, and `wb_fct_years_to_close` has a validity test. The other 3 marts are not yet tested: schema tests for them are planned before final submission.

Remaining work: the Tableau dashboard (not yet started), broader dbt test coverage, and the planned Eurostat cross-validation (see Data).

## Question
Are the Western Balkans converging toward the EU at the country level, and on which dimensions is each economy stuck (gap to EU flat or widening over the analysis window)?

## Countries
Albania, Bosnia & Herzegovina, Kosovo, Montenegro, North Macedonia, Serbia. Comparators: recent EU entrants Croatia, Bulgaria, Romania. Regional success case: Slovenia, the ex-Yugoslav economy that completed convergence and EU/eurozone accession; included on its own analytical axis as a trajectory endpoint, not a peer comparator. The EU aggregate (EUU) is used as the benchmark denominator (gap-to-EU as % of EU level).

Country roles are carried in the dbt country dimension via a `role` field (`western_balkan`, `success_case`, `recent_entrant`, plus the EU aggregate row). `role` is the discriminator used for all country-set filtering. The full EU-27 is included as a distributional backdrop, the six sit in the bottom tail of the EU distribution, not as part of the six-country sigma analysis.

## Data
- **World Bank API** (backbone): economic, trade, labour indicators via `wbgapi` (WDI, db=2).
- **Worldwide Governance Indicators** (source=3): governance, descriptive only, via raw requests.
- **Eurostat (planned)**: EU27=100 cross-validation. Motivation: the EUU aggregate's composition changed with Brexit, which may introduce a structural break in the benchmark; the Eurostat cross-check tests the gap-to-EU figures against an independent EU27=100 series. Not yet done.

The frozen, verified indicator basket lives in `config/indicators.yml` (single source of truth). Verification record: `notebooks/00_verify_codes.ipynb`.

## Coverage (raw layer, verified 2026-06-30)
- **WDI** (`wb_raw_wdi`): 8 indicators × 34 entities × 17 years. Missing observations kept as NULL rows, not dropped, a null records "queried, returned nothing," which is itself coverage information. Verified gaps are confined to the Western Balkans: Kosovo productivity entirely absent (17/17 null), plus minor scattered labour-series gaps for Kosovo and Montenegro. All 27 EU members are fully populated across all 8 indicators. Check: `sql/wb_raw_coverage_check.sql`.
- **WGI** (`wb_raw_wgi`): 3 scores × 33 entities × 17 years, fully balanced (zero nulls). EUU is absent (WGI rates countries, not aggregates), expected and harmless for a country-level governance story. Check: `sql/wb_raw_wgi_coverage_check.sql`.

Kosovo (XKX) is asymmetric: thin on economics (productivity entirely absent -> 5-country only, excluded from 6-country sigma) but complete on governance (full coverage, no caveat). The economic and governance panels treat Kosovo differently for this reason, and this asymmetry is reported as a finding rather than masked.

## Analysis windows
Two windows, used deliberately for different purposes:
- **2008–2024**: the descriptive convergence-path chart. Shows the full trajectory, that catch-up predates 2014, and that the country ranking is stable over the longer run. A general-introduction view, not a measured result.
- **2014–2024** — the convergence metrics (sigma-convergence, years-to-close, stuck-matrix). The measured decade over which gaps, dispersion, and closing rates are computed.

See the notebook's scope section.

## Stack
Python (ingestion)-> PostgreSQL (raw/staging/marts) -> dbt (transform + tests) -> Tableau (dashboard, in progress).

## Repo layout
    config/          indicators.yml - single source of truth
    ingestion/       per-source Python ingestion (WDI, WGI)
    models/          dbt: staging / intermediate / marts
    macros/          dbt: generate_schema_name guardrail + helpers
    seeds/           dbt: reference CSVs (country roles, indicator meta)
    tests/           dbt: singular tests (grain / validity guards)
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
5. Build the dbt models: from the project root, `dbt seed` then `dbt build`. Output lands in schema `s_vesnamalenica`.
6. Run the analysis: open `notebooks/01_analysis.ipynb` and run all cells. It reads the marts directly from the database and produces the findings and charts.

## Reproducibility notes
This is an open-data pipeline: every source is publicly accessible via API, but a few things a re-runner needs are, by design, not in the repo:
- **Database.** Development used a shared course PostgreSQL instance with temporary access; to reproduce independently, point `.env` at any PostgreSQL database (local or hosted). The pipeline is warehouse-agnostic PostgreSQL, no instance-specific features are used.
- **Credentials.** `.env` is gitignored and never committed. Use `.env.example` as the template.
- **dbt.** Models were developed in dbt Cloud, but the project is standard dbt and runs identically under dbt Core (`dbt build` from the repo root) against any connected PostgreSQL, dbt Cloud is not required.
- **Source APIs.** Ingestion depends on the World Bank WDI/WGI APIs being reachable at run time. The frozen indicator basket (`config/indicators.yml`) fixes what is pulled; the APIs supply the values.

## Key methodology notes
- **Labour:** national estimates, not modeled-ILO (modeled is empty for Kosovo).
- **Productivity:** 5-country (Kosovo absent); excluded from 6-country dispersion.
- **Governance:** absolute 0–100 score (2025 WGI revision; old `*.PER.RNK` codes retired), descriptive only: no gap-to-EU / years-to-close / sigma, since the scores are standardised, not ratio-scaled.
- **Years-to-close:** current-pace extrapolation from the 2014–2024 OLS slope, explicitly not a forecast, convergence decelerates near the frontier, and 6 countries cannot support prediction intervals. Large values are the finding, not a failure.
- **Innovation dimension dropped:** unmeasurable for Kosovo on comparable data (documented).

## Limitations

This is a descriptive, small-sample study of open secondary data. The main limitations, and how each is handled:

- **Small sample (n = 6).** Six economies cannot support inferential statistics, no significance tests, confidence intervals, or prediction intervals are meaningful at this size. Handled by keeping the analysis descriptive: gaps, dispersion, and closing rates are reported as observed quantities, not estimated with error bars. Beta-convergence regression is treated as secondary and illustrative only.

- **Years-to-close is extrapolation, not forecast.** The figures divide the remaining 2024 gap by the 2014–2024 OLS slope, assuming that pace holds. Real convergence decelerates near the frontier, so these values, if anything, understate how hard the final stretch is. Stated explicitly throughout as current-pace extrapolation; large values are read as "effectively not converging on any meaningful horizon" not as literal predictions.

- **Single source, and EU-benchmark composition.** The economic indicators come almost entirely from World Bank WDI, with no independent triangulation. On top of this, the gap-to-EU denominator uses the World Bank EUU aggregate, whose composition changed when the UK left the EU, a possible structural break in the benchmark across the window. Both are addressed by the same planned step: an Eurostat EU27=100 cross-validation, testing the gap figures against an independent, fixed-composition series. Not yet done; flagged as pending.

- **Kosovo data asymmetry.** Kosovo has no World Bank productivity series (17/17 null) and scattered labour-series gaps, but complete governance coverage. Rather than drop or impute, Kosovo is excluded from the 5-country productivity and 6-country sigma analyses and retained everywhere it has data. The asymmetry is reported as a finding, not masked.

- **Association, not causation.** Any co-occurrence between governance and economic convergence (for example, fast income catch-up alongside weak corruption control) is described, not explained. No governance-on-convergence regression is run, with n = 6 it would invite causal over-reading the data cannot support.

- **Governance not ratio-scaled.** WGI scores are standardised 0–100, not ratio measures, so the gap-to-EU / sigma / years-to-close machinery does not apply to them. Governance is presented on its own descriptive axis and cannot be integrated with the economic metrics on a common basis, a boundary on how far the 2 stories can be quantitatively combined, treated as such rather than worked around.

- **Labour estimates.** National labour estimates are used rather than modeled-ILO series, because the modeled series is empty for Kosovo. This keeps Kosovo in the labour analysis but means the labour figures are not harmonised to the ILO modeled basis, which can differ across countries.