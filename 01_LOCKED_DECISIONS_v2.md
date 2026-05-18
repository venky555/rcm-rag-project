# RCM Platform — Locked Architecture Decisions v2
# STATUS: AWAITING FINAL SIGN-OFF
#
# Every DeepSeek prompt references decisions by ID.
# Do not change a decision after prompts referencing it have been run.
# To change a decision: mark it SUPERSEDED, create a new decision with next ID.

---

# SECTION A — ARCHITECTURE DECISIONS

---

## ARCH-01 — Polyglot service topology

**Decision.**
Five backend services total:
- `rcm-core`         — Spring Boot (Java 21)       — RCM transactional backbone
- `rcm-rag`          — FastAPI (Python 3.12)        — RAG, embeddings, LLM, agent
- `rcm-notify`       — Express.js (Node.js 20 LTS)  — Notifications (email/SMS/webhook)
- `rcm-bff`          — Express.js + Apollo (Node 20) — BFF / GraphQL gateway for UI
- `rcm-ui`           — Next.js 14 (React/TypeScript) — Biller workbench UI

**Rationale.**
Each service exists because of a genuine polyglot justification:
- Java for the transactional core: mature HIPAA-tested ecosystem, type safety, Spring's enterprise libraries
- Python for AI: the entire model tooling ecosystem lives here; forcing AI into Java means fighting the ecosystem
- Node.js for notification: event-driven, I/O-bound, non-blocking — textbook Node.js workload
- Node.js for BFF: aggregates multiple backend APIs into one GraphQL schema for the UI; Apollo Server is the industry standard
- Next.js for UI: React Server Components, SSE streaming support, TypeScript, App Router

**Interview talking point.**
"Each language earns its place by being the right tool for its workload. Java's concurrency model and Spring ecosystem win for transactional RCM. Python wins for AI because LangChain, LlamaIndex, and RAGAS don't exist in Java. Node.js wins for the notification service because it's pure I/O — waiting for SMTP, waiting for SMS gateway, waiting for webhook acks. Node.js for BFF because Apollo Server's DataLoader pattern is the best-in-class solution for the N+1 problem in a GraphQL aggregation layer. If I used Java everywhere I'd be fighting the wrong battles."

---

## ARCH-02 — Modular monolith for rcm-core, not microservices within it

**Decision.**
`rcm-core` is one deployable JAR, internally structured as bounded contexts (Gradle subprojects):
`registration`, `eligibility`, `charge-capture`, `claims`, `payments`, `denials`, `ar`, `common`.
Bounded contexts communicate via in-process Spring application events today.
Module boundaries are clean enough to extract any context later.

**Rationale.**
Seven microservices for seven RCM stages would be six services too many for one team.
A modular monolith proves DDD understanding without the operational tax.

**Interview talking point.**
"Module boundaries are a design decision. Deployment boundaries are an operational decision.
They don't have to match. I get bounded context isolation with one deployable.
I'd split a context out when a team-scaling or independent-deploy forcing function appears — not before."

---

## ARCH-03 — Communication protocols: REST + GraphQL + gRPC, each with a real home

**Decision.**

| Protocol | Where | Why |
|---|---|---|
| REST/JSON | rcm-core ↔ external callers (clearinghouse, EHR); rcm-core ↔ rcm-notify; rcm-core ↔ rcm-bff | Standard HTTP, external-facing, CRUD-heavy resources |
| GraphQL | rcm-bff ↔ rcm-ui | UI needs flexible aggregation across multiple backends in one query |
| gRPC (protobuf) | rcm-core → rcm-rag (claim scrubbing, sync path) | Internal, high-frequency, latency-sensitive, strict contract |
| Kafka (async messaging) | rcm-core → rcm-rag (denial flow); rcm-core → rcm-notify | Genuinely async business events with hours-to-days latency in reality |

**REST talking point.**
"REST for external-facing APIs and CRUD-heavy resources. HTTP/JSON is the lingua franca — any client, any language, any tool speaks it. Resource semantics map naturally to RCM entities. When I'm designing a public or semi-public API surface, REST's discoverability and tooling ecosystem win."

**GraphQL talking point.**
"GraphQL at the BFF layer because the UI needs to aggregate data from multiple services in one round trip. The biller's denial review screen needs claim data, denial data, patient data, and the AI-drafted appeal — one GraphQL query versus four REST calls, with the exact fields the UI needs and no more. The BFF owns the schema; the backends own their domains. Apollo's DataLoader handles N+1 batching automatically."

**gRPC talking point.**
"gRPC for the claim scrubbing path because it's internal, high-frequency, and latency-sensitive. Protobuf contracts are stricter than OpenAPI — I get compile-time type safety across the Java/Python boundary. gRPC streaming lets me stream the LLM's token output back to Java if we need real-time scrubbing feedback. HTTP/2 multiplexing means no head-of-line blocking on concurrent scrubbing requests."

**Kafka talking point.**
"Kafka for genuinely async business events — the 837 submission to 835 response cycle is hours to days in real RCM. Modeling that as synchronous HTTP is wrong. Kafka also gives me the event log as a HIPAA audit artifact and replay capability for the analytics pipeline."

