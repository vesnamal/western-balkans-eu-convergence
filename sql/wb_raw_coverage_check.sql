-- Coverage / data-quality check for the WDI raw layer.
-- Per indicator: total rows landed, non-null observations, and null gaps.
--
-- IMPORTANT: wb_raw_wdi is APPEND-ONLY. Each ingestion run stamps its rows
-- with a timestamped batch_id and no run overwrites another. The table
-- currently holds two batches (a superseded 11-entity pull and the current
-- 34-entity pull), so an unfiltered count double-counts every entity present
-- in both. This check filters to the latest batch, matching what wb_stg_wdi
-- reads.
--
-- Expected on the latest batch: 578 rows per indicator (34 entities x 17
-- years). Nulls: 17 on SL.GDP.PCAP.EM.KD (Kosovo, all years absent), small
-- pre-2014 counts on the labour series (Kosovo, Montenegro), zero elsewhere.

with latest_batch as (
    select max(batch_id) as batch_id
    from s_vesnamalenica.wb_raw_wdi
)

select indicator_code,
       count(*) as total_rows,
       count(value) as non_null,
       count(*) - count(value) as nulls
from s_vesnamalenica.wb_raw_wdi
where batch_id = (select batch_id from latest_batch)
group by indicator_code
order by indicator_code;