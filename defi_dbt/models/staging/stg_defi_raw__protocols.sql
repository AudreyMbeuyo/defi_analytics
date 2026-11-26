with source as (

    select * from {{ source('defi_raw', 'protocols') }}

),

renamed as (

    select
        snapshot_date::date as snapshot_date,
        trim(protocol_id) as source_protocol_id,
        trim(name) as protocol_name,
        trim (slug) as slug,
        trim(symbol) as token_symbol,
        trim(category) as category,
        trim(primary_chain) as primary_chain,
        trim(chains) as chains,
        n_chains::integer as n_chains,
        tvl_usd::numeric as tvl_usd,

        trim(parent_protocol) as parent_protocol

    from source

)

select * from renamed