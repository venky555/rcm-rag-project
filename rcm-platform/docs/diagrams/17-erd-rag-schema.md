// FILE: docs/diagrams/17-erd-rag-schema.md
---
# Data Model: RAG Schema ERD

## Overview
This diagram maps out the `rag` schema in PostgreSQL, designed to support the LangChain/LlamaIndex pipelines. It leverages the `pgvector` extension to store and quickly query high-dimensional embeddings alongside operational AI state data like caching and evaluations.

## Diagram
```text
+-----------------------+             +-----------------------+
| rag_documents         |             | rag_chunks            |
|-----------------------|             |-----------------------|
| id UUID [PK]          |<-+          | id UUID [PK]          |<-+
| tenant_id UUID [FK]   |  |          | tenant_id UUID [FK]   |  |
| source_type VARCHAR   |  +----------| document_id UUID [FK] |  |
| source_name VARCHAR   |             | chunk_index INTEGER   |  +--+
| payer_id UUID         |             | content TEXT          |     |
| effective_date DATE   |             | token_count INTEGER   |     |
| expiry_date DATE      |             | metadata JSONB        |     |
| content TEXT          |             | created_at TIMESTAMPTZ|     |
| metadata JSONB        |             +-----------------------+     |
| ingested_at TIMESTAMP |                                           |
| embedding_model VCHAR |             +-----------------------+     |
+-----------------------+             | rag_embeddings        |     |
                                      |-----------------------|     |
+-----------------------+             | id UUID [PK]          |     |
| eval_results          |             | tenant_id UUID [FK]   |     |
|-----------------------|             | chunk_id UUID [FK]    |-----+
| id UUID [PK]          |             | embedding vector(1536)| ** pgvector type
| prompt_id VARCHAR(100)|             | model_version VARCHAR |
| prompt_version VARCHAR|             | created_at TIMESTAMPTZ|
| eval_set VARCHAR(100) |             +-----------------------+
| run_at TIMESTAMPTZ    |             [INDEX: HNSW using cosine_ops]
| faithfulness DECIMAL  |
| answer_relevance DEC  |             +-----------------------+
| recall_at_1 DECIMAL   |             | cached_llm_responses  |
| recall_at_3 DECIMAL   |             |-----------------------|
| recall_at_5 DECIMAL   |             | id UUID [PK]          |
| precision_at_5 DECIMAL|             | tenant_id UUID [FK]   |
| mrr DECIMAL           |             | query_hash VARCHAR(64)|
| ndcg_at_5 DECIMAL     |             | prompt_version_id VCHR|
| bleu4 DECIMAL         |             | chunk_ids UUID[]      |
| rouge_l DECIMAL       |             | query_emb vector(1536)| ** pgvector type
| cosine_similarity DEC |             | response_text TEXT    |
| carc_accuracy DECIMAL |             | response_metadata JSON|
| metadata JSONB        |             | hit_count INTEGER     |
+-----------------------+             | created_at TIMESTAMPTZ|
                                      | last_hit_at TIMESTAMPT|
+-----------------------+             +-----------------------+
| agent_states          |
|-----------------------|
| id UUID [PK]          |
| tenant_id UUID [FK]   |
| denial_id UUID [FK]   |
| run_id UUID           |
| current_node VARCHAR  |
| state JSONB           |
| interrupted_at TIMEST |
| resumed_at TIMESTAMPTZ|
| completed_at TIMESTAMP|
| created_at TIMESTAMPTZ|
| updated_at TIMESTAMPTZ|
+-----------------------+
```

## Schema Design Decisions
1. **Native Vector Storage:** Uses `vector(1536)` from the `pgvector` extension natively alongside relational data. This allows for hybrid search (e.g., similarity search `ORDER BY embedding <-> query` combined with relational filtering `WHERE payer_id = X`).
2. **HNSW Indexing:** Employs Hierarchical Navigable Small World (HNSW) indexing using `cosine_ops`. HNSW builds faster and scales better to millions of rows compared to IVFFlat, ensuring sub-50ms vector lookups.
3. **Decoupled Chunks and Embeddings:** By separating `rag_chunks` from `rag_embeddings`, the system can easily support multiple embedding models (e.g., migrating from `text-embedding-ada-002` to `text-embedding-3-small`) on the same source text without data duplication.
4. **State Checkpointing:** The `agent_states` table stores the LangGraph state machine object as a native `JSONB` document. This enables the critical "Human-in-the-loop" interrupt feature by persisting AI state across service restarts.

## Interview Talking Points
- Highlight the **Hybrid Search capability**. Because vectors and metadata live in the same PostgreSQL instance, we avoid the dreaded "split-brain" problem of keeping a standalone vector DB (like Pinecone) synchronized with the primary relational DB.
- Discuss the `cached_llm_responses` table. It caches LLM generations based on a semantic hash. By storing the `query_embedding` here as well, we can perform semantic caching (returning a cached response if a new query is semantically similar but not lexically identical).
// ===== END OF FILE =====
