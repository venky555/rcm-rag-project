// FILE: docs/diagrams/04-c4-components-rcm-rag.md
---
# C4 Level 3: Component Diagram - rcm-rag

## Overview
This Component diagram details the internal architecture of the `rcm-rag` service, a FastAPI-based Python application. It showcases the integration of advanced AI frameworks (LlamaIndex, LangChain, LangGraph) into a robust ingestion, retrieval, and intelligent agent pipeline to automate complex RCM workflows like claim scrubbing and denial resolution.

## Diagram
```text
                  HTTP/REST                       gRPC (scrubbing)                  Kafka (denial.received)
       ------------------------------>   ------------------------------->   --------------------------------->
                      |                                  |                                  |
                      v                                  v                                  v
+-------------------------------------------------------------------------------------------------------------------------+
|                                           rcm-rag [FastAPI, Python 3.12]                                                |
|                                                                                                                         |
|  +--------------------------------------------+  +-------------------------------------------------------------------+  |
|  | api                                        |  | flows                                                             |  |
|  | - FastAPI routers (health, ingestion,      |  | - ClaimScrubbingFlow (gRPC servicer)                              |  |
|  |   retrieval, denial, eval)                 |  | - DenialExplanationFlow (Kafka consumer / producer)               |  |
|  +--------------------------------------------+  +-------------------------------------------------------------------+  |
|      | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - >      |
|      v                                                                                                           v      |
|  +--------------------------------------------+  +-------------------------------------------------------------------+  |
|  | ingestion (LlamaIndex)                     |  | agent (LangGraph)                                                 |  |
|  | - IngestionPipeline                        |  | - AgentState, DenialResolutionGraph, AgentStatePersistence        |  |
|  | - DocumentLoader, SemanticChunker          |  | - Nodes: triage, lookup_carc, fetch_payer_policy,                 |  |
|  | - Embedder (provider-abstracted)           |  |   check_medical_necessity, draft_appeal, finalize, human_review   |  |
|  | - PgVectorStore, FaissCache                |  | - Tools: CarcLookup, PayerPolicy, MedNecessity, AppealDraft       |  |
|  +--------------------------------------------+  +-------------------------------------------------------------------+  |
|      |                                               |                               |                           |      |
|      |                                               | - - - - - - - - - - - - - - > | - - - - - - - - - - - - > |      |
|      v                                               v                               v                           v      |
|  +--------------------------------------------+  +-----------------------+  +----------------------+  +--------------+  |
|  | common & evals                             |  | retrieval (LangChain) |  | llm                  |  | prompts      |  |
|  | - JWTAuth, PhiRedactor, TenantContext      |  | - HybridRetriever     |  | - LLMClient          |  | - PromptReg- |  |
|  | - EvalRunner, retrieval_metrics            |  | - SemanticCache       |  | - AzureOpenAIClient  |  |   istry      |  |
|  | - domain_metrics, operational_metrics      |  | - CrossEncoderReranker|  | - OllamaClient       |  | - YAML files |  |
|  +--------------------------------------------+  +-----------------------+  | - TokenCounter       |  +--------------+  |
|      |                                               |                      | - Middleware         |                    |
|      | - - - - - - - - - - - - - - - - - - - - - - - | - - - - - - - - - -> +----------------------+                    |
|      v                                               v                                                                  |
|  +-------------------------------------------------------------------------------------------------------------------+  |
|  | db layer                                                                                                          |  |
|  | - AsyncPG / SQLAlchemy, redis-py async, Motor, azure-cosmos                                                       |  |
|  +-------------------------------------------------------------------------------------------------------------------+  |
|          |                            |                            |                            |            |          |
+----------+----------------------------+----------------------------+----------------------------+------------+----------+
           |                            |                            |                            |            |
  asyncpg  |             Motor / Python |            redis-py        |         LangChain / REST |      Kafka |
  (vector) |               SDK (async)  |             (async)        |            (async)       |  (produce) |
           v                            v                            v                            v            v
  +-----------------+          +-----------------+          +-----------------+          +---------------+ +--------+
  | PostgreSQL 16   |          | MongoDB 7 /     |          | Redis 7         |          | Azure OpenAI/ | | Kafka  |
  | [+ pgvector]    |          | CosmosDB        |          | [L2 / Semantic] |          | Ollama        | | Broker |
  +-----------------+          +-----------------+          +-----------------+          +---------------+ +--------+
```

## Key Points
- **LangGraph Agent:** The complex denial resolution logic is modeled as a stateful graph (LangGraph). It loops through specific nodes (e.g., retrieving policies, analyzing medical necessity) before optionally pausing for human review (`INTERRUPT`).
- **Hybrid Retrieval:** The `retrieval` module uses a dual-strategy approach: vector similarity search (pgvector) combined with structured metadata filtering, followed by a CrossEncoder for reranking to maximize context relevance.
- **LLM Abstraction:** The `llm` module completely abstracts the underlying provider (Azure OpenAI vs. Ollama) and handles cross-cutting concerns like rate-limiting, budget tracking, and strict token counting via middleware.
- **Evaluation Framework:** Built-in `evals` ensure the continuous quality of the RAG pipeline by measuring domain metrics, faithfulness, and hallucination rates before updates are promoted.
- **Asynchronous Data Access:** The `db layer` utilizes pure async drivers (`asyncpg`, `Motor`) to maintain extremely high concurrency without thread blocking, which is critical in an IO-heavy AI service.

## Interview Talking Points
- Highlight the choice of **Presidio** inside the `common` module. By enforcing PHI redaction as a foundational dependency *before* any text hits the embedder or LLM, the architecture ensures strict HIPAA compliance at the architectural level.
- Discuss the separation of **Prompts** as YAML files governed by a semver registry. This treats prompts as code, enabling A/B testing and version control independent of the Python execution logic.
- Explain the `human_review` node in LangGraph. This illustrates a "Human-in-the-Loop" (HITL) pattern where the agent can pause its execution, persist its state to PostgreSQL, and resume exactly where it left off once a Biller approves an action.
// ===== END OF FILE =====
