-- Grain guard for wb_fct_governance.
-- The mart's declared grain is one row per country_iso3 x indicator_code x year.
-- A dbt singular test passes when it returns ZERO rows. This query returns any
-- (country, indicator, year) combination that appears more than once -- i.e. a
-- join fan-out or duplicate-batch leak. Currently expected: 0 rows (330 total,
-- 10 countries x 3 indicators x 11 years, all distinct).

select
    country_iso3,
    indicator_code,
    year,
    count(*) as n_rows
from {{ ref('wb_fct_governance') }}
group by country_iso3, indicator_code, year
having count(*) > 1