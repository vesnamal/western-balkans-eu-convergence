-- wb_fct_stuck_matrix: classifies each country-indicator over 2014->2024,
-- based on OLS slope of gap-to-EU (not endpoint delta -- see years_to_close
-- for why: endpoint comparison is fragile to a single volatile year, e.g.
-- the Montenegro 2021 productivity artifact). CLASSIFICATION IS SCOPED:
--   convergence      -> classified; rising gap_to_eu = closing in on EU = catching_up
--   context_inverted -> classified; falling gap_to_eu (unemployment) = catching_up
--   context (plain)  -> NOT classified; EU average is not a clear target for a
--                       catch-up economy (e.g. investment share). Retained as
--                       'not_classified' for descriptive use, never labelled.
-- Null slope (insufficient data) => 'no_data'. Deadband matches years_to_close:
-- +/-0.2 pts/year for convergence, +/-2.0 pts/year for context_inverted.
-- Verified: mean absolute slope is 5.54 pts/year for context_inverted vs
-- 0.91 for convergence (~6x), and no context_inverted slope falls below
-- 0.46 -- so a +/-0.2 deadband would classify zero rows as stuck there.

with scoped as (
    select
        country_iso3, country_name, role, ex_yugoslav, eu_member,
        indicator_code, friendly_name, bucket, year, gap_to_eu
    from {{ ref('wb_fct_gap_to_eu') }}
    where year between 2014 and 2024
),
slopes as (
    select
        country_iso3, country_name, role, ex_yugoslav, eu_member,
        indicator_code, friendly_name, bucket,
        regr_slope(gap_to_eu, year) as slope_per_year,
        max(case when year = 2014 then gap_to_eu end) as gap_2014,
        max(case when year = 2024 then gap_to_eu end) as gap_2024
    from scoped
    group by country_iso3, country_name, role, ex_yugoslav, eu_member,
             indicator_code, friendly_name, bucket
),
classified as (
    select
        *,
        gap_2024 - gap_2014 as gap_change,
        case
            when slope_per_year is null then 'no_data'
            when bucket = 'context' then 'not_classified'
            when bucket = 'context_inverted' then
                case
                    when slope_per_year < -2.0 then 'catching_up'
                    when slope_per_year >  2.0 then 'falling_behind'
                    else 'stuck'
                end
            when bucket = 'convergence' then
                case
                    when slope_per_year >  0.2 then 'catching_up'
                    when slope_per_year < -0.2 then 'falling_behind'
                    else 'stuck'
                end
            else 'not_classified'
        end as status
    from slopes
)
select
    country_iso3, country_name, role, ex_yugoslav, eu_member,
    indicator_code, friendly_name, bucket,
    gap_2014, gap_2024, gap_change, slope_per_year, status
from classified