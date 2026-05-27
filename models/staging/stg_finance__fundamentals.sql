{{ config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'finance']
) }}

select
    ticker::varchar                     as ticker,
    metric_name::varchar                as metric_name,
    period_type::varchar                as period_type,
    fiscal_date::date                   as fiscal_date,
    value::numeric                      as value,
    ingested_at::timestamp              as loaded_at
from {{ source('raw', 'Fundamentals') }}
where ticker is not null
  and metric_name is not null
  and fiscal_date is not null
  and value is not null