-- Dimension temporelle (grain : 1 ligne par jour)
with dates_distinctes as (

    select distinct
        snapshot_date
    from {{ ref('int_yield_pools_enriched') }}

)

select
    snapshot_date as date_id,
    extract(year from snapshot_date)::smallint as annee,
    extract(quarter from snapshot_date)::smallint as trimestre,
    extract(month from snapshot_date)::smallint as mois,
    extract(day from snapshot_date)::smallint as jour,
    extract(isodow from snapshot_date)::smallint as jour_semaine
from dates_distinctes