# Western Balkans → EU Convergence

A reproducible ELT pipeline measuring real economic convergence of the six Western Balkan economies toward the EU over 2014–2024, and identifying where each economy is stuck.

**Question:** Are the Western Balkans converging toward the EU at the country level, and on which dimensions is each economy stuck — its gap to the EU flat or widening over the decade?

## Key findings

All figures are computed in the marts and reproduced in `notebooks/01_analysis.ipynb`. Gap-to-EU is each country's value as a percentage of the EU (EUU) benchmark; a slope is the OLS fit through the 2014–2024 gap-to-EU series.

- **Every economy is catching up on income, but not by the same amount.** All six narrowed their GDP-per-capita gap to the EU over 2014–2024, by +4.8 to +11.1 points. Albania (+11.1) and Serbia (+10.9) lead; **North Macedonia is slowest at +4.8** and is the most-stuck economy overall.

- **Income is converging far faster than productivity, nearly three times faster.** Mean GDP-per-capita gain across the six is 8.69 points against 3.19 for productivity. Income can rise through remittances, consumption, and workers moving out of unemployment; productivity is what makes catch-up durable, and it has barely moved.

- **Productivity convergence is a century-plus proposition where it is happening at all.** At the current decade's pace, closing the productivity gap takes 106 years (Bosnia), 128 (Montenegro), 145 (Albania), and 146 (Serbia). North Macedonia's productivity slope is statistically flat (0.009 points/year — effectively not converging), and Kosovo has no World Bank productivity series at all.

- **GDP-per-capita closing times span a threefold range.** Serbia closes in 43 years, Bosnia 71, Montenegro 82, Kosovo 96, and North Macedonia 130 — the clear outlier on the slow end. These are current-pace extrapolations, not forecasts (see Methodology).

- **Montenegro's unemployment divergence reversed.** On the full-window slope Montenegro diverges on both unemployment measures, but this masks a turnaround: the total-unemployment gap rose steadily from 2014, peaked in 2020, then narrowed every year through 2024. The rise predates COVID by six years, so it is not COVID-caused despite the timing.

- **Governance does not track EU membership.** Below Slovenia (clearly ahead on all three WGI scores), the ranking stops following who is already in the EU. Montenegro, a candidate, out-scores Bulgaria (an EU member since 2007) on rule of law in every year 2014–2024; Kosovo passed Bulgaria in 2024. Separately, Serbia is the fastest income converger yet has the weakest control-of-corruption score of all ten countries — a corruption story specifically, not general governance failure.

## Countries

Albania, Bosnia & Herzegovina, Kosovo, Montenegro, North Macedonia, Serbia. Comparators: recent EU entrants Croatia, Bulgaria, Romania. Regional success case: Slovenia, the ex-Yugoslav economy that completed convergence and EU/eurozone accession, included as a trajectory endpoint, not a peer comparator. The EU aggregate (EUU) is the benchmark denominator (gap-to-EU as a percentage of the EU level).

Country roles are carried in the dbt country dimension via a `role` field (`western_balkan`, `success_case`, `recent_entrant`, `eu_core`, and the EU aggregate row). `role` is the discriminator for all country-set filtering. The full EU-27 is included as a distributional backdrop; the six sit in the bottom tail of the EU distribution, not as part of the six-country sigma analysis.

## Status

Pipeline built end-to-end and producing verified results.

- **Ingestion:** WDI + WGI landed in PostgreSQL, coverage verified (see Coverage).
- **Transform:** dbt staging, intermediate, and five marts built in `s_vesnamalenica`: `wb_fct_gap_to_eu`, `wb_fct_stuck_matrix`, `wb_fct_sigma_convergence`, `wb_fct_years_to_close`, `wb_fct_governance`. Full `dbt build` passes with **78 tests across all 5 marts** — `accepted_values`, `not_null`, grain-uniqueness, and singular validity guards. Tests cover bucket classifications, indicator and role sets, the 5-vs-6-country sigma split, and years-to-close status consistency.
- **Analysis:** `notebooks/01_analysis.ipynb` reads the marts and produces the convergence findings and the governance descriptive panel.
- **Tableau:** five interactive dashboards built off the same marts (consistency-passed); a narrative Story assembled from them, with final visual polish (unified palette, cover page) in progress.

## Data

- **World Bank WDI** (backbone): economic, trade, and labour indicators via `wbgapi` (source db=2).
- **Worldwide Governance Indicators** (source=3): governance scores, descriptive only, pulled via raw `requests` because `wbgapi` cannot reach source=3.

The frozen, verified indicator basket lives in `config/indicators.yml` (single source of truth). Verification record: `notebooks/00_verify_codes.ipynb`.

