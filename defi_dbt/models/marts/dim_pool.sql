-- Dimension Pools de rendement (attributs descriptifs et indicateurs de risque)
with derniers_pools as (

    select
        pool_id,
        pool_symbol,
        pool_meta,
        is_stablecoin,
        il_risk,
        exposure,
        row_number() over(partition by pool_id order by snapshot_date desc) as rang
    from {{ ref('int_yield_pools_enriched') }}

)

select
    pool_id,
    pool_symbol,
    pool_meta,
    is_stablecoin,
    il_risk,
    exposure
from derniers_pools
where rang = 1