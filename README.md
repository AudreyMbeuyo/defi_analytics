# 📊 DeFi Analytics — Pipeline & Modélisation SQL

Projet académique d'ingénierie des données et de modélisation SQL autour de la **Finance Décentralisée (DeFi)** : analyse des rendements (*APY*), de la liquidité (*TVL*) et des indicateurs de risque des pools DeFi.

## 🎯 Question métier
> *« Quel pool de finance décentralisée présente le meilleur compromis entre rendement, liquidité et indicateurs de risque selon les blockchains et les protocoles ? »*

**Axes d'analyse Power BI :**
- Classement des blockchains et catégories de protocoles selon la TVL et le rendement moyen (`APY`)
- Évolution quotidienne des rendements (`APY base` vs `APY reward`) sur la période observée
- Comparaison des pools risqués (`il_risk = yes`) et des pools sûrs (`stablecoin = True`)

## 👥 Équipe & Organisation Git
- **Membres :** Audrey Mbeuyo & Huyen Tran
- **Branches :**
  - `main` : version stable et validée du projet
  - `audrey` : branche de développement d'Audrey
  - `huyen` : branche de développement de Huyen

## 📦 Source des données & Licence
- **Dataset Kaggle :** [DeFi Daily: TVL, Stablecoins, DEX & Yields](https://www.kaggle.com/datasets/danielaijdkx/defi-daily-tvl-stablecoins-dex-yields)
- **Source originale :** API publique **DefiLlama** (données quotidiennes en USD, dates UTC)
- **Licence & Attribution :** Données publiques DefiLlama avec attribution requise 

## 🛠️ Environnement technique
- **SGBD :** PostgreSQL 19 (schéma en étoile à 5 tables, porté à **10 030 700 lignes** sur `fact_yield_pools`)
- **Ingestion Python :** `pandas`, `pyarrow`, `pg8000`
- **Transformation :** `dbt-postgres`
- **Visualisation :** Power BI

## 📁 Structure du dépôt
```text
defi_analytics/
├── .gitignore
├── README.md
├── docs/
│   ├── guide_migration.md         # Guide d'installation et d'import Python -> PostgreSQL
│   ├── rapport_performance.md     # Benchmarks EXPLAIN ANALYZE avant / après indexation
│   └── schema_relationnel.png     # Schéma en étoile (ERD PostgreSQL)
├── scripts/
│   ├── inspect_data.py            # Inspection des fichiers CSV / Parquet
│   └── load_to_postgres.py        # Chargement des données pure DeFi dans PostgreSQL
└── sql/
    ├── 00_creation_schema.sql     # Création des 5 tables, PK, FK et contraintes
    ├── 01_generation_volume.sql   # Génération rejouable à ~10 millions de lignes + ANALYZE
    ├── 02_requetes_avancees.sql   # Requêtes TP1 (fondamentales) et TP2 (avancées)
    └── 03_index.sql               # Index créés pour les benchmarks de performance
```
