-- Grain guard for wb_fct_sigma_convergence.
-- Declared grain: one row per indicator_code x year (no country dimension --
-- countries are collapsed into the dispersion statistic). 4 indicators x 11
-- years (2014-2024) = 44 rows, verified.
-- A dbt singular test passes when it returns ZERO rows. This query returns any
-- (indicator, year) pair appearing more than once -- i.e. the group-by key in
-- the dispersion CTE has changed, or an indicator has been added upstream
-- without updating the scope filter.

select
    indicator_code,
    year,
    count(*) as n_rows
from {{ ref('wb_fct_sigma_convergence') }}
group by indicator_code, year
having count(*) > 1