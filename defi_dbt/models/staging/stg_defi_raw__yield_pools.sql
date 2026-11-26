with source as (

    select * from {{ source('defi_raw', 'yield_pools') }}

),

renamed as (

    select
        snapshot_date::date as snapshot_date,
        trim(pool_id) as pool_id,
        trim(chain) as chain_name,
        lower(trim (project)) as protocol_slug,
        trim(symbol) as pool_symbol,
        trim(pool_meta) as pool_meta,
        lower(trim(il_risk)) as il_risk,
        lower(trim(exposure)) as exposure,
        stablecoin::boolean as is_stablecoin,
        tvl_usd::numeric as tvl_usd,
        apy::numeric as apy,
        apy_base::numeric as apy_base,
        apy_reward::numeric as apy_reward,
        apy_mean_30d::numeric as apy_mean_30d,
        volume_usd_1d::numeric as volume_usd_1d,
        concat(snapshot_date::date, '_', trim(pool_id)) as yield_snapshot_id

    from source
)

select * from renamed