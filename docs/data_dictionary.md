# Data Dictionary

Reference for every object this project owns in schema `s_vesnamalenica`. Everything
is prefixed `wb_` because it's a shared course schema. The prefix after that tells
you the layer: `wb_raw_`, `wb_stg_`, `wb_int_`, `wb_fct_`.

Pipeline: Python ingestion → raw tables → dbt staging views → intermediate view →
mart tables. Seeds are static CSVs loaded by `dbt seed`.

The data covers 2008–2024. All the convergence metrics are computed on 2014–2024
only. The longer span is used for one descriptive chart in the notebook.

34 entities: the 6 Western Balkan candidates, the 27 EU members, and the EUU
aggregate used as the benchmark.

78 dbt tests. `wb_int_country_dim` has none of its own — it's a straight
pass-through of the `wb_country_roles` seed, and the seed's tests already cover it.

---

## Raw layer

Two tables, both append-only. Every ingestion run tags its rows with a timestamped
`batch_id` and nothing overwrites anything, so the raw tables hold every pull I ever
did. Staging is where deduplication happens: it filters to `max(batch_id)`.

This matters if you query the raw tables directly. `wb_raw_wdi` has 6,120 rows, not
4,624 — an early 11-entity pull from 27 June is still sitting in there alongside the
current 34-entity one. Same story for `wb_raw_wgi` (2,193 rows, two batches). I
checked: no country-indicator-year has a different value across the two batches, so
nothing downstream is affected. The coverage-check scripts in `sql/` filter to the
latest batch for this reason.

Null values are kept, never dropped. A null means "asked the API, got nothing," and
that's information about coverage.

### `wb_raw_wdi`
World Bank WDI (db=2), pulled with `wbgapi` by `ingestion/pull_wdi.py`.

| Column | Type | Description |
|---|---|---|
| `source` | text | Always `'WDI'`. |
| `indicator_code` | text | e.g. `NY.GDP.PCAP.PP.KD` |
| `country_iso3` | text | e.g. `ALB`, `EUU` |
| `year` | integer | 2008–2024 |
| `value` | double precision | Nullable. |
| `ingested_at` | timestamptz | Set by a DDL default. |
| `batch_id` | text | e.g. `wdi_20260630T093354Z` |

### `wb_raw_wgi`
World Bank WGI (source=3), pulled with raw `requests` by `ingestion/pull_wgi.py` —
`wbgapi` can't reach source=3. These are the absolute 0–100 scores from the 2025
revision; the old `*.PER.RNK` percentile codes are retired.

| Column | Type | Description |
|---|---|---|
| `source` | text | Always `'WGI'`. |
| `indicator_code` | text | `GOV_WGI_RL.SC`, `GOV_WGI_CC.SC`, `GOV_WGI_GE.SC` |
| `country_iso3` | text | No `EUU` — WGI rates countries, not aggregates. |
| `year` | integer | 2008–2024 |
| `value` | double precision | Zero nulls in practice. |
| `ingested_at` | timestamptz | |
| `batch_id` | text | |

---

## Seeds

### `wb_country_roles`
34 rows, one per entity. Cohorts assigned by hand from the research design, not by
clustering. Edited as `seeds/wb_country_roles.csv`.

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | Primary key. Kosovo is `XKX`, the World Bank's code. |
| `country_name` | text | |
| `role` | text | `western_balkan` (6), `recent_entrant` (3), `success_case` (1), `eu_core` (23), `eu_benchmark` (1) |
| `ex_yugoslav` | boolean | True for BIH, XKX, MNE, MKD, SRB, HRV, SVN. False for Albania, which is Western Balkan but was never Yugoslav. |
| `eu_member` | boolean | True for the 27 EU members. |

**Use `role` for filtering, never `eu_member`.** `eu_member` is false for the six
Western Balkan countries *and* for the EUU aggregate row, so it can't tell them
apart. It's fine as label text on a chart. It is not a filter.

`eu_core` is the 23 EU members that aren't already broken out as recent entrants or
as Slovenia. It's a distributional backdrop — context for where the six sit in the
EU distribution — not a convergence target.

### `wb_indicator_meta`
11 rows: 8 WDI indicators and 3 WGI scores. `seeds/wb_indicator_meta.csv`.

| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | Primary key. |
| `friendly_name` | text | Chart label. |
| `bucket` | text | How to read the indicator. |

Buckets:

