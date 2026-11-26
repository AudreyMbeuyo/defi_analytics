CREATE INDEX idx_fyp_chain_tvl
ON fact_yield_pools (chain, tvl_usd);

CREATE INDEX idx_fyp_protocol_date_cov
ON fact_yield_pools (protocol_slug, date_id)
INCLUDE (pool_id, tvl_usd, apy);

CREATE INDEX idx_fyp_whale_pools
ON fact_yield_pools (tvl_usd)
WHERE tvl_usd >= 500000000 AND apy IS NOT NULL;

ANALYZE fact_yield_pools;