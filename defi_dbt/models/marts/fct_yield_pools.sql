-- Table de faits centrale : 1 ligne par pool et par jour (schéma en étoile OLAP)
with base as (

    select
        snapshot_date,
        pool_id,
        chain_name,
        protocol_slug,
        tvl_usd,
        apy,
        apy_base,
        apy_reward,
        apy_mean_30d,
        volume_usd_1d
    from {{ ref('int_yield_pools_enriched') }}

),

dates as (

    select date_id from {{ ref('dim_date') }}

),

chains as (

    select chain_id, chain_name from {{ ref('dim_chain') }}

),

protocols as (

    select protocol_id, protocol_slug from {{ ref('dim_protocol') }}

),

pools as (

    select pool_id from {{ ref('dim_pool') }}

)

select
    -- Clé de substitution du fait (unicité du grain jour + pool)
    md5(concat(b.snapshot_date, '_', b.pool_id)) as yield_snapshot_id,
    -- Clés étrangères vers les 4 dimensions
    d.date_id,
    p.pool_id,
    c.chain_id,
    pr.protocol_id,
    -- Mesures numériques
    b.tvl_usd,
    b.apy,
    b.apy_base,
    b.apy_reward,
    b.apy_mean_30d,
    b.volume_usd_1d
from base b
inner join dates d on b.snapshot_date = d.date_id
inner join pools p on b.pool_id = p.pool_id
inner join chains c on b.chain_name = c.chain_name
inner join protocols pr on b.protocol_slug = pr.protocol_slug