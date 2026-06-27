
-- Coverage / data-quality check for the WDI raw layer.
-- Per indicator: total rows landed, non-null observations, and null gaps.
-- A high null count flags a known coverage limitation (e.g. Kosovo on
-- productivity = 17 nulls = all 17 years absent, per indicators.yml).


SELECT indicator_code,
       COUNT(*) AS total_rows,
       COUNT(value) AS non_null,
       COUNT(*) - COUNT(value) AS nulls
FROM s_vesnamalenica.wb_raw_wdi
GROUP BY indicator_code
ORDER BY indicator_code;