The gap-to-EU denominator uses the World Bank EUU aggregate. Its composition changed when the UK left the EU, raising the possibility of a structural break in the benchmark. This was checked directly: the EUU series is smooth across the window on all four convergence-metric indicators, with no compositional discontinuity, so Brexit is not a confound here. 

## Coverage

The raw layer is **append-only with two ingestion batches** for each source; staging selects the newest batch (`max(batch_id)`), guarded by staging row-count tests. Row counts below are the full append-only tables; the per-batch analysis grid is noted alongside.

- **WDI** (`wb_raw_wdi`): 8 indicators × 34 entities × 17 years (2008–2024) per batch; 6,120 rows total across batches, 56 nulls. Missing observations are kept as NULL rows rather than dropped: a null records "queried, returned nothing," which is itself coverage information. Verified gaps are confined to the Western Balkans: Kosovo productivity entirely absent (17/17 null), plus minor scattered labour-series gaps for Kosovo and Montenegro. All 27 EU members are fully populated. Check: `sql/wb_raw_coverage_check.sql`.
- **WGI** (`wb_raw_wgi`): 3 scores × 33 entities × 17 years per batch; 2,193 rows total, **zero nulls**. EUU is absent (WGI rates countries, not aggregates); expected and harmless for a country-level governance story. Check: `sql/wb_raw_wgi_coverage_check.sql`.

The deduplicated analysis marts are clean grids: `wb_fct_gap_to_eu` is 4,624 rows (8 × 34 × 17), and `wb_fct_governance` is 330 rows (10 countries × 3 scores × 11 years, 2014–2024).

Kosovo (XKX) is asymmetric: thin on economics (productivity entirely absent, so productivity is 5-country and Kosovo is excluded from the 6-country sigma) but complete on governance. The two panels treat Kosovo differently for this reason, and the asymmetry is reported as a finding rather than masked.

## Analysis windows

Two windows, used deliberately:

- **2008–2024** — the descriptive convergence-path chart. Shows the full trajectory, that catch-up predates 2014, and that the country ranking is stable over the longer run. An introduction view, not a measured result.
- **2014–2024** — the convergence metrics (gap-to-EU deltas, sigma-convergence, years-to-close, stuck-matrix). The measured decade.

## Methodology notes

