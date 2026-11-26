-- Test métier : aucune TVL ne peut être négative ou nulle, et aucun volume 24h ne peut être négatif
select
    yield_snapshot_id,
    date_id,
    pool_id,
    tvl_usd,
    volume_usd_1d
from {{ ref('fct_yield_pools') }}
where tvl_usd < 0
   or tvl_usd is null
   or volume_usd_1d < 0