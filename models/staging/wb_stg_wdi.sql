-- wb_stg_wdi: clean staging layer for World Bank WDI indicators.
-- One row per country-indicator-year. Latest batch only (raw is append-only;
-- today's 34-entity batch is a complete superset of the prior 11-entity one).
-- Nulls are KEPT: a null value records "queried, returned nothing" = coverage info.
-- No joins, no metrics, no type casts (raw types are already clean).

with latest_batch as (

    select max(batch_id) as batch_id
    from {{ source('wb_raw', 'wb_raw_wdi') }}

),

source as (

    select
        indicator_code,
        country_iso3,
        year,
        value
    from {{ source('wb_raw', 'wb_raw_wdi') }}
    where batch_id = (select batch_id from latest_batch)

)

select
    indicator_code,
    country_iso3,
    year,
    value
from source