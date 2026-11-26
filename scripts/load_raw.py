from getpass import getpass
from io import StringIO
from pathlib import Path
import pandas as pd
import pg8000.native

# Connexion à PostgreSQL
data_dir = Path(__file__).resolve().parent.parent / "data"
port_input = input("Port PostgreSQL (Entrée pour 5432) : ").strip()
port = int(port_input) if port_input else 5432
password = getpass("Mot de passe PostgreSQL (utilisateur postgres) : ")

# Création du schéma raw et 3 tables vides (raw.chains, raw.protocols, raw.yield_pools)
# avec les mêmes colonnes que les fichiers_.parquet, sans contraintes.
ddl = """
CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.chains, raw.protocols, raw.yield_pools CASCADE;

CREATE TABLE raw.chains (
    snapshot_date TIMESTAMP,
    chain TEXT,
    tvl_usd NUMERIC,
    token_symbol TEXT,
    chain_id TEXT
);

CREATE TABLE raw.protocols (
    snapshot_date TIMESTAMP,
    protocol_id TEXT,
    name TEXT,
    slug TEXT,
    symbol TEXT,
    category TEXT,
    primary_chain TEXT,
    chains TEXT,
    n_chains NUMERIC,
    tvl_usd NUMERIC,
    change_1h_pct NUMERIC,
    change_1d_pct NUMERIC,
    change_7d_pct NUMERIC,
    mcap_usd NUMERIC,
    parent_protocol TEXT,
    listed_at TIMESTAMP
);

CREATE TABLE raw.yield_pools (
    snapshot_date TIMESTAMP,
    pool_id TEXT,
    chain TEXT,
    project TEXT,
    symbol TEXT,
    pool_meta TEXT,
    tvl_usd NUMERIC,
    apy NUMERIC,
    apy_base NUMERIC,
    apy_reward NUMERIC,
    apy_mean_30d NUMERIC,
    stablecoin BOOLEAN,
    il_risk TEXT,
    exposure TEXT,
    volume_usd_1d NUMERIC
);
"""

files = [
    ("raw.chains", "chains_snapshots.parquet"),
    ("raw.protocols", "protocols_snapshots.parquet"),
    ("raw.yield_pools", "yield_pools_snapshots.parquet"),
]

# Ouverture de la connexion vers la base defi_analytics dans PostgreSQL.
con = pg8000.native.Connection(
    user="postgres",
    password=password,
    host="localhost",
    port=port,
    database="defi_analytics",
)

## Envoi rapide des fichiers parquet vers PostgreSQL via COPY
try:
    con.run("START TRANSACTION")
    for stmt in ddl.strip().split(";"):
        if stmt.strip():
            con.run(stmt)
    for table_name, filename in files:
        df = pd.read_parquet(data_dir / filename)
        buf = StringIO()
        df.to_csv(buf, index=False)
        buf.seek(0)
        cols = ", ".join(df.columns)
        con.run(f"COPY {table_name} ({cols}) FROM STDIN WITH (FORMAT CSV, HEADER TRUE)", stream=buf)
        print(f"{table_name} : {len(df)} lignes chargées")
    con.run("COMMIT")
finally:
    con.close()