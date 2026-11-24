CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    annee SMALLINT NOT NULL,
    trimestre SMALLINT NOT NULL,
    mois SMALLINT NOT NULL,
    jour SMALLINT NOT NULL
);

CREATE TABLE dim_chain (
    chain VARCHAR(100) PRIMARY KEY,
    token_symbol VARCHAR(50),
    chain_id VARCHAR(50)
);

CREATE TABLE dim_protocol (
    slug VARCHAR(150) PRIMARY KEY,
    protocol_id VARCHAR(100),
    name VARCHAR(200),
    symbol TEXT,
    category VARCHAR(100),
    primary_chain VARCHAR(100),
    n_chains INTEGER,
    parent_protocol VARCHAR(150),
    listed_at TIMESTAMP
);

CREATE TABLE dim_yields (
    pool_id VARCHAR(150) PRIMARY KEY,
    symbol TEXT,
    pool_meta TEXT,
    stablecoin BOOLEAN,
    il_risk VARCHAR(20),
    exposure VARCHAR(50)
);

CREATE TABLE fact_chain_tvl (
    date_id DATE NOT NULL REFERENCES dim_date(date_id),
    chain VARCHAR(100) NOT NULL REFERENCES dim_chain(chain),
    tvl_usd NUMERIC CHECK (tvl_usd >= 0),
    PRIMARY KEY (date_id, chain)
);

CREATE TABLE fact_protocol_snapshots (
    date_id DATE NOT NULL REFERENCES dim_date(date_id),
    slug VARCHAR(150) NOT NULL REFERENCES dim_protocol(slug),
    tvl_usd NUMERIC CHECK (tvl_usd >= 0),
    change_1h_pct NUMERIC,
    change_1d_pct NUMERIC,
    change_7d_pct NUMERIC,
    mcap_usd NUMERIC CHECK (mcap_usd >= 0),
    PRIMARY KEY (date_id, slug)
);

CREATE TABLE fact_yield_pools (
    date_id DATE NOT NULL REFERENCES dim_date(date_id),
    pool_id VARCHAR(150) NOT NULL REFERENCES dim_yields(pool_id),
    chain VARCHAR(100) NOT NULL REFERENCES dim_chain(chain),
    protocol_slug VARCHAR(150) NOT NULL REFERENCES dim_protocol(slug),
    tvl_usd NUMERIC CHECK (tvl_usd >= 0),
    apy NUMERIC,
    apy_base NUMERIC,
    apy_reward NUMERIC,
    apy_mean_30d NUMERIC,
    volume_usd_1d NUMERIC CHECK (volume_usd_1d >= 0),
    PRIMARY KEY (date_id, pool_id)
);