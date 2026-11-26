-- === TP1 : REQUETES FONDAMENTALES ===

'Écris une requête SQL (et teste-la dans le Query Tool de pgAdmin 4) qui affiche, uniquement pour la date ''2026-11-23'' :
- La blockchain (chain),
- La catégorie du protocole (category — présente dans dim_protocol),
- Le nombre de pools dans ce groupe,
- La TVL totale en dollars (arrondie à 2 décimales avec ROUND(..., 2) si tu veux que ce soit lisible),
- Le rendement moyen (apy moyen, arrondi à 2 décimales).
Contraintes :
- Ne garder que les groupes qui comptent au moins 10 pools ET une TVL totale strictement supérieure à 100 000 000 $ (100 millions).
- Trier du plus grand rendement moyen au plus petit.'

select fyp.chain,
dpr.category,
count (fyp.pool_id) as nb_pool,
round(sum(fyp.tvl_usd),2) as tvl_totale,
round(avg(fyp.apy),2) as rendement_moyen
from fact_yield_pools fyp
inner join dim_protocol dpr
on fyp.protocol_slug = dpr.slug
where fyp.date_id = '2026-11-23'
Group by dpr.category, fyp.chain
having count (fyp.pool_id) >= 10 and sum(fyp.tvl_usd) > 100000000
order by rendement_moyen desc;

'Écris une requête SQL (et teste-la dans pgAdmin 4) qui affiche, pour la date la plus récente disponible dans fact_yield_pools :
- Le symbole du pool (symbol dans dim_pool),
- La blockchain (chain),
- Le nom du protocole (name dans dim_protocol),
- La TVL (tvl_usd) et le rendement apy (arrondis à 2 décimales).
Conditions :
- Ne garder que les pools sûrs : stablecoin = TRUE ET il_risk = ''no'' (dans dim_pool).
- Ne garder que ceux dont l''apy est strictement supérieur à la moyenne des apy à cette date la plus récente.
- Trier du plus grand apy au plus petit, et n''afficher que les 15 premiers .'

select dpl.symbol,
fyp.chain, dpr.name,
round(fyp.tvl_usd,2) as tvl,
round (fyp.apy,2) as apy
from dim_pool dpl
inner join fact_yield_pools fyp
on fyp.pool_id = dpl.pool_id
inner join dim_protocol dpr
on dpr.slug = fyp.protocol_slug
where fyp.date_id = (select max(date_id) from fact_yield_pools)
and (dpl.stablecoin is True and dpl.il_risk = 'no')
and fyp.apy > (select avg(apy) from fact_yield_pools
where date_id = (select max(date_id) from fact_yield_pools) )
order by apy desc
limit 15;

'Écris une requête SQL (et teste-la dans pgAdmin 4) qui affiche :
- La catégorie de protocole (category dans dim_protocol),
- Le nombre de protocoles distincts dans cette catégorie qui n''ont aucun pool dans fact_yield_pools
Conditions :
- Filtrer pour ne garder que ceux sans correspondance.
- Trier du plus grand nombre de protocoles sans pool au plus petit .'

select dpr.category,
count (distinct dpr.slug) as nb_protocoles
from dim_protocol dpr
left join fact_yield_pools fyp
on dpr.slug = fyp.protocol_slug
where fyp.pool_id is null
group by dpr.category
order by nb_protocoles desc;


-- === TP2 : REQUETES AVANCEES ===

'À la date du 2026-11-23, un investisseur veut connaître,
pour chaque blockchain, les 3 placements les plus rentables
(le rendement apy le plus élevé) parmi ceux qui sont suffisamment liquides (au moins 5 000 000 $ de TVL).'

with p1 as (
select fyp.chain,
dpl.symbol,
dpr.name,
round(fyp.tvl_usd,2) as tvl_usd,
round (fyp.apy,2) as apy,
row_number() over(partition by fyp.chain order by apy desc) as row_num
from fact_yield_pools fyp
inner join dim_pool dpl on fyp.pool_id = dpl.pool_id
inner join dim_protocol dpr on dpr.slug = fyp.protocol_slug
where fyp.date_id = '2026-11-23'
and fyp.apy is not null
and fyp.tvl_usd >= 5000000
)

select * from p1
where row_num <=3
order by chain, row_num;


'Sur les données réelles récentes (à partir du 2026-10-10), on veut mesurer l''évolution quotidienne
du rendement des très gros pools sur Ethereum (ceux ayant une TVL d''au moins 100 000 000 $).'

select fyp.date_id,
dpl.symbol,
round(fyp.apy,2) as apy,
round(lag(fyp.apy,1) over(partition by fyp.pool_id order by fyp.date_id),2) as apy_prec,
round((fyp.apy - lag(fyp.apy,1) over(partition by fyp.pool_id order by fyp.date_id)),2) as var_apy
from fact_yield_pools fyp
inner join dim_pool dpl on dpl.pool_id = fyp.pool_id
where fyp.date_id >= '2026-10-10'
and fyp.tvl_usd >= 100000000
and fyp.chain ='Ethereum'
order by dpl.symbol, fyp.pool_id, fyp.date_id
limit 30;


