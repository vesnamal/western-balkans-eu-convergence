-- Grain guard for wb_fct_gap_to_eu.
-- The mart's declared grain is one row per country_iso3 x indicator_code x year.
-- A dbt singular test passes when it returns ZERO rows. This query returns any
-- (country, indicator, year) combination that appears more than once -- i.e. a
-- join fan-out from wb_int_country_dim or wb_indicator_meta, or a duplicate
-- EUU benchmark row leaking through the eu_benchmark CTE.
-- Currently expected: 0 rows (34 countries x 8 indicators x 17 years).

select
    country_iso3,
    indicator_code,
    year,
    count(*) as n_rows
from {{ ref('wb_fct_gap_to_eu') }}
group by country_iso3, indicator_code, year
having count(*) > 1