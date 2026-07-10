-- Completeness guard for wb_stg_wdi.
-- The raw layer is append-only and wb_stg_wdi selects where batch_id =
-- max(batch_id) -- the LATEST batch, not the most complete one. If a future
-- ingestion run dies partway through, its partial batch becomes max() and
-- staging silently shrinks. Every downstream mart would rebuild on
-- incomplete data and no other test would fail: nothing else asserts a
-- row count.
-- Expected: 8 indicators x 34 entities x 17 years (2008-2024) = 4624 rows.
-- A dbt singular test passes when it returns ZERO rows.

select count(*) as n_rows
from {{ ref('wb_stg_wdi') }}
having count(*) <> 4624