| Bucket | n | Indicators | How to read it |
|---|---|---|---|
| `convergence` | 2 | GDP per capita, productivity | Ratio-scaled. A rising gap-to-EU means catching up. |
| `context_inverted` | 2 | Total and youth unemployment | Lower is better, so a falling gap means catching up. |
| `context` | 4 | Investment, FDI, trade, labour participation | Already percentages. The EU average isn't a target for a catch-up economy, so these are never classified. |
| `governance` | 3 | Rule of Law, Control of Corruption, Government Effectiveness | Standardised 0–100. None of the convergence maths applies. |

---

## Staging (views)

One row per country-indicator-year, latest batch only. Nulls kept, no joins, no
casts.

`max(batch_id)` picks the *newest* batch, not the most *complete* one. If an
ingestion run ever died halfway through, its partial batch would become the newest
and staging would silently shrink. Both staging models have a row-count test to
catch that.

**`wb_stg_wdi`** — 4,624 rows (34 × 8 × 17). A complete grid: every combination
exists as a row, so all missingness is an explicit null, never a missing row.

**`wb_stg_wgi`** — 1,683 rows (33 × 3 × 17; no EUU, since WGI rates countries not
aggregates). Fully balanced, zero nulls.

Both have columns `indicator_code`, `country_iso3`, `year`, `value`.

---

## Intermediate (view)

### `wb_int_country_dim`
34 rows. Everything downstream joins to this. It's `select` of the five columns from
`wb_country_roles` and nothing else — same columns, same types.

---

## Marts

### `wb_fct_gap_to_eu`
One row per country × indicator × year. 4,624 rows.

Each entity's value as a percentage of the EUU benchmark for the same
indicator-year. The benchmark CTE joins on indicator and year only, so EUU ends up
compared to itself and every EUU row reads `gap_to_eu = 100`. That's arithmetic, not
a result.

| Column | Type | Description |
|---|---|---|
| `country_iso3` | text | |
| `country_name` | text | |
| `role` | text | |
| `ex_yugoslav` | boolean | |
| `eu_member` | boolean | Label only. |
| `indicator_code` | text | |
| `friendly_name` | text | |
| `bucket` | text | |
| `year` | integer | |
| `value` | double precision | Nullable. |
| `eu_value` | double precision | The EUU benchmark for that indicator-year. |
| `gap_to_eu` | numeric | `value / eu_value × 100`, 2dp. Null when `value` is null. |

Inside the 2014–2024 window there is exactly one null pattern: Kosovo on
productivity, all 11 years. A test fails if any other in-window null appears.

### `wb_fct_stuck_matrix`
One row per country × indicator, no year. 272 rows (34 × 8).

Classifies how `gap_to_eu` moved over 2014–2024 using the OLS slope, not the
difference between the endpoints. Endpoints are fragile: North Macedonia's
productivity gap ends 1.06 points higher than it started, but the fitted line
through all 11 points is basically flat (slope 0.009/year). The endpoint number
says "moved"; the slope says "didn't."

Deadbands differ by bucket, on purpose:

- `convergence`: ±0.2 pts/year
- `context_inverted`: ±2.0 pts/year

Unemployment slopes are about 6× larger on average (mean |slope| 5.54 vs 0.91) and
never drop below 0.46, so a ±0.2 band would classify nothing as `stuck`. I picked
the threshold by looking at the observed slope distribution, not from theory.

Only `convergence` and `context_inverted` get classified. Plain `context` rows come
out as `not_classified` (136 of the 272). A null slope gives `no_data` — that
happens exactly once, Kosovo × productivity, where every year is null so
`regr_slope` returns null.

| Column | Type | Description |
|---|---|---|
| `country_iso3`, `country_name`, `role`, `ex_yugoslav`, `eu_member`, `indicator_code`, `friendly_name`, `bucket` | | As in `wb_fct_gap_to_eu`. |
| `gap_2014` | numeric | |
| `gap_2024` | numeric | |
| `gap_change` | numeric | `gap_2024 − gap_2014`. Descriptive. **Not** what `status` is based on. |
| `slope_per_year` | double precision | OLS slope. This is what `status` is based on. |
| `status` | text | `catching_up` / `stuck` / `falling_behind` / `not_classified` / `no_data` |

`gap_2014`, `gap_2024`, `gap_change` and `slope_per_year` are null only on that one `no_data` row.

### `wb_fct_sigma_convergence`
One row per indicator × year. 44 rows (4 indicators × 11 years). No country column —
the countries are collapsed into a dispersion statistic.

This asks a different question from the stuck-matrix: not "is each country catching
up" but "is the group tightening." Measure is the coefficient of variation
(`sd_gap / mean_gap`), which is scale-free, so it doesn't shrink just because the
mean rises as everyone converges upward. Sample SD (n−1), which suits a small
cross-section.

It's a descriptive trend, not a significance test. At n=6 (n=5 for productivity)
p-values wouldn't mean anything.

