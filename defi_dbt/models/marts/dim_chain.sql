-- Dimension Blockchains (1 ligne unique par blockchain avec clé de substitution)
with dernieres_infos as (

    select
        chain_name,
        chain_token_symbol,
        evm_chain_id,
        row_number() over(partition by chain_name order by snapshot_date desc) as rang
    from {{ ref('int_yield_pools_enriched') }}

)

select
    -- Clé de substitution déterministe
    md5(chain_name) as chain_id,
    chain_name,
    chain_token_symbol,
    evm_chain_id
from dernieres_infos
where rang = 1