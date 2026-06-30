-- wb_fct_gap_to_eu: gap-to-EU fact table. One row per country-indicator-year.
-- gap_to_eu = country value as % of the EUU benchmark (WB-derived; Eurostat
-- cross-check deferred). Read 'convergence' bucket as true catch-up; 'context'
-- and 'context_inverted' are descriptive (latter: lower is better).
with wdi as (
select indicator_code, country_iso3, year, value
from {{ ref('wb_stg_wdi') }}
),
eu_benchmark as (
select indicator_code, year, value as eu_value
from {{ ref('wb_stg_wdi') }}
where country_iso3 = 'EUU'
),
joined as (
select
w.country_iso3,
w.indicator_code,
w.year,
w.value,
b.eu_value,
case
when b.eu_value is null or b.eu_value = 0 then null
else round((w.value / b.eu_value * 100)::numeric, 2)
end as gap_to_eu
from wdi w
left join eu_benchmark b
on w.indicator_code = b.indicator_code
and w.year = b.year
)
select
j.country_iso3,
d.country_name,
d.role,
d.ex_yugoslav,
d.eu_member,
j.indicator_code,
m.friendly_name,
m.bucket,
j.year,
j.value,
j.eu_value,
j.gap_to_eu
from joined j
left join {{ ref('wb_int_country_dim') }} d on j.country_iso3 = d.country_iso3
left join {{ ref('wb_indicator_meta') }} m on j.indicator_code = m.indicator_code