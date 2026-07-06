-- Singular test: regression guard for the years-to-close closure-status
-- interaction found and fixed this session (see wb_fct_years_to_close
-- header comment, CLOSURE_STATUS section, for the Romania worked example).
-- dbt singular tests pass when the query returns ZERO rows -- any row
-- returned here is a failure.

select
    country_iso3, indicator_code, bucket, status, closure_status, years_to_close
from {{ ref('wb_fct_years_to_close') }}
where
    -- bug 1: years_to_close must never be negative
    years_to_close < 0
    -- bug 2: already_closed rows must always show exactly 0, never null
    -- or any other value -- see header comment for why this is a locked
    -- rule, not case-specific
    or (closure_status = 'already_closed' and years_to_close is distinct from 0)