# Rapport de Performance SQL — Projet DeFi Analytics

## 1. Environnement et protocole de test
- **SGBD :** PostgreSQL 19 (port 5433)
- **Table principale :** `fact_yield_pools` (**10 030 700 lignes** après génération via `sql/01_generation_volume.sql`)
- **Mise à jour des statistiques :** `ANALYZE` exécuté après le passage à 10 millions de lignes, puis après la création des index (`sql/03_index.sql`).
- **Protocole de benchmark :** Chaque requête a été exécutée **3 fois consécutives** pour travailler à cache chaud. Nous avons relevé la **médiane** des 3 temps pgAdmin ainsi que l'`Execution Time` et les `Buffers` du plan `EXPLAIN (ANALYZE, BUFFERS)`.

---

## 2. Tableau comparatif des 3 benchmarks

| Requête | Médiane Avant (Exec. Time) | Opérateur Avant | Index testé (`03_index.sql`) | Médiane Après (Exec. Time) | Opérateur Après | Gain / Conclusion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **B1** — Agrégat Solana ($\text{TVL} \ge 10\text{M\$}$) | 1 741 ms (`1527.1 ms`) | `Parallel Seq Scan` (`164 596` buffers) | `idx_fyp_chain_tvl` sur `(chain, tvl_usd)` | 735 ms (`709.9 ms`) | `Parallel Seq Scan` (`164 599` buffers) | Index non retenu par l'optimiseur (faible sélectivité sur Solana, baisse due au cache) |
| **B2** — Fenêtre `LAG` sur `uniswap-v2` (`LIMIT 50`) | 73 ms (`36.8 ms`) | `Index Scan` PK (`32 263` buffers) | `idx_fyp_protocol_date_cov` (`INCLUDE`) | 125 ms (`68.1 ms`) | `Index Only Scan` (`552` buffers, `Heap Fetches: 0`) | **-98,3 % de buffers lus** (temps plus haut à cause du `LIMIT 50`) |
| **B3** — Fenêtre `RANK` pools $\ge 500\text{M\$}$ (`LIMIT 50`) | 927 ms (`2124.5 ms`) | `Parallel Seq Scan` + `Disk Sort` (`164 594` buffers) | `idx_fyp_chain_tvl` + `idx_fyp_whale_pools` | 76 ms (**`4.75 ms`**) | `Index Scan` (`3 461` buffers, pré-trié par `chain`) | **~12× (chrono) / ~447× (`Execution Time`)**, suppression du tri sur disque |

---

## 3. Détail des benchmarks

### Benchmark 1 : Jointure et agrégation par catégorie sur Solana ($\text{TVL} \ge 10\text{M\$}$)

#### Requête testée
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT dpr.category, COUNT(*) AS nb_snapshots, ROUND(AVG(fyp.apy), 2) AS apy_moyen
FROM fact_yield_pools fyp
INNER JOIN dim_protocol dpr ON dpr.slug = fyp.protocol_slug
WHERE fyp.chain = 'Solana'
  AND fyp.tvl_usd >= 10000000
