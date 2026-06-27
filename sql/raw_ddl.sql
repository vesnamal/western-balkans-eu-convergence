CREATE TABLE IF NOT EXISTS s_vesnamalenica.wb_raw_wdi (
    source         TEXT        NOT NULL,
    indicator_code TEXT        NOT NULL,
    country_iso3   TEXT        NOT NULL,
    year           INTEGER     NOT NULL,
    value          DOUBLE PRECISION,
    ingested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    batch_id       TEXT        NOT NULL
);

CREATE TABLE IF NOT EXISTS s_vesnamalenica.wb_raw_wgi (
    source         TEXT        NOT NULL,
    indicator_code TEXT        NOT NULL,
    country_iso3   TEXT        NOT NULL,
    year           INTEGER     NOT NULL,
    value          DOUBLE PRECISION,
    ingested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    batch_id       TEXT        NOT NULL
);