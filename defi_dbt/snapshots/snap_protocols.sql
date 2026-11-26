{% snapshot snap_protocols %}

{{
    config(
      target_schema='snapshots',
      unique_key='protocol_id',
      strategy='check',
      check_cols=['category', 'parent_protocol', 'n_chains', 'protocol_name']
    )
}}

-- Historisation SCD Type 2 des protocoles DeFi
select
    protocol_id,
    protocol_slug,
    protocol_name,
    category,
    parent_protocol,
    n_chains
from {{ ref('dim_protocol') }}

{% endsnapshot %}