# Guide de migration des données vers PostgreSQL

Ce guide explique comment recréer la base `defi_analytics` en local et y importer les données depuis Python.

## Prérequis
- **PostgreSQL** (et **pgAdmin 4**) installés
- **Python 3.10+**
- Les fichiers de données présents dans le dossier `data/` (à la racine du dépôt)

## Étape 1 : Récupérer le projet et créer l'environnement Python

```bash
git clone https://github.com/AudreyMbeuyo/defi_analytics.git
cd defi_analytics
```

Créer et activer un environnement virtuel, puis installer les dépendances :

```bash
python -m venv .venv
# Sur Windows (Git Bash) :
source .venv/Scripts/activate
# Sur Mac / Linux :
# source .venv/bin/activate

pip install pandas pyarrow pg8000
```

*(Sur PyCharm : lier l'interpréteur `.venv` et installer `pandas`, `pyarrow`, `pg8000` via l'onglet **Python Packages**).*

## Étape 2 : Créer la base et le schéma dans PostgreSQL

1. Ouvrir **pgAdmin 4**.
2. Créer une base de données vide nommée exactement **`defi_analytics`** (*clic droit sur Databases > Create > Database*).
3. Noter le **port** du serveur PostgreSQL (*clic droit sur le serveur > Properties > Connection*, généralement `5432` ou `5433`).
4. Ouvrir un **Query Tool** sur `defi_analytics`, copier le contenu de `sql/00_creation_schema.sql` et l'exécuter (**F5**).
5. Vérifier dans `Schemas > public > Tables` que les **5 tables** sont créées :
   - `dim_date`
   - `dim_chain`
   - `dim_protocol`
   - `dim_pool`
   - `fact_yield_pools`

## Étape 3 : Importer les données avec Python

Depuis la racine du projet (ou dans le terminal de PyCharm), exécuter :

```bash
.venv/Scripts/python.exe scripts/load_to_postgres.py
```

Renseigner au clavier :
- Le **port** PostgreSQL (`5432` par défaut, ou `5433` si applicable)
- Le **mot de passe** de l'utilisateur `postgres`

## Résultat attendu (environ 100 000 lignes pure DeFi)

Le script filtre automatiquement les protocoles `CEX` et les pools sans protocole rattaché, puis charge les 5 tables :
- `dim_date` : 39 lignes
- `dim_chain` : 68 lignes
- `dim_protocol` : 7 409 lignes
- `dim_pool` : 3 375 lignes
- `fact_yield_pools` : 100 307 lignes