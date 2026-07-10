-- Null-scoping guard for wb_fct_years_to_close.years_to_close.
-- The existing assert_years_to_close_valid checks that already_closed rows
-- show exactly 0 and that no value is negative. This test checks the
-- CONVERSE, which nothing else covers:
--   1. A row showing 0 must actually be already_closed -- a 0 elsewhere
--      would read as "gap closes immediately" and is never legitimate.
--   2. stalled / diverging / no_data rows (that are NOT already_closed)
--      must be null -- there is no honest years figure for a gap that is
--      not closing, and a number appearing there would be silently wrong.
--   3. catching_up rows (that are NOT already_closed) must be non-null --
--      a null here means the final CASE fell through with no else branch.
-- Verified baseline: 7 null years_to_close rows out of 40.
-- A dbt singular test passes when it returns ZERO rows.

select
    country_iso3,
    indicator_code,
    bucket,
    status,
    closure_status,
    years_to_close
from {{ ref('wb_fct_years_to_close') }}
where
    (years_to_close = 0 and closure_status <> 'already_closed')
    or (closure_status <> 'already_closed'
        and status in ('stalled', 'diverging', 'no_data')
        and years_to_close is not null)
    or (closure_status <> 'already_closed'
        and status = 'catching_up'
        and years_to_close is null)