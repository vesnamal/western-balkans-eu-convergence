-- wb_fct_stuck_matrix: classifies each country-indicator as catching_up / stuck /
-- falling_behind over 2014->2024, based on change in gap-to-EU. Bucket-aware:
-- convergence + context use gap-rising = good; context_inverted (unemployment)
-- flips it (gap-falling toward EU = good). Null in either year => no_data.
-- Threshold: +/-2 points over the decade.
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
when gap_2014 is null or gap_2024 is null then 'no_data'
when bucket = 'context_inverted' then
case
when gap_2024 - gap_2014 < -2 then 'catching_up'
when gap_2024 - gap_2014 >  2 then 'falling_behind'
else 'stuck'
end
else
case
when gap_2024 - gap_2014 >  2 then 'catching_up'
when gap_2024 - gap_2014 < -2 then 'falling_behind'
else 'stuck'
end
end as status
from pivoted
)
select
country_iso3, country_name, role, ex_yugoslav, eu_member,
indicator_code, friendly_name, bucket,
gap_2014, gap_2024, gap_change, status
from classified