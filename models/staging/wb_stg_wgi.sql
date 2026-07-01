-- wb_stg_wgi: clean staging layer for WGI governance scores. Latest batch only.

with latest_batch as (
    select max(batch_id) as batch_id
    from {{ source('wb_raw', 'wb_raw_wgi') }}
),

source as (
    select indicator_code, country_iso3, year, value
    from {{ source('wb_raw', 'wb_raw_wgi') }}
    where batch_id = (select batch_id from latest_batch)
)

select indicator_code, country_iso3, year, value
from source