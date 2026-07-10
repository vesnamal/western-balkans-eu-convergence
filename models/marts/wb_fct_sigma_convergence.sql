-- wb_fct_sigma_convergence: cross-country dispersion of gap-to-EU per indicator per year.
-- Sigma-convergence = is the SPREAD across the six WB economies shrinking over time?
-- A different question from the stuck-matrix (which asks about each country individually):
-- this asks whether the GROUP is tightening. Falling CV over time = converging as a group.
--
-- MEASURE: coefficient of variation (CV = stddev / mean), NOT raw standard deviation.
-- CV is scale-free, so it does not shrink merely because the mean level rises as economies
-- converge upward. It is one of the two literature-standard sigma measures (the other is
-- stddev of log income); CV is chosen because it applies uniformly across our mixed indicator
-- set without the undefined-value problems log would hit. Reported as a descriptive trend,
-- NOT a significance test -- at n=6 (n=5 for productivity) p-values are not defensible.
--
-- SCOPE: same indicator scope as the stuck-matrix -- convergence + context_inverted buckets --
-- so the project has ONE inclusion rule, not two. Four indicators:
--   GDP per capita PPP        NY.GDP.PCAP.PP.KD   (6-country)
--   productivity              SL.GDP.PCAP.EM.KD   (5-country: Kosovo has no data)
--   total unemployment        SL.UEM.TOTL.NE.ZS   (6-country, context_inverted)
--   youth unemployment        SL.UEM.1524.NE.ZS   (6-country, context_inverted)
--
-- WINDOW: 2014-2024, matching the research question's "recent 10 years" and the rest of the
-- analysis (stuck-matrix, slope chart). In this window all four indicators are BALANCED panels
-- (6, or 5 for productivity, every year) -- the pre-2014 coverage gaps that would corrupt a
-- dispersion trend fall outside this window, so no composition artifact.
--
-- KOSOVO: not filtered out anywhere. Its productivity rows exist but are NULL, so SQL aggregates
-- (avg, stddev, count) skip them automatically -- productivity computes over 5 countries with no
-- hardcoded exclusion. n_countries uses count(gap_to_eu), which counts only non-null contributors,
-- so it reads 5 on productivity and 6 elsewhere. That column is the audit trail for the asymmetry
-- AND a data-quality tripwire: if coverage silently drops, n_countries falls below expected and
-- the schema test catches it.


-- FINDINGS:
--
-- GDP per capita (6-country): CV falls 0.274 -> 0.199, a steady ~27% decline,
--   monotonic. The six are genuinely tightening on income. This is the clean
--   sigma-convergence result and the group-level echo of the country-level
--   "all six catching up on GDP" finding.
--
-- Productivity (5-country): CV falls 0.187 -> 0.151 (~19%) on endpoints, but
--   the path is NOT monotonic -- it peaks at 0.203 mid-window, above its own
--   2014 starting value, before the sustained decline from 2022. Quote the
--   endpoints only alongside the peak.
--
--   This is NOT the same claim as GDP, and it appears to contradict the
--   locked "productivity gaps barely move" finding but does not. That finding is
--   about the MEAN gap, which crawls only +3.2 pts (45.9 -> 49.1). Sigma is about
--   the SPREAD, which shrinks. Correct reading: the five economies are converging
--   ON EACH OTHER faster than they are converging on the EU. They are becoming
--   similarly stuck, not collectively catching up. This spread-vs-level split is
--   the finding sigma adds that nothing else in the project shows.
--
-- Total unemployment (6-country): CV falls 0.290 -> 0.190 but NON-MONOTONIC --
--   peaks 0.353 in 2020 (COVID), bottoms at 0.167 in 2023, then REBOUNDS to
--   0.190 in 2024. Trend is down but noisy and currently worsening; any
--   "converging" claim must carry the noise caveat AND the 2024 uptick.
--
-- Youth unemployment (6-country): CV falls 0.219 -> 0.159, also non-monotonic
--   (peaks 0.279 in 2018). Same noise caveat.
--
-- "all four show sigma-convergence" -- true statistically,
-- misleading substantively. GDP is the clean claim; productivity is the
-- spread-vs-level nuance; unemployment is down-but-noisy.


with wb_six as (

    select
        indicator_code,
        year,
        gap_to_eu
    from {{ ref('wb_fct_gap_to_eu') }}
    where country_iso3 in ('ALB', 'BIH', 'XKX', 'MNE', 'MKD', 'SRB')
      and indicator_code in (
          'NY.GDP.PCAP.PP.KD',   -- GDP per capita PPP
          'SL.GDP.PCAP.EM.KD',   -- productivity (5-country)
          'SL.UEM.TOTL.NE.ZS',   -- total unemployment
          'SL.UEM.1524.NE.ZS'    -- youth unemployment
      )
      and year between 2014 and 2024

),

dispersion as (

    select
        indicator_code,
        year,
        count(gap_to_eu)            as n_countries,   -- non-null contributors only: 5 for productivity, 6 elsewhere
        avg(gap_to_eu)              as mean_gap,
        stddev_samp(gap_to_eu)      as sd_gap         -- sample SD (n-1); appropriate for a small cross-section
    from wb_six
    group by indicator_code, year

)

select
    indicator_code,
    year,
    n_countries,
    mean_gap,
    sd_gap,
    -- CV as a fraction; null-guarded so a zero or null mean can never divide-by-zero.
    -- Multiply by 100 in the notebook/Tableau if you want CV as a percentage.
    case
        when mean_gap is null or mean_gap = 0 then null
        else sd_gap / mean_gap
    end as cv_gap
from dispersion
order by indicator_code, year