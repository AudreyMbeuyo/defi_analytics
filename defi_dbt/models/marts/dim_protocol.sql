-- Dimension Protocoles pure DeFi (1 ligne unique par protocole avec clé de substitution)
with derniers_protocoles as (

    select
        protocol_slug,
        protocol_name,
        category,
        parent_protocol,
        n_chains,
        listed_at,
        row_number() over(partition by protocol_slug order by snapshot_date desc) as rang
    from {{ ref('int_yield_pools_enriched') }}

)

select
    -- Clé de substitution déterministe
    md5(protocol_slug) as protocol_id,
    protocol_slug,
    protocol_name,
    category,
    parent_protocol,
    n_chains,
    listed_at
from derniers_protocoles
where rang = 1