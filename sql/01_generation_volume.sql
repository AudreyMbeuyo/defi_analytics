delete from fact_yield_pools where date_id < '2026-10-10';
delete from dim_date where date_id < '2026-10-10';

insert into dim_date (date_id, annee, trimestre, mois , jour )
select dd.date_id - (k*45),
extract (year from dd.date_id - (k*45)) :: smallint,
extract (quarter from dd.date_id - (k*45)) :: smallint,
extract (month from dd.date_id - (k*45)) :: smallint,
extract (day from dd.date_id - (k*45)) :: smallint
from dim_date dd
cross join  generate_series(1, 99) AS k
where  dd.date_id >= '2026-10-10'
on conflict (date_id) do nothing;

insert into fact_yield_pools (date_id, pool_id, chain, protocol_slug, tvl_usd, apy, apy_base, apy_reward, apy_mean_30d, volume_usd_1d )
select fyp.date_id - (k * 45), fyp.pool_id, fyp.chain, fyp.protocol_slug,
round((fyp.tvl_usd *(0.7 + random ()*0.6))::numeric,2),
round((fyp.apy*(0.6 + random()*0.8))::numeric,5),
fyp.apy_base,
fyp.apy_reward,
fyp.apy_mean_30d,
round((fyp.volume_usd_1d *(0.1 + random ()*0.9))::numeric,2)
from fact_yield_pools fyp
cross join  generate_series(1, 99) AS k
where fyp.date_id >= '2026-10-10';

analyze dim_date;
analyze fact_yield_pools;