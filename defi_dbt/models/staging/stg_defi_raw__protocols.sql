with source as (

    select * from {{ source('defi_raw', 'protocols') }}

),

renamed as (

    select
        snapshot_date::date as snapshot_date,
        trim(protocol_id) as source_protocol_id,
        trim(name) as protocol_name,
        lower(trim (slug)) as protocol_slug,
        trim(symbol) as token_symbol,
        trim(category) as category,
        trim(primary_chain) as primary_chain,
        trim(chains) as chains,
        n_chains::integer as n_chains,
        tvl_usd::numeric as tvl_usd,
        change_1h_pct::numeric as change_1h_pct,
        change_1d_pct::numeric as change_1d_pct,
        change_7d_pct::numeric as change_7d_pct,
        mcap_usd::numeric as mcap_usd,
        lower(trim(parent_protocol)) as parent_protocol,
        listed_at::timestamp as listed_at,
        concat(snapshot_date::date, '_', lower(trim(slug))) as protocol_snapshot_id
    from source
)

select * from renamed