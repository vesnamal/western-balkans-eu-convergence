-- Coverage / data-quality check for the WGI governance raw layer.
--
-- IMPORTANT: wb_raw_wgi is APPEND-ONLY. Each ingestion run stamps its rows
-- with a timestamped batch_id and no run overwrites another. The table
-- currently holds two batches (a superseded 10-entity pull and the current
-- 33-entity pull), so an unfiltered count double-counts every entity present
-- in both. This check filters to the latest batch, matching what wb_stg_wgi
-- reads.
--
-- Expected on the latest batch: 33 entities x 3 codes x 17 years = 1683 rows,
-- 51 rows per entity, zero nulls -- WGI is a fully balanced panel.
-- EUU is absent by design: WGI rates countries, not aggregates. Kosovo (XKX)
-- is COMPLETE on governance despite being thin on the economic basket, so the
-- governance panel needs no Kosovo caveat.

with latest_batch as (
    select max(batch_id) as batch_id
    from s_vesnamalenica.wb_raw_wgi
)

select country_iso3,
       count(*)                  as total_rows,
       count(value)              as non_null,
       count(*) - count(value)   as nulls
from s_vesnamalenica.wb_raw_wgi
where batch_id = (select batch_id from latest_batch)
group by country_iso3
order by country_iso3;