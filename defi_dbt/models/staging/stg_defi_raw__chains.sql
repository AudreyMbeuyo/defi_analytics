with source as (

    select * from {{ source('defi_raw', 'chains') }}

),

renamed as (

    select
        snapshot_date::date as snapshot_date,
        trim(chain) as chain_name,
        trim(token_symbol) as token_symbol,
        trim(chain_id) as evm_chain_id,
        tvl_usd::numeric as tvl_usd
    from source

)

select * from renamed