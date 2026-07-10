-- Grain guard for wb_fct_years_to_close.
-- Declared grain: one row per country_iso3 x indicator_code (no year).
-- 10 countries (WB six + Slovenia + Bulgaria/Croatia/Romania) x 4 indicators
-- (convergence + context_inverted buckets) = 40 rows, verified.
-- A dbt singular test passes when it returns ZERO rows. This query returns
-- any (country, indicator) pair appearing more than once -- e.g. a fan-out
-- from the with_gap LEFT JOIN if the reference-year filter ever matched
-- more than one row per country-indicator.

select
    country_iso3,
    indicator_code,
    count(*) as n_rows
from {{ ref('wb_fct_years_to_close') }}
group by country_iso3, indicator_code
having count(*) > 1