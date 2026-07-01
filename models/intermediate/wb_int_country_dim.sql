-- wb_int_country_dim: conformed country dimension, one row per entity.
-- Sourced from the wb_country_roles seed (theory-driven segmentation).
-- Everything downstream joins to this.

select
    country_iso3,
    country_name,
    role,
    ex_yugoslav,
    eu_member
from {{ ref('wb_country_roles') }}