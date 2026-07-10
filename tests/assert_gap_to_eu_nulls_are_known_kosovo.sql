-- Null guard for wb_fct_gap_to_eu, scoped to the 2014-2024 study window.
-- A dbt singular test passes when it returns ZERO rows. Within the study
-- window the ONLY expected null is Kosovo (XKX) on SL.GDP.PCAP.EM.KD
-- (productivity), all 11 years -- the documented Kosovo asymmetry. Any other
-- null means either a new legitimate data gap (update this test AND the
-- _models.yml description together) or an upstream ingestion break.
-- Pre-2014 nulls (XKX labour/unemployment 2008-2011, MNE youth unemployment
-- 2008-2010) are real but out of scope and deliberately not guarded here.
-- gap_to_eu is null exactly when value is null, so checking value suffices.

select
    country_iso3,
    indicator_code,
    year,
    value,
    gap_to_eu
from {{ ref('wb_fct_gap_to_eu') }}
where year between 2014 and 2024
  and value is null
  and not (country_iso3 = 'XKX' and indicator_code = 'SL.GDP.PCAP.EM.KD')