---

## ARCH-04 — Kafka for async flows only, REST/gRPC for sync

**Decision.**
Kafka topics in v1: `claim.submitted`, `denial.received`, `denial.explained`, `notification.requested`.
All other inter-service calls are synchronous (REST or gRPC).

**Rationale.**
Async-by-default is over-engineering. The four topics above represent genuinely async business boundaries.
`notification.requested` lets rcm-core fire-and-forget to rcm-notify without coupling to notification delivery semantics.

**Interview talking point.**
"Async messaging is for events where the producer doesn't care when the consumer processes them and shouldn't block waiting. Claim submission, denial ingestion, notification dispatch all qualify. Eligibility check doesn't — the provider is waiting at the desk."

---

## ARCH-05 — No API gateway in v1, designed for v2

**Decision.**
No gateway in front of services in v1. Direct routing from rcm-ui to rcm-bff to backends.
`docs/adr/ARCH-05-api-gateway.md` documents where Kong or AWS API Gateway would slot in, what it would own (centralized auth, WAF, rate limiting, request routing), and the trigger conditions for adding it.

**Interview talking point.**
"I don't add a gateway until I have a centralized concern that can't sit in each service — WAF, cross-service rate limiting, a public API surface. At five internal services with a BFF already handling aggregation, the gateway is overhead. The design anticipates it; the implementation defers it."

---

## ARCH-06 — Multi-tenancy: shared schema, tenant discriminator, enforced at ORM layer

**Decision.**
Every table has a `tenant_id UUID NOT NULL` column.
Every Postgres query filtered via Hibernate `@Filter` (Java) and SQLAlchemy `before_compile` event (Python).
Every CosmosDB document has `tenantId` as the partition key.
Every MongoDB document has `tenantId` indexed.
Every Kafka message carries `tenantId` in the header.
Every gRPC call carries `tenantId` in metadata.
Current deployment: one tenant. Code: ready for N.

**Interview talking point.**
"Multi-tenancy retrofitted is a rewrite. Designed in from day one it costs almost nothing — one column, one ORM filter, one test that verifies tenant isolation. I chose shared-schema-with-discriminator because it's the most flexible model: I can later promote a hot tenant to a dedicated schema or database without changing application code, only routing."

---

## ARCH-07 — Resilience4j (Java) + Tenacity (Python) for all outbound calls

**Decision.**
Every outbound call from rcm-core to rcm-rag (gRPC) goes through Resilience4j.
Every outbound LLM call from rcm-rag goes through Tenacity retry + a custom circuit breaker.
Defaults:
- Claim scrubbing (gRPC): 3s timeout, 2 retries with 100ms backoff, 50% failure threshold for circuit breaker
- LLM calls: 30s timeout, 1 retry, exponential backoff with jitter, circuit opens at 3 consecutive failures
- Eligibility (REST): 5s timeout, 3 retries

**Interview talking point.**
"LLM latency is the new database latency — unpredictable, occasionally catastrophic. Every outbound call has a timeout, retry policy, and circuit breaker. The LLM circuit breaker is particularly important: if Azure OpenAI degrades, I don't want rcm-rag to queue up thousands of retries. The circuit breaker gives the provider room to recover and gives my service a clean failure mode to surface to the caller."

---

## ARCH-08 — Human-in-the-loop mandatory for all LLM output leaving the system

**Decision.**
No LLM-generated content reaches an external party (payer, patient, clearinghouse) without explicit human approval.
The denial appeal letter is drafted by the LangGraph agent, presented in the UI for biller review and edit, and only submitted after the biller clicks approve.
The LangGraph agent has a hard interrupt node at `human_review`.
The interrupt state is persisted in Postgres so the biller can close the browser and return later.

**Interview talking point.**
"I treat LLM output as a draft, not a final. Human-in-the-loop isn't a UX nicety — it's the control that lets me ship an agentic system in a regulated domain. A hallucinated appeal argument sent to a payer could result in a denied appeal, delayed payment, and potential compliance scrutiny. The interrupt node costs one database write; the risk it eliminates is material."

---

# SECTION B — DATA DECISIONS

---

## DATA-01 — Four data stores, each with a specific job

**Decision.**

| Store | Version | Job | Why this store |
|---|---|---|---|
| PostgreSQL + pgvector | Postgres 16, pgvector 0.7 | RCM transactional data + vector embeddings | ACID, SQL joins between claims and chunks, one backup story |
| MongoDB | 7.0 | PHI access audit log | Append-only, flexible per-event schema, 7yr retention |
| CosmosDB (NoSQL API) | Current Azure | Claim processing event stream | High-write, Change Feed, global distribution, natural partition key (claim_id) |
| Redis | 7.2 | L2 distributed cache + rate limit counters | Shared state across instances, TTL-based expiry |

