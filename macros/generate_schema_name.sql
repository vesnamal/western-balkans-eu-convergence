{% macro generate_schema_name(custom_schema_name, node) -%}

    {#-
        Shared RDS guardrail: this project has no CREATE SCHEMA rights.
        Always build into the single target schema (s_vesnamalenica),
        ignoring any custom schema a model might request. Layer
        separation is done via the wb_ model-name prefix, not schemas.
    -#}
    {{ target.schema | trim }}

{%- endmacro %}