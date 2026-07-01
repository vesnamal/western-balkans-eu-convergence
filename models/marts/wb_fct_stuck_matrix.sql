-- wb_fct_stuck_matrix: classifies each country-indicator over 2014->2024,
-- based on change in gap-to-EU. CLASSIFICATION IS SCOPED (B-nuanced):
--   convergence      -> classified; gap rising toward EU = catching_up
--   context_inverted -> classified; gap falling toward EU (unemployment) = catching_up
--   context (plain)  -> NOT classified; EU average is not a clear target for a
--                       catch-up economy (e.g. investment share). Retained as
--                       'not_classified' for descriptive use, never labelled.
-- Null in either endpoint => 'no_data'. Threshold: +/-2 points over the decade.
with gaps as (
    select country_iso3, country_name, role, ex_yugoslav, eu_member,
           indicator_code, friendly_name, bucket, year, gap_to_eu
    from {{ ref('wb_fct_gap_to_eu') }}
    where year in (2014, 2024)
),
pivoted as (
    select
        country_iso3, country_name, role, ex_yugoslav, eu_member,
        indicator_code, friendly_name, bucket,
        max(case when year = 2014 then gap_to_eu end) as gap_2014,
        max(case when year = 2024 then gap_to_eu end) as gap_2024
    from gaps
    group by country_iso3, country_name, role, ex_yugoslav, eu_member,
             indicator_code, friendly_name, bucket
),
classified as (
    select
        *,
        gap_2024 - gap_2014 as gap_change,
        case
            -- missing endpoint always wins, regardless of bucket
            when gap_2014 is null or gap_2024 is null then 'no_data'
            -- plain context: retained but never classified
            when bucket = 'context' then 'not_classified'
            -- inverted (unemployment): gap FALLING toward EU is good
            when bucket = 'context_inverted' then
                case
                    when gap_2024 - gap_2014 < -2 then 'catching_up'
                    when gap_2024 - gap_2014 >  2 then 'falling_behind'
                    else 'stuck'
                end
            -- convergence: gap RISING toward EU is good
            when bucket = 'convergence' then
                case
                    when gap_2024 - gap_2014 >  2 then 'catching_up'
                    when gap_2024 - gap_2014 < -2 then 'falling_behind'
                    else 'stuck'
                end
            -- any unforeseen bucket: fail safe rather than silently mislabel
            else 'not_classified'
        end as status
    from pivoted
)
select
    country_iso3, country_name, role, ex_yugoslav, eu_member,
    indicator_code, friendly_name, bucket,
    gap_2014, gap_2024, gap_change, status
from classified