-- Énoncé : À la date du 23/11/2026, on prend tous les pools ayant une TVL et un APY renseignés.
-- On les découpe en 4 groupes égaux (quartiles) du plus riche en TVL (groupe 1) au moins riche (groupe 4),
-- puis on affiche pour chaque groupe : le numéro du groupe, le nombre de pools, la TVL min, la TVL max et l'APY moyen.
with pools_quartiles as (
    select
        fyp.pool_id,
        fyp.tvl_usd,
        fyp.apy,
        ntile(4) over(order by fyp.tvl_usd desc) as quartile_tvl
    from fact_yield_pools fyp
    where fyp.date_id = '2026-11-23'
      and fyp.tvl_usd is not null
      and fyp.apy is not null
)
select
    quartile_tvl,
    count(*) as nb_pools,
    round(min(tvl_usd), 2) as tvl_min,
    round(max(tvl_usd), 2) as tvl_max,
    round(avg(apy), 2) as apy_moyen
from pools_quartiles
group by quartile_tvl
order by quartile_tvl;



-- Énoncé : Sur la période réelle depuis le 10/10/2026, pour les pools stablecoins sur Ethereum
-- ayant une TVL d'au moins 50 millions $ (et un APY et un volume renseignés),
-- afficher pour chaque date et chaque pool : son APY du jour, sa moyenne mobile d'APY sur 7 jours
-- (le jour même + les 6 jours précédents) et son volume cumulé depuis le début de la période (40 premières lignes).
select
    fyp.date_id,
    dpl.symbol,
    round(fyp.apy, 2) as apy_jour,
    round(
        avg(fyp.apy) over(
            partition by fyp.pool_id
            order by fyp.date_id
            rows between 6 preceding and current row
        ),
        2
    ) as apy_moyenne_mobile_7j,
    round(
        sum(fyp.volume_usd_1d) over(
            partition by fyp.pool_id
            order by fyp.date_id
            rows between unbounded preceding and current row
        ),
        2
    ) as volume_cumule
from fact_yield_pools fyp
inner join dim_pool dpl on dpl.pool_id = fyp.pool_id
where fyp.date_id >= '2026-10-10'
  and fyp.chain = 'Ethereum'
  and dpl.stablecoin is true
  and fyp.tvl_usd >= 50000000
  and fyp.apy is not null
  and fyp.volume_usd_1d is not null
order by dpl.symbol, fyp.pool_id, fyp.date_id
limit 40;


-- Énoncé : À partir des protocoles qui ont une maison-mère renseignée dans dim_protocol,
-- construire la hiérarchie sur 2 niveaux : niveau 1 = la maison-mère (parent_protocol),
-- niveau 2 = les protocoles rattachés (slug), en conservant le nom de la racine d'origine (40 premières lignes).
with recursive hierarchie as (
    select distinct
        parent_protocol as element,
        parent_protocol as racine,
        1 as niveau
    from dim_protocol
    where parent_protocol is not null

    union all

    select
        dpr.slug as element,
        h.racine,
        h.niveau + 1 as niveau
    from dim_protocol dpr
    inner join hierarchie h on dpr.parent_protocol = h.element
    where h.niveau = 1
)
select racine, niveau, element
from hierarchie
order by racine, niveau, element
limit 40;



-- Énoncé : Identifier les 3 meilleurs pools par catégorie de protocole sur la période réelle (depuis le 10/10/2026).
-- Étape 1 (donnees_reelles) : joindre les faits, les pools et les protocoles depuis le 10/10/2026 (TVL et APY renseignés).
-- Étape 2 (stats_par_pool) : calculer par pool sa TVL moyenne et son APY moyen en ne gardant que ceux observés au moins 30 jours avec >= 10M$ de TVL moyenne.
-- Étape 3 (classement_final) : classer les pools retenus par APY moyen décroissant au sein de chaque catégorie (sans trou en cas d'égalité),
-- puis afficher uniquement le top 3 de chaque catégorie.
with
donnees_reelles as (
    select
        fyp.pool_id,
        fyp.chain,
        dpl.symbol,
        dpl.stablecoin,
        dpl.il_risk,
        dpr.name as protocole,
        dpr.category,
        fyp.tvl_usd,
        fyp.apy
    from fact_yield_pools fyp
    inner join dim_pool dpl on dpl.pool_id = fyp.pool_id
    inner join dim_protocol dpr on dpr.slug = fyp.protocol_slug
    where fyp.date_id >= '2026-10-10'
      and fyp.tvl_usd is not null
      and fyp.apy is not null
),
stats_par_pool as (
    select
        pool_id,
        symbol,
        chain,
        protocole,
        category,
        stablecoin,
        il_risk,
        count(*) as nb_jours,
        round(avg(tvl_usd), 2) as tvl_moyenne,
        round(avg(apy), 2) as apy_moyen
    from donnees_reelles
    group by pool_id, symbol, chain, protocole, category, stablecoin, il_risk
    having count(*) >= 30
       and avg(tvl_usd) >= 10000000
),
classement_final as (
    select
        category,
        symbol,
        protocole,
        chain,
        stablecoin,
        il_risk,
        tvl_moyenne,
        apy_moyen,
        dense_rank() over(partition by category order by apy_moyen desc) as rang_categorie
    from stats_par_pool
)
select
    category,
    rang_categorie,
    symbol,
    protocole,
    chain,
    stablecoin,
    il_risk,
    tvl_moyenne,
    apy_moyen
from classement_final
where rang_categorie <= 3
order by category, rang_categorie, tvl_moyenne desc;