**Interview talking point.**
"Four stores, four justified use cases. Postgres for transactional integrity and vector search — it's the right answer when you need SQL joins between your chunks and your claim metadata. Mongo for the audit log because audit events are append-only, schema-flexible across event types, and queried by filter — textbook document store. CosmosDB for the claim event stream because I need Change Feed to drive the analytics pipeline and global write throughput if we scale nationally. Redis for shared cache and rate limits because those need cross-instance shared state with TTL. If any store disappears, the system loses one specific capability, not all capabilities."

---

## DATA-02 — pgvector for RAG retrieval (primary vector store)

**Decision.**
All embeddings stored in Postgres via pgvector extension.
HNSW indexes on embedding columns (better query performance than IVFFlat for this corpus size).
Hybrid search: structured WHERE clauses (tenant_id, payer_id, effective_date, code_family) + vector cosine similarity in a single SQL query.
pgvector is the source of truth for all vector data.

**Interview talking point.**
"pgvector wins for RCM retrieval because the workload is filtered vector search, not pure vector search. 'Find the top-5 most relevant payer policy chunks for this claim' means WHERE payer_id = ? AND effective_date <= ? followed by vector similarity. In Postgres that's one query. In a dedicated vector DB it's a metadata filter followed by a vector search — two hops, two consistency domains. pgvector also means no additional HIPAA blast radius beyond Postgres."

---

## DATA-03 — CosmosDB NoSQL API for claim processing event stream

**Decision.**
Every micro-event in the claim lifecycle is written to CosmosDB:
`eligibility_checked`, `scrub_passed`, `scrub_failed`, `submitted_to_clearinghouse`,
`acknowledgement_received`, `adjudicated`, `payment_posted`, `denial_received`,
`appeal_drafted`, `appeal_submitted`, `resolved`.
Partition key: `claimId`. TTL: 2 years on raw events, permanent on summary documents.
Change Feed consumed by a dedicated processor that writes to the analytics pipeline.

**Interview talking point.**
"CosmosDB for the event stream because each claim generates dozens of micro-events over days or weeks, the access pattern is always by claim ID (natural partition key), and I need Change Feed to drive the downstream analytics pipeline without polling. Postgres could do it, but I'd be fighting for write throughput on the hot transactional table. CosmosDB gives me elastic write throughput and Change Feed natively."

---

## DATA-04 — FAISS as in-memory retrieval hot cache (designed, minimal build)

**Decision.**
The FastAPI RAG service maintains a FAISS HNSW index in memory, rebuilt from pgvector at startup.
Used as L1 retrieval cache for the claim scrubbing path (highest QPS).
pgvector remains source of truth; FAISS is never written to directly.
Minimal build in v1 (single-threaded, no sharding); full implementation documented in ADR as v2.

**Interview talking point.**
"FAISS is a library, not a database. It shows up in production as an in-process hot cache built on top of a system of record. pgvector is my system of record; FAISS is the cache I rebuild at startup for the hot path. This is the actual architecture at companies doing high-QPS vector retrieval — they're not hitting Postgres on every embedding query in the hot loop."

---

## DATA-05 — MongoDB 7 for PHI access audit log

**Decision.**
Every read or write to any PHI-containing entity generates an audit event written to MongoDB.
Collection: `audit_events`.
Indexed fields: `tenantId`, `eventType`, `timestamp`, `actorId`, `entityId`.
Retention: 7 years (HIPAA minimum).
Append-only: no updates, no deletes (enforced via MongoDB role with insert-only permissions on this collection).

**Interview talking point.**
"Audit log in Mongo because it's append-only writes with flexible per-event-type schemas and filter-based reads — the workload document stores are built for. The insert-only role at the database level means even a compromised application credential can't tamper with audit history. 7-year retention is a hard HIPAA requirement."

---

## DATA-06 — Redis 7 for L2 cache and rate limit counters

**Decision.**
Redis holds exactly three things:
- Eligibility verification responses: key `{tenantId}:{patientId}:{payerId}`, TTL 24h
- LLM response cache: key `hash(promptVersionId + chunkIds + queryHash)`, TTL 7 days
- Rate limit counters: key `{tenantId}:{endpoint}:{minuteBucket}`, TTL 2 minutes

**Interview talking point.**
"Redis for things that cost money or need shared state across service instances. Eligibility and LLM responses cost money. Rate limit counters need shared state. Everything else stays in-process. I deliberately scope Redis usage because every item in Redis is an operational concern — TTLs, eviction policies, memory sizing, serialization. Fewer items, fewer surprises."

---

## DATA-07 — Caffeine (Java) + cachetools (Python) for L1 in-process cache

**Decision.**
L1 caches for hot reference data: CPT/ICD-10 lookups, payer metadata, CARC/RARC definitions, prompt templates.
Caffeine on Java side (LRU, max 10MB, loaded at startup).
`cachetools.TTLCache` on Python side (same data, same sizing).
Data rarely changes; cache is invalidated on service restart and via a Redis pub/sub signal if reference data is updated.

**Interview talking point.**
"Three-tier cache: L1 in-process microseconds for read-mostly reference data, L2 Redis milliseconds for shared TTL'd state, L3 Postgres materialized views for nightly-refreshed analytical reads. Each tier serves a different latency/consistency trade-off. The cache hierarchy is as important as any individual cache."