- **Gap-to-EU:** country value as a percentage of the EU (EUU) benchmark, per indicator per year.
- **Stuck-matrix / years-to-close:** OLS slope over 2014–2024 (endpoint deltas rejected — a single distorted year, e.g. Montenegro's 2021 productivity spike, showed how fragile endpoint methods are). Asymmetric deadbands classify direction of travel: ±0.2 points/year for income and productivity, ±2.0 points/year for unemployment, because unemployment slopes run about 6× larger in magnitude (mean |slope| 5.54 vs 0.91).
- **Years-to-close** is current-pace extrapolation, **explicitly not a forecast**: remaining 2024 gap divided by the decade slope. Convergence decelerates near the frontier, so these values, if anything, understate how hard the final stretch is; large values read as "effectively not converging on any meaningful horizon," not as literal predictions. `status` and `closure_status` are always shown together (Romania is already-closed-but-diverging; the proof case).
- **Sigma-convergence:** coefficient of variation of gap-to-EU across the six, per indicator per year; falling CV means the group is tightening. Productivity runs 5-country (Kosovo absent).
- **Governance:** absolute 0–100 WGI scores (2025 revision; old `*.PER.RNK` codes retired), **descriptive only** — no gap / sigma / years-to-close applied, because the scores are standardised, not ratio-scaled.

Full methodology reasoning, sensitivity checks, and per-finding detail are in the notebook prose.

## Stack

Python (ingestion) → PostgreSQL (raw / staging / marts) → dbt (transform + tests) → Tableau (dashboard).

## Repo layout

    config/          indicators.yml — single source of truth
    ingestion/       per-source Python ingestion (WDI, WGI)
    models/          dbt: staging / intermediate / marts
    macros/          dbt: generate_schema_name guardrail + helpers
    seeds/           dbt: reference CSVs (country roles, indicator meta)
    tests/           dbt: singular tests (grain / validity guards)
    dbt_project.yml  dbt project config (root-level)
    sql/             raw schema DDL + coverage checks
    docs/            data_dictionary.md, impact_and_recommendations.md
    notebooks/       00_verify_codes (indicator verification), 01_analysis (findings)
    tableau/         packaged workbook

The dbt project is initialized at the repo root. All models use a `wb_` name prefix for collision-safety in the shared course schema; a `generate_schema_name` macro override forces all output into the single target schema `s_vesnamalenica`.

## Setup

1. Create and activate a virtual environment, then `pip install -r requirements.txt`.
2. Copy `.env.example` to `.env` and fill in PostgreSQL credentials (`.env` is gitignored).
3. Create the raw tables: run `sql/raw_ddl.sql` against the database once.
4. Land the raw data: `python ingestion/pull_wdi.py` then `python ingestion/pull_wgi.py`.
5. Build the dbt models: from the project root, `dbt seed` then `dbt build`. Output lands in schema `s_vesnamalenica`.
6. Run the analysis: open `notebooks/01_analysis.ipynb` and run all cells. It reads the marts directly from the database and produces the findings and charts.

## Reproducibility notes

Open-data pipeline: every source is publicly accessible via API, but a few things a re-runner needs are, by design, not in the repo.

- **Database.** Development used a shared course PostgreSQL instance with temporary access; to reproduce independently, point `.env` at any PostgreSQL database. The pipeline is warehouse-agnostic PostgreSQL — no instance-specific features.
- **Credentials.** `.env` is gitignored and never committed; use `.env.example` as the template.
- **dbt.** Models were developed in dbt Cloud, but the project is standard dbt and runs identically under dbt Core (`dbt build` from the repo root) against any connected PostgreSQL. dbt Cloud is not required.
- **Source APIs.** Ingestion depends on the World Bank WDI/WGI APIs being reachable at run time. The frozen indicator basket fixes what is pulled; the APIs supply the values.

## Limitations

A descriptive, small-sample study of open secondary data. The main limitations, and how each is handled:

- **Small sample (n = 6).** Six economies cannot support inferential statistics: no significance tests, confidence intervals, or prediction intervals are meaningful at this size. Handled by keeping the analysis descriptive: gaps, dispersion, and closing rates are reported as observed quantities, not estimated with error bars.

- **Years-to-close is extrapolation, not forecast.** The figures divide the remaining 2024 gap by the 2014–2024 slope, assuming that pace holds. Real convergence decelerates near the frontier, so these values, if anything, understate the difficulty of the final stretch. Stated as current-pace extrapolation throughout; large values read as "effectively not converging," not as literal predictions.

- **Single source, and EU-benchmark composition.** The economic indicators come almost entirely from World Bank WDI, with no independent triangulation, and the gap-to-EU denominator uses the EUU aggregate, whose composition changed with Brexit. The Brexit break was checked and found not to be present (the EUU series is smooth across the window on all four convergence indicators). An Eurostat EU27=100 cross-check would provide independent, fixed-composition triangulation; it is out of scope here, so all gap-to-EU figures should be read as World Bank-internal comparisons.

- **Kosovo data asymmetry.** No World Bank productivity series (17/17 null) and scattered labour-series gaps, but complete governance coverage. Rather than drop or impute, Kosovo is excluded from the 5-country productivity and 6-country sigma analyses and retained everywhere it has data. The asymmetry is reported as a finding.

- **Flagged data artifact (Montenegro productivity).** Montenegro's productivity series carries a distortion in 2021 (a sharp spike and near-equal reversal the following year). The years-to-close and stuck-matrix use OLS slopes over the full decade specifically to blunt single-year distortions like this one; excluding 2021 lengthens Montenegro's productivity timeline further but does not change the century-plus finding. The artifact is disclosed rather than smoothed, and Montenegro's productivity figure is read as approximate.

- **Association, not causation.** Any co-occurrence between governance and economic convergence — fast income catch-up alongside weak corruption control, for instance — is described, not explained. No governance-on-convergence regression is run; at n = 6 it would invite causal over-reading the data cannot support.

- **Governance not ratio-scaled.** WGI scores are standardized 0–100, not ratio measures, so the gap / sigma / years-to-close machinery does not apply. Governance is presented on its own descriptive axis and cannot be integrated with the economic metrics on a common quantitative basis.

- **Labour estimates.** National labour estimates are used rather than modeled-ILO series, because the modeled series is empty for Kosovo. This keeps Kosovo in the labour analysis but means the labour figures are not harmonized to the ILO modeled basis, which can differ across countries.

- **Youth unemployment cannot separate recovery from emigration.** A falling youth-unemployment gap is not, on its own, evidence of a strengthening labour market: in this region it can equally reflect young people leaving the country, which lowers measured unemployment without any improvement in job creation. The project holds no migration data and cannot distinguish the two, so youth-unemployment movements carry an interpretive limit that total unemployment does not. Youth figures are therefore read as a signal to watch, not as a clean recovery indicator.