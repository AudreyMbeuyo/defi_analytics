# 📊 DeFi Analytics — Pipeline & Modélisation SQL

Ce projet académique d'ingénierie des données vise à concevoir un pipeline analytique de bout en bout pour explorer les données de la Finance Décentralisée (Decentralized Finance — DeFi).

Il s'appuie sur une architecture Medallion (Bronze, Silver, Gold), avec PostgreSQL pour le stockage et les transformations SQL, dbt pour l'industrialisation du pipeline et Power BI pour la visualisation.

L'objectif est de transformer des données brutes issues de fichiers CSV et Parquet en un modèle décisionnel structuré, permettant d'analyser les rendements, la liquidité et certains indicateurs de risque des pools DeFi.

## ❓ Problématique métier

« Quels pools de rendement DeFi présentent le meilleur compromis entre rendement (APY), liquidité (TVL) et indicateurs de risque, selon les blockchains et les protocoles ? »

## 👥 Équipe & Organisation Git
- **Membres :** Audrey Mbeuyo & Huyen Tran
- **Branches :**
  - `main` : version stable et validée du projet
  - `audrey` : branche de travail d'Audrey
  - `huyen` : branche de travail de Huyen

## 📦 Source des données
- **Dataset Kaggle :** [DeFi Daily: TVL, Stablecoins, DEX & Yields](https://www.kaggle.com/datasets/danielaijdkx/defi-daily-tvl-stablecoins-dex-yields)
- **Source originale :** API publique **DefiLlama** (données quotidiennes en USD, dates UTC).
- **Attribution :** Données fournies par DefiLlama.

## 🛠️ Environnement technique
- **SGBD :** PostgreSQL
- **Scripts & Automatisation :** Python (`pandas`, `pyarrow`, `SQLAlchemy`)
- **Visualisation (livrable final) :** Power BI (modèle en étoile)

## 🏗️ Architecture des données — Medallion Architecture

Le projet adopte une architecture Medallion afin de séparer les différentes étapes de traitement et de garantir la qualité, la traçabilité et la maintenabilité des données.

🥉 Bronze — Raw Data

La couche Bronze stocke les données sources dans PostgreSQL, avec un minimum de transformations.

Traitements :

Importation des fichiers CSV et Parquet via Python.

Création des tables dans le schéma bronze.

Conservation des informations sources.

Vérification du nombre de lignes, des colonnes et des types importés.

Traçabilité des fichiers et des chargements.

🥈 Silver — Cleaned & Transformed Data

La couche Silver prépare les données pour la modélisation analytique.

Traitements prévus :

Gestion des valeurs NULL et des doublons.

Conversion et harmonisation des types de données.

Standardisation des dates et des identifiants.

Contrôles de qualité et de cohérence.

Identification des clés et des relations entre tables.

Transformations SQL et préparation des données de référence.

Les transformations seront progressivement industrialisées avec dbt et accompagnées de tests de qualité.

🥇 Gold — Business Analytics

La couche Gold expose des données structurées pour répondre à la problématique métier.

Objectifs :

Construire un schéma dimensionnel en étoile.

Créer les tables de faits et de dimensions.

Calculer les KPI : APY, TVL, variations et classements.

Préparer des tables ou vues optimisées pour Power BI.

⭐ Modélisation décisionnelle — Star Schema

Le modèle analytique est centré sur les observations temporelles des Yield Pools.

Grain cible : une observation par pool et par date de snapshot, après validation de l'unicité de cette combinaison.

## 📁 Structure du dépôt
```text
defi_analytics/
├── .gitignore
├── README.md
├── docs/          # Fiche projet, justification SGBD, schéma relationnel / étoile
├── scripts/       # Scripts Python d'inspection et d'importation dans PostgreSQL
└── sql/           # Scripts SQL (création des tables, contraintes, requêtes d'analyse)

🏗️ Architecture des données — Medallion Architecture

Le projet adopte une architecture Medallion afin de séparer les différentes étapes de traitement et de garantir la qualité, la traçabilité et la maintenabilité des données.