GROUP BY dpr.category
ORDER BY apy_moyen DESC;
```

#### Mesures AVANT index (`1805 ms`, `1741 ms`, `1550 ms` $\rightarrow$ médiane `1741 ms`)
```text
Sort  (cost=229372.25..229372.47 rows=89 width=49) (actual time=1515.084..1527.015 rows=8.00 loops=1)
  Sort Key: (round(avg(fyp.apy), 2)) DESC
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=15031 read=149565
  ->  Finalize GroupAggregate  (cost=229325.29..229369.37 rows=89 width=49) (actual time=1514.977..1526.996 rows=8.00 loops=1)
        Group Key: dpr.category
        ->  Gather Merge  (cost=229325.29..229364.65 rows=338 width=49) (actual time=1514.957..1526.921 rows=98.00 loops=1)
              Workers Planned: 2 / Workers Launched: 2
              ->  Sort  (cost=228325.26..228325.62 rows=141 width=49) (actual time=1474.114..1474.117 rows=32.67 loops=3)
                    ->  Nested Loop  (cost=228214.12..228320.23 rows=141 width=49) (actual time=1473.764..1474.055 rows=32.67 loops=3)
                          ->  Partial HashAggregate  (cost=228213.84..228218.08 rows=339 width=51) (actual time=1473.704..1473.738 rows=32.67 loops=3)
                                ->  Parallel Seq Scan on fact_yield_pools fyp  (cost=0.00..226956.04 rows=167706 width=17) (actual time=2.552..1428.895 rows=122450.33 loops=3)
                                      Filter: ((tvl_usd >= '10000000'::numeric) AND ((chain)::text = 'Solana'::text))
                                      Rows Removed by Filter: 3221116
                                      Buffers: shared hit=14721 read=149565
                          ->  Index Scan using dim_protocol_pkey on dim_protocol dpr  (actual time=0.009..0.009 rows=1.00 loops=98)
Planning Time: 0.415 ms
Execution Time: 1527.123 ms
```

#### Action appliquée
Création d'un index composite B-tree plaçant le filtre d'égalité (`chain`) avant l'inégalité (`tvl_usd`) :
```sql
CREATE INDEX idx_fyp_chain_tvl ON fact_yield_pools (chain, tvl_usd);
```

#### Mesures APRÈS index (`720 ms`, `750 ms`, `735 ms` $\rightarrow$ médiane `735 ms`)
```text
Sort  (cost=229375.22..229375.44 rows=89 width=49) (actual time=699.712..709.823 rows=8.00 loops=1)
  Buffers: shared hit=15995 read=148604
  ->  Finalize GroupAggregate  (actual time=699.607..709.813 rows=8.00 loops=1)
        ->  Gather Merge  (actual time=699.583..709.740 rows=99.00 loops=1)
              ->  Sort  (actual time=664.888..664.892 rows=33.00 loops=3)
                    ->  Nested Loop  (actual time=664.539..664.836 rows=33.00 loops=3)
                          ->  Partial HashAggregate  (actual time=664.491..664.514 rows=33.00 loops=3)
                                ->  Parallel Seq Scan on fact_yield_pools fyp  (cost=0.00..226967.20 rows=166614 width=17) (actual time=1.369..621.819 rows=122450.33 loops=3)
                                      Filter: ((tvl_usd >= '10000000'::numeric) AND ((chain)::text = 'Solana'::text))
                                      Rows Removed by Filter: 3221116
                                      Buffers: shared hit=15682 read=148604
                          ->  Index Scan using dim_protocol_pkey on dim_protocol dpr  (actual time=0.009..0.009 rows=1.00 loops=99)
Planning Time: 0.587 ms
Execution Time: 709.910 ms
```

#### Analyse
PostgreSQL n'a **pas retenu** `idx_fyp_chain_tvl` et a conservé le `Parallel Seq Scan` (toujours `~164 599` buffers lus). Le filtre sur Solana renvoie environ **367 350 lignes** ($\approx 3{,}7\%$ de la table), dispersées sur presque toutes les pages de la table : le planificateur estime que des lectures aléatoires via l'index coûteraient plus cher qu'une lecture séquentielle parallélisée. La baisse de durée observée (`1527 ms` $\rightarrow$ `710 ms`) s'explique uniquement par un cache disque plus chaud, et non par l'index.

---

### Benchmark 2 : Jointure et fonction de fenêtre `LAG` sur `uniswap-v2`

#### Requête testée
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    fyp.date_id,
    dpl.symbol,
    fyp.tvl_usd,
    fyp.apy,
    fyp.apy - LAG(fyp.apy, 1) OVER (PARTITION BY fyp.pool_id ORDER BY fyp.date_id) AS var_apy
FROM fact_yield_pools fyp
INNER JOIN dim_pool dpl ON dpl.pool_id = fyp.pool_id
WHERE fyp.protocol_slug = 'uniswap-v2'
  AND fyp.date_id >= '2025-01-01'
ORDER BY fyp.pool_id, fyp.date_id
LIMIT 50;
```

