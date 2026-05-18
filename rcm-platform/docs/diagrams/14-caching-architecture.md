// FILE: docs/diagrams/14-caching-architecture.md
---
# AI Architecture: 5-Tier Caching Strategy

## Overview
This diagram depicts the aggressive 5-tier caching architecture employed across the RCM platform. By implementing caches at the in-process, distributed, database, and semantic levels, the system minimizes expensive LLM API calls, reduces vector embedding latency, and guarantees sub-millisecond response times for static reference data.

## Diagram
```text
+-----------------------------------------------------------------------------------------+
| L1 Cache: In-Process LRU (Caffeine / cachetools)                                        |
| Latency: ~0.1 ms | Location: rcm-core & rcm-rag memory | TTL: Service Lifetime          |
| Use Cases:                                                                              |
| - CPT/ICD10 ref data (~50K records)       - Prompt templates (all versions, <1MB)       |
| - CARC/RARC definitions (~300 codes)      - Feature flags (Redis pub/sub invalidation)  |
| - Payer metadata (~500 payers)                                                          |
+-----------------------------------------------------------------------------------------+
                                         | (Miss)
                                         v
+-----------------------------------------------------------------------------------------+
| L2 Cache: Distributed Cache (Redis 7)                                                   |
| Latency: ~1-3 ms | Location: AWS ElastiCache | TTL: 2min to 7d                          |
| Use Cases:                                                                              |
| - Eligibility responses (key: {tenantId}:{patientId}:{payerId}, TTL: 24h)               |
| - LLM exact-match cache (key: hash(promptV+chunkIds+queryHash), TTL: 7d)                |
| - Rate limit counters (key: {tenantId}:{endpoint}:{minuteBucket}, TTL: 2min)            |
+-----------------------------------------------------------------------------------------+
                                         | (Miss)
                                         v
+-----------------------------------------------------------------------------------------+
| L3 Cache: Database Materialized Views (PostgreSQL 16)                                   |
| Latency: ~10-50 ms | Location: RDS | Refresh: Nightly via pg_cron                       |
| Use Cases:                                                                              |
| - ar_aging_buckets (AR aging report)      - denial_rate_by_payer (Analytics)            |
| - claim_throughput_by_day (Ops Metrics)   - eligibility_cache_hit_rate                  |
+-----------------------------------------------------------------------------------------+
                                         |
=========================================+=================================================
 AI-SPECIFIC CACHE LAYERS                |
=========================================+=================================================
                                         |
                                         v
+-----------------------------------------------------------------------------------------+
| L4 Cache: Embedding Cache (In-Process -> PostgreSQL)                                    |
| Latency: ~1 ms | Location: rcm-rag memory / Postgres | Key: hash(text + model_version)  |
| Use Cases:                                                                              |
| - Prevents expensive API calls to re-embed identical text chunks on re-ingestion.       |
| - Loaded to memory as dictionary; persisted to PostgreSQL gracefully on shutdown.       |
+-----------------------------------------------------------------------------------------+
                                         | (Miss)
                                         v
+-----------------------------------------------------------------------------------------+
| L5 Cache: Semantic Cache (pgvector)                                                     |
| Latency: ~10-20 ms | Location: PostgreSQL (cached_responses table)                      |
| Use Cases:                                                                              |
| - Embeds incoming query -> executes cosine similarity search against previous queries.  |
| - Hit threshold: > 0.97 cosine similarity (extremely high confidence).                  |
| - On Hit: Returns cached LLM response (saves seconds of latency & token costs).         |
| - On Miss: Calls LLM -> stores new embedding + response in cache table.                 |
+-----------------------------------------------------------------------------------------+
```

## Key Points
- **L1/L2 Classic Caching:** Standard dictionary data (CARC codes) stays directly in memory (L1), while heavier, shared, TTL-based data (Eligibility) uses distributed Redis (L2).
- **L3 Pre-computation:** Rather than running expensive COUNT and GROUP BY queries on millions of claims during the day, nightly `pg_cron` jobs calculate L3 materialized views to ensure dashboards load instantly.
- **L4 Embedding Cache:** A critical cost-saving measure that ensures if a 1,000-page medical manual is re-ingested with only one paragraph changed, only the changed chunk is sent to the embedding model.
- **L5 Semantic Cache:** The most advanced layer. It understands *intent*. If a user asks "Why did Aetna deny code 99213?" and another asks "Reason for Aetna 99213 rejection?", they will map to the same vector (>0.97 similarity) and return instantly without hitting Azure OpenAI.

## Interview Talking Points
- When discussing L1, emphasize the **Pub/Sub Invalidation** mechanism. Since L1 is isolated in each container's memory, changing a Feature Flag triggers a Redis Pub/Sub event to instantly invalidate the L1 cache across all `rcm-core` containers simultaneously.
- Highlight the financial and performance impact of the **Semantic Cache (L5)**. LLM generation can take 5-10 seconds and cost cents per query; a semantic cache hit reduces this to 15 milliseconds and 0 cents, drastically altering the unit economics of the AI feature.
// ===== END OF FILE =====