Kosovo isn't filtered out here either. Its productivity rows exist but are null, and
SQL aggregates skip nulls, so productivity just computes over 5 countries.
`n_countries` counts non-null contributors and is the audit trail for that.

| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | GDP per capita, productivity, total and youth unemployment. |
| `year` | integer | 2014–2024 |
| `n_countries` | bigint | 5 on productivity, 6 elsewhere. |
| `mean_gap` | numeric | |
| `sd_gap` | numeric | Sample SD. |
| `cv_gap` | numeric | `sd_gap / mean_gap`. Guarded against a zero mean. |

### `wb_fct_years_to_close`
One row per country × indicator. 40 rows (10 countries × 4 indicators).

Narrower scope than the other marts: only the `convergence` and `context_inverted`
buckets, and only the WB six plus the comparators. The EU aggregate and the 23
`eu_core` states are left out — neither is converging on itself.

Takes the remaining 2024 gap and divides by the 2014–2024 OLS slope. **This is not a
forecast.** Convergence slows down near the frontier, and six countries can't
support prediction intervals. The large numbers are the finding, not a bug.

`closure_status` looks like a second category but mostly isn't. It returns
`already_closed` if the 2024 gap has crossed the benchmark, and otherwise just
repeats `status`. Four of its five values are `status` verbatim. Only
`already_closed` tells you something new.

**Always show `status` and `closure_status` together with `years_to_close`.**
Romania's total unemployment is `diverging` and `already_closed` at the same time —
it's better than the EU average right now (91.64) and getting worse. On its own,
"0 years, already closed" reads like an all-clear.

| Column | Type | Description |
|---|---|---|
| `country_iso3`, `country_name`, `role`, `ex_yugoslav`, `eu_member`, `indicator_code`, `friendly_name`, `bucket` | | As in `wb_fct_gap_to_eu`. `role` here is only `western_balkan`, `success_case`, or `recent_entrant`. |
| `n_points` | bigint | Observations feeding the slope. 11 everywhere except Kosovo × productivity (0). |
| `slope_per_year` | double precision | |
| `intercept` | double precision | |
| `status` | text | `catching_up` / `diverging` / `stalled` / `no_data` |
| `closure_status` | text | `already_closed`, or `status` repeated. |
| `gap_2024` | numeric | Gap in the reference year (a dbt var, currently 2024). |
| `years_to_close` | numeric | `0` for every `already_closed` row. Null for `stalled`, `diverging`, `no_data` — there's no honest number of years for a gap that isn't closing. 7 of 40 rows are null. |

### `wb_fct_governance`
One row per country × indicator × year. 330 rows (10 countries × 3 scores × 11
years). Same country scope as `wb_fct_years_to_close`.

Descriptive only. WGI scores are standardised 0–100, not ratio-scaled, so gap-to-EU,
sigma, and years-to-close don't apply. Governance can't be put on the same
quantitative footing as the economic metrics, and I haven't tried to.

| Column | Type | Description |
|---|---|---|
| `country_iso3`, `country_name`, `role`, `ex_yugoslav`, `eu_member`, `indicator_code`, `friendly_name` | | As in `wb_fct_gap_to_eu`. `role` here is only `western_balkan`, `success_case`, or `recent_entrant`. |
| `bucket` | text | Always `governance`. |
| `year` | integer | 2014–2024 |
| `value` | double precision | Score, 0–100. |

---

## Coverage notes

**Kosovo is asymmetric.** No productivity data at all (17/17 null), but complete
governance coverage. It is never filtered out of anything — the nulls just get
skipped by SQL aggregates, so productivity runs over five countries and
`n_countries` records it. The economic and governance panels treat Kosovo
differently because the data does, and I've reported that rather than hidden it.

**A few pre-2014 labour gaps.** Kosovo's youth unemployment starts in 2012, and it
has nulls at 2010–2011 on labour participation and total unemployment. Montenegro
has youth-unemployment nulls at 2008–2010. All of it falls outside the analysis
window. Across the 4,624 staged rows there are 28 nulls in total: 17 productivity,
11 labour. 

**The 27 EU members are fully populated** on all 8 WDI indicators. Zero nulls.

**`EUU` has no governance score.** It's an aggregate, and WGI rates countries.

**The EU benchmark's composition changed** when the UK left in 2020 — EUU tracks
current membership. That could have put a structural break in the denominator, so I
looked. The EUU series 2016–2024 shows no persistent level shift on any of the four
indicators the convergence metrics use: each dips in 2020 for COVID and recovers by
2021. A Eurostat EU27=100 cross-check would also rule out slower compositional
drift; I haven't done it, and it's in the README's limitations.