-- Completeness guard for wb_stg_wgi. Same rationale as
-- assert_stg_wdi_complete: staging reads max(batch_id), so a truncated
-- re-pull would silently shrink the panel with nothing to catch it.
-- Expected: 3 WGI scores x 33 entities x 17 years (2008-2024) = 1683 rows.
-- EUU is absent by design (WGI rates countries, not aggregates), hence 33
-- entities rather than 34.
-- A dbt singular test passes when it returns ZERO rows.

select count(*) as n_rows
from {{ ref('wb_stg_wgi') }}
having count(*) <> 1683