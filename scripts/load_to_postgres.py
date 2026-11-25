from getpass import getpass
from io import StringIO
from pathlib import Path
import pandas as pd
import pg8000.native

data_dir = Path(__file__).resolve().parent.parent / "data"
port_input = input("Port PostgreSQL (Entrée pour 5432) : ").strip()
port = int(port_input) if port_input else 5432
password = getpass("Mot de passe PostgreSQL (utilisateur postgres) : ")

df_chains = pd.read_parquet(data_dir / "chains_snapshots.parquet")
df_protocols = pd.read_parquet(data_dir / "protocols_snapshots.parquet")
df_yields = pd.read_parquet(data_dir / "yield_pools_snapshots.parquet")

df_protocols = df_protocols[df_protocols["category"] != "CEX"].copy()
dim_protocol = (
    df_protocols.sort_values("snapshot_date")
    .drop_duplicates(subset=["slug"], keep="last")
    [["slug", "protocol_id", "name", "symbol", "category", "primary_chain", "n_chains", "parent_protocol", "listed_at"]]
    .copy()
)
dim_protocol["n_chains"] = dim_protocol["n_chains"].astype("Int64")

valid_slugs = set(dim_protocol["slug"])
avant = len(df_yields)
df_yields = df_yields[df_yields["project"].isin(valid_slugs)].copy()
print(f"Pools conservés (pure DeFi reliée) : {len(df_yields)} / {avant}")

df_yields["date_id"] = pd.to_datetime(df_yields["snapshot_date"]).dt.date

unique_dates = df_yields["date_id"].dropna().drop_duplicates()
dt = pd.to_datetime(unique_dates)
dim_date = pd.DataFrame({
    "date_id": unique_dates.values,
    "annee": dt.dt.year.values,
    "trimestre": dt.dt.quarter.values,
    "mois": dt.dt.month.values,
    "jour": dt.dt.day.values,
})

chains_meta = (
    df_chains.sort_values("snapshot_date")
    .drop_duplicates(subset=["chain"], keep="last")[["chain", "token_symbol", "chain_id"]]
)
dim_chain = (
    pd.DataFrame({"chain": df_yields["chain"].dropna().drop_duplicates()})
    .merge(chains_meta, on="chain", how="left")
)

dim_pool = (
    df_yields.sort_values("date_id")
    .drop_duplicates(subset=["pool_id"], keep="last")
    [["pool_id", "symbol", "pool_meta", "stablecoin", "il_risk", "exposure"]]
)

fact_yield_pools = (
    df_yields.rename(columns={"project": "protocol_slug"})
    [["date_id", "pool_id", "chain", "protocol_slug", "tvl_usd", "apy", "apy_base", "apy_reward", "apy_mean_30d", "volume_usd_1d"]]
    .drop_duplicates(subset=["date_id", "pool_id"], keep="last")
    .copy()
)
for col in ["tvl_usd", "volume_usd_1d"]:
    fact_yield_pools.loc[fact_yield_pools[col] < 0, col] = None

tables = [
    ("dim_date", dim_date),
    ("dim_chain", dim_chain),
    ("dim_protocol", dim_protocol),
    ("dim_pool", dim_pool),
    ("fact_yield_pools", fact_yield_pools),
]

con = pg8000.native.Connection(
    user="postgres",
    password=password,
    host="localhost",
    #changer le port si different
    port=5433,
    database="defi_analytics",
)

try:
    con.run("START TRANSACTION")
    con.run("TRUNCATE fact_yield_pools, dim_pool, dim_protocol, dim_chain, dim_date;")
    for name, df in tables:
        buf = StringIO()
        df.to_csv(buf, index=False)
        buf.seek(0)
        cols = ", ".join(df.columns)
        con.run(f"COPY {name} ({cols}) FROM STDIN WITH (FORMAT CSV, HEADER TRUE)", stream=buf)
        print(f"{name} : {len(df)} lignes importées")
    con.run("COMMIT")
finally:
    con.close()