---

## DATA-08 — Postgres materialized views for analytical L3 reads

**Decision.**
Materialized views (refreshed nightly via pg_cron): AR aging buckets, denial rate by payer,
claim throughput by day, eligibility cache hit rate, top denial reason codes by month.
Read-only by the reporting endpoints in rcm-bff (GraphQL resolvers).

---

## DATA-09 — Flyway for Postgres migrations, ordered SQL files

**Decision.**
Migrations: `V001__create_extensions.sql` through `V0NN__...`.
Immutable once merged. Run on service startup by rcm-core.
Separate Flyway baseline for the RAG schema (`R__` repeatable for pgvector index rebuilds).

---

## DATA-10 — Embedding model: Azure OpenAI in prod, self-hosted in dev

**Decision.**
Config-driven embedding provider.
Prod: Azure OpenAI `text-embedding-3-small` (1536 dimensions) under a HIPAA BAA.
Dev: `BAAI/bge-small-en-v1.5` via sentence-transformers (384 dimensions), no GPU needed.
Dimension mismatch handled: separate pgvector column configurations per environment via Flyway profile.
The prompt registry records which embedding model produced each vector — never mix dimensionalities.

**Interview talking point.**
"Dev runs offline because I refuse to require cloud credentials for local development. Prod runs under Azure OpenAI BAA because HIPAA. The embedding model version is stored with each vector because you can't use a 1536-dim index to retrieve 384-dim vectors — mixing dimensionalities silently returns garbage. The registry enforces this invariant."

---

## DATA-11 — LLM provider: Azure OpenAI primary, config-driven swap

**Decision.**
Prod: Azure OpenAI `gpt-4o` for agent, `gpt-4o-mini` for cheap classifications.
Dev: self-hosted Llama-3-8B-Instruct via Ollama, or recorded-response mock for tests.
Provider is an interface; concrete implementation is config-selected.
DeepSeek is used to generate the code; Azure OpenAI / Ollama runs the generated system.

---

# SECTION C — AI DECISIONS

---

## AI-01 — LlamaIndex for ingestion pipeline, LangChain + LangGraph for orchestration

**Decision.**
LlamaIndex owns: document loading, parsing, chunking (semantic chunking), embedding pipeline,
pgvector upsert. (Ingest path.)
LangChain + LangGraph own: prompt assembly, tool calling, agent state machine, human-in-the-loop interrupt. (Runtime path.)
Both share the pgvector store via a common connection pool.

**Interview talking point.**
"LlamaIndex is an ingestion-and-indexing framework; LangChain is an orchestration framework. They solve different problems. LlamaIndex has richer document loaders and smarter chunking strategies (semantic chunking vs fixed-size). LangChain has better agent primitives and LangGraph for graph-based state machines. Using each where it's strongest is the senior move. Using one to do both means doing one job poorly."

---

## AI-02 — LangGraph state machine for the denial resolution agent

**Decision.**
The denial resolution agent is a LangGraph graph.
Nodes: `triage` → `lookup_carc_definition` → `fetch_payer_policy` → `check_medical_necessity`
      → `draft_appeal` → `human_review` [INTERRUPT] → `submit_appeal` → `finalize`.
Edges are conditional based on triage output (simple denial vs complex denial vs escalate).
Agent state persisted to Postgres between interrupt and resume (durable execution).
All tool calls are logged to MongoDB as audit events.

**Interview talking point.**
"ReAct loops are good for demos and bad for production. They're hard to debug because the next step is opaque, hard to constrain because any tool can be called at any point, and hard to add human-in-the-loop to because there's no natural interrupt mechanism. LangGraph gives me a state machine with explicit transitions, inspectable state, durable persistence across the human-review interrupt, and a visual graph I can show a compliance team."

---

## AI-03 — PHI redaction before every external LLM call

**Decision.**
Microsoft Presidio (or a custom redactor with the same interface) runs on every prompt
before it leaves the FastAPI service boundary.
Redacted tokens: patient name, DOB, SSN, MRN, address, phone, NPI.
Replacement: typed tokens (`[PATIENT_NAME_1]`, `[DOB_1]`, ...).
LLM response is rehydrated by reversing the token map before returning to caller.
Redaction/rehydration logged (without the actual PHI) to the audit log.

**Interview talking point.**
"BAA covers the legal exposure; redaction covers the operational exposure. If a prompt ever leaks via a logging bug, a vendor breach, or a model memorization event, redacted prompts cap the damage. Rehydration means the biller sees real names in the UI — the redaction is invisible to end users and only exists on the wire to the LLM provider."

---

## AI-04 — Prompt registry with semantic versioning

