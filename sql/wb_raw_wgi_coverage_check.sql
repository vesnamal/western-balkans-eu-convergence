-- Coverage / data-quality check for the WGI governance raw layer.
-- Expected: EUU absent (WGI rates countries, not aggregates); all others
-- 51 rows (3 codes x 17 years), zero nulls — WGI is a fully balanced panel.
-- Note: Kosovo (XKX) is COMPLETE on governance despite being thin on the
-- economic basket — governance panel needs no Kosovo caveat.
SELECT country_iso3,
       COUNT(*)                  AS total_rows,
       COUNT(value)              AS non_null,
       COUNT(*) - COUNT(value)   AS nulls
FROM s_vesnamalenica.wb_raw_wgi
GROUP BY country_iso3
ORDER BY country_iso3;