-- Grain guard for wb_fct_stuck_matrix.
-- Declared grain: one row per country_iso3 x indicator_code (no year).
-- 34 countries x 8 indicators = 272 rows, verified.
-- A dbt singular test passes when it returns ZERO rows. This query returns
-- any (country, indicator) pair appearing more than once -- i.e. a join
-- fan-out, or a group-by key changing upstream in wb_fct_gap_to_eu.

select
    country_iso3,
    indicator_code,
    count(*) as n_rows
from {{ ref('wb_fct_stuck_matrix') }}
group by country_iso3, indicator_code
having count(*) > 1