**Decision.**
Prompts live in `rcm-rag/prompts/` as YAML files.
Schema per prompt file:
```yaml
id: denial-appeal-drafting
version: 1.2.0
model: gpt-4o
template: |
  System: You are a medical billing specialist...
  User: {context} {query}
output_schema: AppealDraftResponse
metadata:
  purpose: Draft an appeal letter for a denied claim
  author: rcm-team
  created: 2025-01-15
  eval_scores:
    faithfulness: 0.91
    carc_accuracy: 0.87
    bleu4: 0.43
    rouge_l: 0.61
    cosine_similarity: 0.88
    usefulness_p50: 4.2
```
Loader resolves by `id` + `version`. If version omitted, loads latest.
Eval harness writes scores back into YAML metadata on every eval run.
CI fails if eval scores regress below threshold for any prompt in production.

**Interview talking point.**
"Prompts are code. They need versioning, testing, and deployment gates. The registry is the difference between 'I changed a prompt and something broke in production but I don't know what' and 'prompt v1.2.0 regressed faithfulness from 0.91 to 0.73 on the eval set, CI caught it, we didn't ship it.' The eval scores in the YAML are the test results for the prompt."

---

## AI-05 — Structured outputs via Pydantic, validated and retried on failure

**Decision.**
Every LLM call that returns structured data uses OpenAI function calling / structured output mode
with a Pydantic model as the contract.
Validation: if Pydantic validation fails, retry once with an explicit correction prompt.
If it fails again: return a typed `LLMFailureResponse` to the caller, log to Mongo, increment failure counter.
Application code never sees unvalidated LLM output.

**Interview talking point.**
"I treat the LLM as a function with a typed signature. Pydantic is the type checker. The retry-with-correction pattern handles the most common failure mode — the LLM returning valid JSON with the wrong structure — without failing the request. Hard failures surface as typed errors with structured logging so I can see exactly what the model returned and why validation failed."

---

## AI-06 — Spring AI for one in-Java LLM flow

**Decision.**
Claim narrative summarization runs entirely within rcm-core via Spring AI.
On claim creation, Spring AI calls Azure OpenAI directly from Java and writes a one-paragraph
summary to the claim record.
No round-trip to rcm-rag. Spring AI manages the client, retries, and response parsing.

**Interview talking point.**
"Not every AI call needs a service boundary. For simple, prompt-only flows that are latency-sensitive and don't need the RAG infrastructure, Spring AI in the Java service is the right answer. Adding a service hop for a single LLM call would add 10-50ms of network latency for no architectural gain. I reserve the Python service for flows that genuinely need LangChain, LlamaIndex, or the vector store."

---

## AI-07 — Feature flags for every AI feature

**Decision.**
A feature flag service (50-line abstraction over a Postgres `feature_flags` table) gates:
- `rag.claim-scrubbing` — enables/disables LLM-based claim scrubbing
- `rag.denial-explanation` — enables/disables the denial explanation agent
- `rag.appeal-drafting` — enables/disables LLM-drafted appeal letters
- `ai.claim-summarization` — enables/disables Spring AI claim summaries
Flag resolution: per-tenant, with global fallback.
Cached in L1 cache, Redis-invalidated on change.

**Interview talking point.**
"Every AI feature ships behind a flag because AI rollback isn't just code rollback — it's flipping off a behavior that's harming users, in production, in seconds. Code rollback takes 10 minutes minimum. A flag flip takes 5 seconds. In a domain where a hallucinated appeal argument has real consequences, that 10-minute gap matters."

---

## AI-08 — Comprehensive RAG evaluation: four metric layers

**Decision.**
The eval harness (`rcm-rag/evals/`) measures four distinct layers:

**Layer 1 — Retrieval quality** (did we find the right chunks?):
- `recall@k` (k=1,3,5,10) — primary retrieval metric
- `precision@k`
- `MRR` (Mean Reciprocal Rank)
- `NDCG@k` (Normalized Discounted Cumulative Gain)
- `hit_rate@k` — binary, fast sanity check
- `context_relevance` — LLM-as-judge via RAGAS

**Layer 2 — Generation quality** (did the LLM use what we retrieved faithfully?):
- `faithfulness` — hallucination detector (RAGAS); threshold 0.85
- `answer_relevance` — is the response on-topic? (RAGAS)
- `BLEU-4` — surface n-gram overlap with golden reference
- `ROUGE-L` — longest common subsequence
- `cosine_similarity` — semantic similarity via embeddings
- `BERTScore` — contextualized semantic similarity

**Layer 3 — Domain quality** (did the RCM-specific facts come out right?):
- `carc_accuracy` — did it correctly identify the CARC/RARC code?
- `appeal_acceptance_rate` — tracked in schema, measured in prod only
- `usefulness_score` — 1-5 biller rating captured in UI, stored in Postgres

**Layer 4 — Operational quality** (is the system healthy?):
- `llm_latency_p50/p95/p99` — Prometheus histogram
- `tokens_used_per_request` — by prompt version, Prometheus counter
- `retrieval_latency_ms` — pgvector query time, Prometheus histogram
- `cache_hit_rate` — exact + semantic combined, Prometheus gauge
- `agent_steps_per_resolution` — efficiency proxy, Prometheus histogram
- `hallucination_rate` — faithfulness < 0.85, Prometheus counter

