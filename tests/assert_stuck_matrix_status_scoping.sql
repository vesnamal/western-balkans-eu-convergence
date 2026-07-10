-- Scoping guard for wb_fct_stuck_matrix.status.
-- The model asserts two invariants that no schema test can express:
--   1. bucket 'context' is NEVER classified -> status must be 'not_classified'
--      (EU average is not a defensible target for a catch-up economy).
--   2. buckets 'convergence' and 'context_inverted' are ALWAYS classified ->
--      status must be catching_up / falling_behind / stuck, or 'no_data' when
--      regr_slope returned null (all gap_to_eu values null in the window).
-- accepted_values on status alone cannot catch a context row wrongly labelled
-- 'catching_up', because 'catching_up' is a legal value elsewhere.
-- A dbt singular test passes when it returns ZERO rows.

select
    country_iso3,
    indicator_code,
    bucket,
    status,
    slope_per_year
from {{ ref('wb_fct_stuck_matrix') }}
where
    (bucket = 'context' and status <> 'not_classified')
    or (bucket in ('convergence', 'context_inverted')
        and status not in ('catching_up', 'falling_behind', 'stuck', 'no_data'))
    or (status = 'no_data' and slope_per_year is not null)
    or (status <> 'no_data' and bucket <> 'context' and slope_per_year is null)