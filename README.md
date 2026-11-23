# 📊 DeFi Analytics — Pipeline & Modélisation SQL

Projet académique d'ingénierie des données et de modélisation SQL autour de la **Finance Décentralisée (DeFi)** : suivi quotidien de la TVL (*Total Value Locked*), des blockchains, des stablecoins, des volumes/frais des DEX et des pools de rendement (*Yield Pools*).

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

## 📁 Structure du dépôt
```text
defi_analytics/
├── .gitignore
├── README.md
├── docs/          # Fiche projet, justification SGBD, schéma relationnel / étoile
├── scripts/       # Scripts Python d'inspection et d'importation dans PostgreSQL
└── sql/           # Scripts SQL (création des tables, contraintes, requêtes d'analyse)