Libraries: RAGAS (faithfulness, answer_relevance, context_relevance),
`evaluate` from HuggingFace (BLEU, ROUGE, BERTScore),
custom implementations for recall@k, precision@k, MRR, NDCG@k, hit_rate@k.

CI gate: eval runs on every PR touching a prompt file.
Build fails if any Layer 1-3 metric regresses below its threshold for the affected prompt.
Thresholds stored in `evals/thresholds.yaml`.

**Interview talking point.**
"I separate eval into four layers because they measure different things and fail for different reasons. Retrieval quality fails when the chunking is wrong or the embedding model is mismatched to the domain. Generation quality fails when the context is good but the prompt doesn't constrain the model's output. Domain quality is the business-level check that neither of those catches — the model might be fluent and faithful but cite the wrong CARC code. Operational quality is the SRE layer. BLEU and ROUGE are the floor. The metric that matters most in healthcare is faithfulness — a hallucinated argument in an appeal letter is a real harm."

---

## AI-09 — Semantic cache for LLM responses

**Decision.**
Two-tier LLM cache:
- Tier 1: exact cache in Redis (key = `hash(promptVersionId + chunkIds + queryHash)`)
- Tier 2: semantic cache in pgvector (query embedding → cosine similarity lookup, threshold 0.97)
On a cache hit at either tier, the cached response is returned without an LLM call.
Cache entries store: response, prompt version, retrieved chunks, timestamp, hit count.
Semantic cache misses that become LLM calls are written back to both tiers.

**Interview talking point.**
"Exact-match caching gets you 20% hit rate on typical LLM workloads. Semantic caching gets you 50-70% because billers ask the same questions phrased differently every day. The threshold of 0.97 cosine similarity is conservative — I only return a cached response if the query is nearly identical semantically. I tune this threshold using the eval harness: lower threshold, higher hit rate, lower faithfulness. The threshold is a business decision, not a technical one."

---

## AI-10 — Token budget and rate limit enforcement

**Decision.**
FastAPI middleware chain:
1. `TenantBudgetMiddleware` — checks per-tenant daily token budget against Redis counter; returns HTTP 429 if exceeded
2. `ProviderRateLimitMiddleware` — token bucket per provider (Azure OpenAI has RPM and TPM limits); queues with bounded queue depth, returns 429 if queue full
3. `TokenCountingMiddleware` — counts tokens on every LLM response (via tiktoken), increments Redis counter, emits Prometheus metrics

Prometheus metrics exposed: `llm_tokens_used_total{tenant,model,prompt}`, `llm_budget_remaining{tenant}`,
`llm_rate_limit_queued{provider}`, `llm_rate_limit_rejected_total{provider}`.

**Interview talking point.**
"Two separate rate limiting concerns: budget (don't let one tenant bankrupt us) and provider rate limits (don't get throttled by Azure OpenAI). The first is a business control, the second is an operational control. They need separate middleware because they have different failure modes — budget exhaustion returns 429 to the tenant permanently until tomorrow; provider throttling queues and retries internally. Conflating them makes both worse."

---

# SECTION D — SECURITY DECISIONS

---

## SEC-01 — OAuth2/OIDC via Keycloak, RS256 signed JWTs

**Decision.**
Keycloak in docker-compose locally. UI: Authorization Code + PKCE flow.
Service-to-service: Client Credentials grant, separate client per service.
JWT signed RS256, validated by every service via JWKS endpoint.
Token lifetime: user access token 15 min, refresh 8h, service token 1h.

**Interview talking point.**
"OIDC because it's the standard, Keycloak because it runs locally and the pattern transfers to Okta/Azure AD/PingFederate with a config change. RS256 because HS256 doesn't scale to multiple independent token verifiers — every service would need the shared secret, which is a key distribution problem. RS256 is asymmetric: Keycloak holds the private key, services verify with the public key from JWKS."

---

## SEC-02 — No user token propagation between services

**Decision.**
When rcm-core calls rcm-rag or rcm-notify, it presents its own service token (Client Credentials).
The calling service includes `tenantId` and `userId` in a signed internal header (`X-Internal-Context: <signed JWT>`).
The receiving service trusts the internal context only if the caller's service token is valid.

**Interview talking point.**
"User identity and service identity are different concerns. User tokens have broad scope and live for the user's session — I don't want a compromised internal service to impersonate any user forever. Service tokens have narrow scope (just the specific API they need) and short lifetime. User context travels as data (signed header), not as the bearer token on the wire."

---

## SEC-03 — PHI data classification and encryption

**Decision.**
PHI fields in Postgres are encrypted at the column level using pgcrypto (symmetric, key from Secrets Manager).
PHI in transit: TLS 1.3 everywhere.
PHI in LLM calls: redacted before leaving the service (AI-03).
PHI in logs: log masking via Logback `MaskingConverter` (Java) and structlog processor (Python).
PHI in Kafka messages: encrypted payload, key stored in Secrets Manager.

---

## SEC-04 — Row-level security enforced at ORM layer