#### Mesures AVANT index (`337 ms`, `73 ms`, `72 ms` $\rightarrow$ médiane `73 ms`)
```text
Limit  (cost=780.45..3944.63 rows=50 width=96) (actual time=36.627..36.720 rows=50.00 loops=1)
  Buffers: shared hit=32263
  ->  WindowAgg  (actual time=36.626..36.712 rows=50.00 loops=1)
        ->  Incremental Sort  (actual time=36.609..36.616 rows=51.00 loops=1)
              ->  Nested Loop  (actual time=0.036..36.429 rows=584.00 loops=1)
                    ->  Index Scan using dim_pool_pkey on dim_pool dpl  (actual time=0.010..0.032 rows=12.00 loops=1)
                    ->  Index Scan using fact_yield_pools_pkey on fact_yield_pools fyp  (actual time=2.726..3.022 rows=48.67 loops=12)
                          Index Cond: ((date_id >= '2025-01-01'::date) AND ((pool_id)::text = (dpl.pool_id)::text))
                          Filter: ((protocol_slug)::text = 'uniswap-v2'::text)
                          Rows Removed by Filter: 436
                          Index Searches: 6606
                          Buffers: shared hit=32252
Planning Time: 0.372 ms
Execution Time: 36.776 ms
```

#### Action appliquée
Création d'un index couvrant avec `INCLUDE` pour éviter les 6 606 recherches sur la clé primaire et lire toutes les colonnes utiles sans accéder à la table :
```sql
CREATE INDEX idx_fyp_protocol_date_cov
ON fact_yield_pools (protocol_slug, date_id)
INCLUDE (pool_id, tvl_usd, apy);
```

#### Mesures APRÈS index (`131 ms`, `125 ms`, `105 ms` $\rightarrow$ médiane `125 ms`)
```text
Limit  (cost=628.64..3165.59 rows=50 width=96) (actual time=67.753..67.796 rows=50.00 loops=1)
  Buffers: shared hit=552
  ->  WindowAgg  (actual time=67.752..67.791 rows=50.00 loops=1)
        ->  Incremental Sort  (actual time=67.733..67.736 rows=51.00 loops=1)
              ->  Nested Loop  (actual time=0.034..67.580 rows=584.00 loops=1)
                    Join Filter: ((dpl.pool_id)::text = (fyp.pool_id)::text)
                    Rows Removed by Join Filter: 429584
                    ->  Index Scan using dim_pool_pkey on dim_pool dpl  (actual time=0.009..0.156 rows=12.00 loops=1)
                    ->  Materialize  (actual time=0.002..2.545 rows=35847.33 loops=12)
                          ->  Index Only Scan using idx_fyp_protocol_date_cov on fact_yield_pools fyp  (actual time=0.018..5.212 rows=39106.00 loops=1)
                                Index Cond: ((protocol_slug = 'uniswap-v2'::text) AND (date_id >= '2025-01-01'::date))
                                Heap Fetches: 0
                                Buffers: shared hit=541
Planning Time: 0.524 ms
Execution Time: 68.113 ms
```

#### Analyse
L'index couvrant a permis un **`Index Only Scan`** avec **`Heap Fetches: 0`** : les lectures de pages ont chuté de **98,3 %** (`32 263` $\rightarrow$ `552` buffers). Cependant, le temps total est passé de `36,8 ms` à `68,1 ms` à cause du `LIMIT 50` : avant index, le moteur avait trouvé 50 lignes rapidement en parcourant seulement 12 pools, alors qu'avec le nouvel index il a d'abord matérialisé les 39 106 lignes de `uniswap-v2` en mémoire avant la jointure `Nested Loop` (429 584 comparaisons rejetées en RAM).

---

### Benchmark 3 : Jointure et fonction de fenêtre `RANK` sur les très gros pools ($\text{TVL} \ge 500\text{M\$}$)

