-- Couche Intermediate : enrichissement des pools pure DeFi avec les protocoles et blockchains
with yield_pools as (

    select * from {{ ref('stg_defi_raw__yield_pools') }}

),

protocols as (

    select * from {{ ref('stg_defi_raw__protocols') }}

),

chains as (

    select * from {{ ref('stg_defi_raw__chains') }}

),

enriched as (

    select
        yp.yield_snapshot_id,
        yp.snapshot_date,
        yp.pool_id,
        yp.chain_name,
        yp.protocol_slug,
        yp.pool_symbol,
        yp.pool_meta,
        yp.is_stablecoin,
        yp.il_risk,
        yp.exposure,
        yp.tvl_usd,
        yp.apy,
        yp.apy_base,
        yp.apy_reward,
        yp.apy_mean_30d,
        yp.volume_usd_1d,
        -- Informations du protocole (pure DeFi)
        pr.protocol_name,
        pr.category,
        pr.parent_protocol,
        pr.n_chains,
        pr.listed_at,
        -- Informations de la blockchain
        ch.token_symbol as chain_token_symbol,
        ch.evm_chain_id
    from yield_pools yp
    -- Jointure sur la date et le protocole pour éviter toute duplication sur les 39 jours
    inner join protocols pr
        on yp.snapshot_date = pr.snapshot_date
       and yp.protocol_slug = pr.protocol_slug
    -- Left join pour conserver tous les pools même si une blockchain manque dans raw.chains
    left join chains ch
        on yp.snapshot_date = ch.snapshot_date
       and yp.chain_name = ch.chain_name
    -- Exclure les plateformes centralisées (CEX) et garantir une TVL valide
    where pr.category != 'CEX'
      and yp.tvl_usd >= 0

)

select * from enriched