**Decision.**
Java: Hibernate `@Filter` named `tenantFilter` applied to all `@Entity` classes, activated on every session.
Python: SQLAlchemy `before_compile` event adds `WHERE tenant_id = :tenant_id` to all queries.
Test: `TenantIsolationTest` verifies that a query without the filter active returns 0 rows from a pre-seeded multi-tenant dataset.

---

## SEC-05 — Secrets management: env vars in dev, cloud vault in prod

**Decision.**
`.env.example` checked in, `.env` git-ignored.
Docker Compose loads from `.env`.
Prod: AWS Secrets Manager / Azure Key Vault, loaded at startup via SDK.
Application code reads from environment; it doesn't know or care where the env came from.

---

## SEC-06 — HIPAA audit logging via AOP (Java) and FastAPI dependency (Python)

**Decision.**
Every PHI access generates an audit event written to MongoDB.
Event schema:
```json
{
  "tenantId": "uuid",
  "actorId": "uuid",
  "actorType": "user|service|agent",
  "action": "READ|WRITE|DELETE",
  "entityType": "Patient|Claim|...",
  "entityId": "uuid",
  "timestamp": "ISO8601",
  "ipAddress": "string",
  "requestId": "uuid",
  "outcome": "SUCCESS|FAILURE",
  "llmCallId": "uuid|null"
}
```
Java: Spring AOP `@Around` advice on all service methods annotated `@PhiAccess`.
Python: FastAPI dependency `AuditDependency` injected into all routes that touch PHI.
Agent: every tool call that touches PHI emits an audit event with `actorType: agent` and the LangGraph run ID.

**Interview talking point.**
"HIPAA audit is a cross-cutting concern so it lives at the cross-cutting layer — AOP in Java, dependencies in FastAPI. Developers annotate their methods with `@PhiAccess`; they don't write audit events. This means developers can't accidentally forget. The agent audit events are particularly important: every tool call the agent makes that touches patient data is traceable back to the agent run, the tenant, and the user who triggered the run."

---

## SEC-07 — Input validation at three layers

**Decision.**
Layer 1: API boundary — Bean Validation (Java DTOs), Pydantic (Python), Zod (TypeScript/Node.js)
Layer 2: Domain layer — invariant checks in domain objects (claim total must equal sum of lines, etc.)
Layer 3: Database — Postgres CHECK constraints on critical business rules

---

# SECTION E — OPS DECISIONS

---

## OPS-01 — Full observability triad across all five services

**Decision.**
Structured JSON logs: Logback (Java), structlog (Python), pino (Node.js)
Metrics: Micrometer → Prometheus (Java), prometheus-client (Python), prom-client (Node.js)
Traces: OpenTelemetry SDK on all five services, W3C Trace Context propagated across all boundaries
(REST, gRPC, GraphQL, Kafka messages carry trace context in headers/metadata)

Grafana dashboards:
- Service overview (all five services, RED metrics: Rate/Errors/Duration)
- LLM cost dashboard (tokens per tenant, cost estimate, budget remaining)
- RAG quality dashboard (all Layer 1-4 metrics from AI-08)
- Claim throughput dashboard (claims per hour, scrub pass rate, denial rate)
- Agent execution dashboard (steps per resolution, tool call breakdown, interrupt wait time)

**Interview talking point.**
"Traces across a polyglot boundary are where distributed systems debugging actually lives. When a biller says 'the denial explanation is slow', I need one trace that shows me: the Kafka consumer picked it up after 200ms, the gRPC call to rcm-rag took 50ms, the pgvector query took 40ms, the LLM call took 1200ms. Without trace context in Kafka headers, that story breaks at the async boundary and I'm guessing. W3C Trace Context is the standard; OpenTelemetry auto-instrumentation handles the boilerplate."

---

## OPS-02 — Local observability stack: LGTM (Loki + Grafana + Tempo + Mimir)

**Decision.**
docker-compose includes: Prometheus, Grafana, Loki (logs), Tempo (traces), Mimir (long-term metrics storage).
Grafana provisioned via `grafana/provisioning/` — dashboards and datasources as code.
No manual Grafana setup required after `docker compose up`.

---

## OPS-03 — Testcontainers for all integration tests

**Decision.**
Java: Testcontainers for Postgres (with pgvector), Kafka, Redis, MongoDB, Keycloak.
Python: testcontainers-python for Postgres, Kafka, Redis, MongoDB.
Node.js: testcontainers via `testcontainers` npm package for Redis, Kafka.
Integration tests start real infrastructure, not mocks or in-memory fakes.

**Interview talking point.**
"In-memory H2 doesn't catch the bugs Postgres catches. Mocked Kafka doesn't catch serialization bugs. Testcontainers solved the 'tests pass locally, fail in CI' problem for me. The startup cost is 10-15 seconds per test suite; the alternative is production bugs that took 2 minutes each to reproduce in staging."

---

## OPS-04 — Pact contract tests for all synchronous service boundaries

**Decision.**
Consumer-driven contract tests for: rcm-bff → rcm-core (REST), rcm-core → rcm-rag (gRPC + REST fallback), rcm-bff → rcm-notify (REST).
Java generates pacts; Python and Node.js verify them.
GitHub Actions workflow `contract-tests.yml` runs pact verification on every PR.
PR is blocked if pact verification fails.

