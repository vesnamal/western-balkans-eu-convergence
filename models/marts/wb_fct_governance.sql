-- wb_fct_governance
--
-- Descriptive governance panel: 3 three WGI scores (Rule of Law,
-- Control of Corruption, Government Effectiveness) for the WB-6 plus
-- comparator tiers, 2014-2024, long grain (one row per country-indicator-year).
--
-- LOCKED DECISIONS reflected here:
--   * Descriptive ONLY. No gap-to-EU, no sigma, no slope, no years-to-close.
--     WGI scores are standardised 0-100 and NOT ratio-scaled, so the
--     convergence machinery applied to WDI indicators does not apply here.
--     `value` is the raw WGI score, passed through untouched.
--   * No EU benchmark. The World Bank publishes no WGI aggregate for the EU
--     as a bloc (EUU is absent from WGI raw entirely -- expected, not a gap),
--     so there is nothing to compute a gap against.
--   * Kosovo (XKX) is COMPLETE on WGI (unlike productivity, where it is null).
--     This mart is where that completeness shows -- XKX appears on all three
--     scores. Reported as a finding, not masked.
--
-- SCOPE / JOIN NOTES:
--   * Inner joins to wb_int_country_dim and wb_indicator_meta are intentional:
--     they enforce the role scope (countries with no role -- e.g. Austria in
--     raw WGI -- drop out) AND guarantee no NULL friendly_name / role. A WGI
--     row for a country outside the three roles silently vanishes BY DESIGN.
--   * Window 2014-2024 matches the convergence analysis window for deck
--     consistency, though WGI data spans 2008-2024.

with wgi as (
    select
        indicator_code,
        country_iso3,
        year,
        value
    from {{ ref('wb_stg_wgi') }}
    where year between 2014 and 2024
),

final as (
    select
        dim.country_iso3,
        dim.country_name,
        dim.role,
        dim.ex_yugoslav,
        dim.eu_member,
        wgi.indicator_code,
        meta.friendly_name,
        meta.bucket,
        wgi.year,
        wgi.value
    from wgi
    inner join {{ ref('wb_int_country_dim') }} dim
        on wgi.country_iso3 = dim.country_iso3
    inner join {{ ref('wb_indicator_meta') }} meta
        on wgi.indicator_code = meta.indicator_code
    where dim.role in ('western_balkan', 'success_case', 'recent_entrant')
)

select
    country_iso3,
    country_name,
    role,
    ex_yugoslav,
    eu_member,
    indicator_code,
    friendly_name,
    bucket,
    year,
    value
from final
order by role, country_name, indicator_code, year