#### Requête testée
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    fyp.date_id,
    fyp.chain,
    dpr.name,
    fyp.tvl_usd,
    RANK() OVER (PARTITION BY fyp.chain ORDER BY fyp.apy DESC) AS rang_apy
FROM fact_yield_pools fyp
INNER JOIN dim_protocol dpr ON dpr.slug = fyp.protocol_slug
WHERE fyp.tvl_usd >= 500000000
  AND fyp.apy IS NOT NULL
LIMIT 50;
```

#### Mesures AVANT index (`1714 ms`, `927 ms`, `927 ms` $\rightarrow$ médiane `927 ms`)
```text
Limit  (cost=227299.37..227306.07 rows=50 width=46) (actual time=2108.404..2123.035 rows=50.00 loops=1)
  Buffers: shared hit=14819 read=149775, temp read=766 written=981
  ->  WindowAgg  (actual time=2108.403..2123.025 rows=50.00 loops=1)
        ->  Gather Merge  (actual time=2108.389..2122.938 rows=50.00 loops=1)
              ->  Sort  (actual time=2053.115..2053.258 rows=608.67 loops=3)
                    Sort Key: fyp.chain, fyp.apy DESC
                    Sort Method: external merge  Disk: 2544kB
                    ->  Nested Loop  (actual time=2.533..1908.983 rows=49643.67 loops=3)
                          ->  Parallel Seq Scan on fact_yield_pools fyp  (actual time=2.445..1853.205 rows=49643.67 loops=3)
                                Filter: ((apy IS NOT NULL) AND (tvl_usd >= '500000000'::numeric))
                                Rows Removed by Filter: 3293923
                                Buffers: shared hit=14511 read=149775
                          ->  Memoize / Index Scan on dim_protocol dpr
Planning Time: 0.520 ms
Execution Time: 2124.498 ms
```

#### Action appliquée
Indexation de la colonne sélective `tvl_usd` (et création d'un index partiel dédié) :
```sql
CREATE INDEX idx_fyp_whale_pools
ON fact_yield_pools (tvl_usd)
WHERE tvl_usd >= 500000000 AND apy IS NOT NULL;
```

#### Mesures APRÈS index (`99 ms`, `74 ms`, `76 ms` $\rightarrow$ médiane `76 ms`)
```text
Limit  (cost=6290.77..6426.62 rows=50 width=46) (actual time=4.597..4.636 rows=50.00 loops=1)
  Buffers: shared hit=3461
  ->  WindowAgg  (actual time=4.596..4.630 rows=50.00 loops=1)
        ->  Incremental Sort  (actual time=4.582..4.592 rows=50.00 loops=1)
              Sort Key: fyp.chain, fyp.apy DESC
              Presorted Key: fyp.chain
              ->  Nested Loop  (actual time=0.058..3.174 rows=3440.00 loops=1)
                    ->  Index Scan using idx_fyp_chain_tvl on fact_yield_pools fyp  (actual time=0.042..1.806 rows=3440.00 loops=1)
                          Index Cond: (tvl_usd >= '500000000'::numeric)
                          Filter: (apy IS NOT NULL)
                          Index Searches: 7
                          Buffers: shared hit=3449
                    ->  Memoize / Index Scan on dim_protocol dpr
Planning Time: 0.435 ms
Execution Time: 4.754 ms
```

#### Analyse
Gain : l'`Execution Time` passe de **`2 124,5 ms` à `4,75 ms` (447× plus rapide)** et les buffers passent de `164 594` à `3 461`. Fait intéressant : PostgreSQL a préféré **`idx_fyp_chain_tvl`** `(chain, tvl_usd)` plutôt que l'index partiel `idx_fyp_whale_pools`, car `idx_fyp_chain_tvl` fournit les lignes **déjà triées par `chain`** (`Presorted Key: fyp.chain`), ce qui a supprimé le coûteux tri sur disque (`external merge Disk: 2544kB`) nécessaire à `PARTITION BY fyp.chain` !