**Interview talking point.**
"OpenAPI documents the contract. Pact verifies it. At a polyglot boundary I can't rely on shared generated types — a Java client and a Python server each generate their own code from the spec, and if the spec and the code drift, only a contract test catches it before production. Consumer-driven means the consumer defines what it needs and the provider proves it can deliver it."

---

## OPS-05 — GitHub Actions CI per service, shared contract workflow

**Decision.**
Workflows:
- `rcm-core-ci.yml`: build → test → integration test → pact generate → containerize → push GHCR
- `rcm-rag-ci.yml`: lint → test → integration test → eval harness → pact verify → containerize → push GHCR
- `rcm-notify-ci.yml`: lint → test → containerize → push GHCR
- `rcm-bff-ci.yml`: lint → test → pact generate → containerize → push GHCR
- `rcm-ui-ci.yml`: lint → test → Playwright E2E → build → push GHCR
- `contract-tests.yml`: triggered after any service CI passes; runs all Pact verifications in order

---

## OPS-06 — Docker Compose for local dev, Terraform stubs for prod

**Decision.**
`docker-compose.yml` at repo root runs all five services plus all infrastructure.
Single command: `docker compose up --build`.
`terraform/` contains AWS deployment stubs (VPC, ECS tasks for each service,
RDS Postgres, ElastiCache Redis, MSK Kafka, DocumentDB for Mongo, CosmosDB via Azure provider,
ALB, Route53, ACM, Secrets Manager, CloudWatch).
Terraform is not applied — it documents the prod target.

---

## OPS-07 — Feature flags: Postgres-backed, L1-cached, Redis-invalidated

**Decision.**
`feature_flags` table in Postgres: `(tenant_id, flag_name, enabled, metadata JSONB)`.
Java client: `FeatureFlags.isEnabled(flagName, tenantId)` — checks L1 cache, falls back to DB.
Python client: same interface.
Node.js client: same interface.
Redis pub/sub channel `feature-flags-invalidated`: when a flag is updated, all service instances
clear their L1 cache for that flag within 1 second.

---

# SECTION F — PROCESS DECISIONS

---

## PROC-01 — ADR per locked decision, with interview talking points

**Decision.**
Every decision in this document has a matching file in `docs/adr/`.
ADR template:
```markdown
# ADR-[ID]: [Short Title]
Status: Accepted
Date: YYYY-MM-DD

## Context
[Why did this decision need to be made?]

## Decision
[What was decided, stated precisely]

## Rationale
[Why this option over the alternatives]

## Alternatives considered
[What else was evaluated and why it lost]

## Consequences
[What gets easier, what gets harder]

## Interview talking point
**One-sentence defense:** "..."
**Follow-up questions to prepare for:**
1. ...
2. ...
3. ...
**What a weak answer sounds like (avoid this):** "..."
```

---

## PROC-02 — INTERVIEW_PREP.md as a cross-reference index

**Decision.**
`docs/INTERVIEW_PREP.md` is generated as the final DeepSeek prompt in Phase 9.
It cross-references all ADRs by likely interview question category:
- System design questions
- AI/ML and RAG questions
- Data architecture questions
- Security and compliance questions
- Scalability questions
- Process and Agile questions
Each entry: question → ADR reference → file location in codebase → talking point.

---

## PROC-03 — Trunk-based development, PRs <2 days

**Decision.**
`main` is always deployable. Feature branches live <48 hours.
PR requirements: 1 review, passing CI, passing Pact, eval gate (if prompt changed).

---

## PROC-04 — Conventional Commits + semantic versioning

**Decision.**
Commit format: `feat(claims): add scrub retry on RAG timeout`.
Tags follow semver. Changelog generated by `git-cliff` on release.

---

## PROC-05 — Pre-commit hooks on all services

**Decision.**
`pre-commit` framework: gitleaks (secrets), ruff (Python), spotless (Java),
eslint (TypeScript/JS), commitlint (commit messages).
Installed via `pre-commit install` post-clone (documented in CONTRIBUTING.md).

---

# SIGN-OFF CHECKLIST

Before proceeding to Section 2 (Canonical File Tree), confirm:

- [ ] ARCH-01: Five services — rcm-core (Java), rcm-rag (Python), rcm-notify (Node), rcm-bff (Node+GraphQL), rcm-ui (Next.js)
- [ ] ARCH-03: REST + GraphQL + gRPC all present with real justified homes
- [ ] ARCH-06: Multi-tenancy enforced everywhere
- [ ] DATA-01: Four stores — Postgres+pgvector, MongoDB, CosmosDB NoSQL, Redis
- [ ] DATA-03: CosmosDB for claim processing event stream (Change Feed)
- [ ] AI-02: LangGraph agent with human-in-the-loop interrupt
- [ ] AI-08: Four-layer eval metrics (retrieval + generation + domain + operational)
- [ ] PROC-01: Every ADR includes interview talking points

Changes to any item above require revising this document before prompts are written.
