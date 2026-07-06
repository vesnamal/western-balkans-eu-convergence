-- wb_fct_years_to_close: OLS slope of gap_to_eu over 2014-2024 (11 points),
-- scoped to convergence + context_inverted buckets (mirrors stuck_matrix's
-- B-nuanced scoping). Role scope widened beyond the WB six to include
-- comparator tier (Slovenia=success_case, Bulgaria/Croatia/Romania=recent_entrant)
-- for Tableau reference display -- NOT the EU aggregate, NOT eu_core states,
-- NOT plain 'context' bucket (no defensible EU target for those indicators).
--
-- METHOD: regr_slope(gap_to_eu, year) per country/indicator. Chosen over
-- endpoint-based rate (2014 vs 2024 only) because endpoint methods are
-- demonstrably fragile to single-year noise -- see North Macedonia finding
-- below. Framing is explicitly "constant-rate extrapolation, NOT a forecast":
-- convergence decelerates near the EU frontier and n=6 cannot support
-- prediction intervals.
--
-- CLASSIFICATION: mirrors stuck_matrix direction logic --
--   convergence: rising gap_to_eu = closing in on EU level (positive slope good)
--   context_inverted: falling gap_to_eu = closing in (negative slope good)
--   NULL slope (missing data, e.g. Kosovo productivity) -> 'no_data', checked
--   before any threshold comparison, since NULL comparisons are neither true
--   nor false and would otherwise silently fall through to a wrong category.
--
-- DEADBANDS ARE ASYMMETRIC ACROSS BUCKETS -- deliberate deviation from
-- stuck-matrix's single ±2pt/decade rule, not an oversight:
--   convergence:       ±0.2 pts/year (= stuck-matrix's ±2pt/decade, unit-converted)
--   context_inverted:  ±2.0 pts/year -- empirically, unemployment-index slopes
--                       run 5-15x larger in magnitude than GDP/productivity
--                       slopes (structurally more volatile indicator); ±0.2
--                       produced zero 'stalled' cases across all 20 rows tested
--                       and was judged non-functional for this bucket.
--   Threshold picked by inspecting the observed slope distribution, not
--   derived theoretically -- a limitation to state plainly, not hide.
--
-- VERIFIED FINDINGS (checked against raw wb_fct_gap_to_eu series, not assumed):
--   - North Macedonia productivity slope (~0.009) looks tiny vs. endpoint-implied
--     change (~1.06pt/decade). Confirmed NOT an artifact: full series is flat/
--     noisy (52-54 range throughout), no spike-reversal signature. OLS correctly
--     discounts noise that endpoint comparison would overstate.
--   - Kosovo total unemployment slope (~-16.6, sharpest in panel): full series
--     shows a genuine multi-year decline 2018-2023, not a spike-reversal.
--     No country-specific data-quality flag found in WDI SpecialNotes metadata
--     (checked directly). Independent modeled-ILO estimate cross-check attempted
--     but blocked by site UI; not completed. Treat as a real but not fully
--     externally corroborated finding.
--   - Montenegro unemployment (~+2 to +5, diverging): confirmed COVID-shock
--     pattern (spike 2019-2021, partial but incomplete recovery by 2024) --
--     structurally different from Montenegro's confirmed 2021 productivity
--     artifact (isolated spike-and-full-reversal). Diverging status is real,
--     not a repeat of the productivity data issue.
--   - Romania unemployment (~+3.4 to +5.7, diverging): sustained non-reverting
--     climb from 2020 onward, still rising through 2024. Checked against
--     Bulgaria and Croatia (same recent_entrant tier) to rule out an EU-wide
--     2020-2021 labour-survey methodology break as an alternative explanation --
--     both comparators show continuous decline with only a transient COVID
--     bump, NOT a lasting level-shift. Romania's pattern does not match either
--     comparator, so an EU-wide artifact explanation is ruled out. Treated as
--     a genuine, Romania-specific divergence, cause not further diagnosed
--     (possible candidates: demographic/emigration effects on labour force
--     denominator, national survey change -- not verified either way).
--   - Kosovo productivity: n_points=0, confirmed structurally null (not a
--     bug) -- consistent with documented 5-country productivity coverage.

with scoped as (
    select
        country_iso3, country_name, role, ex_yugoslav, eu_member,
        indicator_code, friendly_name, bucket, year, gap_to_eu
    from {{ ref('wb_fct_gap_to_eu') }}
    where year between 2014 and 2024
      and bucket in ('convergence', 'context_inverted')
      and role in ('western_balkan', 'success_case', 'recent_entrant')
),
slopes as (
    select
        country_iso3, country_name, role, ex_yugoslav, eu_member,
        indicator_code, friendly_name, bucket,
        regr_slope(gap_to_eu, year) as slope_per_year,
        regr_intercept(gap_to_eu, year) as intercept,
        count(gap_to_eu) as n_points
    from scoped
    group by country_iso3, country_name, role, ex_yugoslav, eu_member,
             indicator_code, friendly_name, bucket
),
classified as (
    select
        *,
        case
            -- missing data (e.g. Kosovo productivity) always wins first
            when slope_per_year is null then 'no_data'

            -- convergence bucket: rising gap_to_eu = closing in on EU level
            when bucket = 'convergence' then
                case
                    when slope_per_year >  0.2 then 'catching_up'
                    when slope_per_year < -0.2 then 'diverging'
                    else 'stalled'
                end

            -- context_inverted (unemployment): falling gap_to_eu = closing in
            when bucket = 'context_inverted' then
                case
                    when slope_per_year < -2.0 then 'catching_up'
                    when slope_per_year >  2.0 then 'diverging'
                    else 'stalled'
                end

            -- any unforeseen bucket: fail safe rather than silently mislabel
            else 'not_classified'
        end as status
    from slopes
)
select
    country_iso3, country_name, role, ex_yugoslav, eu_member,
    indicator_code, friendly_name, bucket,
    n_points, slope_per_year, intercept, status
from classified
order by role, country_name, indicator_code