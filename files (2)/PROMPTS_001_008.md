# BATCH A — Prompts 001–008
# Documentation, Diagrams, ADRs
# Paste each CONTEXT block directly into DeepSeek web chat.
# ============================================================

# ============================================================
# PROMPT-001: RCM Glossary
# ============================================================
# GOAL: Generate the complete RCM domain glossary
# DEPENDS ON: nothing
# OUTPUT: docs/rcm-glossary.md
# ACCEPTANCE CRITERIA:
#   1. Every term below is defined (check the list at bottom of prompt)
#   2. Each definition is 2-5 sentences, plain English, no undefined jargon
#   3. File begins with a table of contents linking to each term
#   4. File ends with a "Protocol Formats" section covering EDI X12 basics
# COMMON FAILURE MODES:
#   - Definitions too short (1 sentence) — ask DeepSeek to expand
#   - Missing EDI section — ask for it explicitly as a follow-up
# ============================================================

PROMPT-001 CONTEXT — paste this into DeepSeek:
==========================================
You are generating documentation for a production-grade Revenue Cycle Management (RCM)
platform. Your task is to produce a comprehensive glossary of RCM domain terms.

OUTPUT REQUIREMENTS:
- Single markdown file saved as: docs/rcm-glossary.md
- Start the file with: // FILE: docs/rcm-glossary.md
- End the file with: // ===== END OF FILE =====
- Include a linked table of contents at the top
- Each term: bold heading, 2-5 sentence plain-English definition,
  one concrete example where helpful
- Group terms into sections: Patient & Demographics, Clinical, Billing & Coding,
  Claims, Payers & Adjudication, Denials & Appeals, Payments, EDI Formats,
  AI & Technology Terms

TERMS TO DEFINE (must include all of these):
Patient Registration, Encounter, Charge Capture, CPT Code, ICD-10 Code,
HCPCS Code, Modifier, Diagnosis Code, Procedure Code, Place of Service (POS),
Revenue Code, Provider NPI, Rendering Provider, Billing Provider,
Payer, Primary Payer, Secondary Payer, Coordination of Benefits (COB),
Eligibility Verification, Prior Authorization, Referral,
Claim, Clean Claim, Dirty Claim, Claim Scrubbing, Claim Submission,
Professional Claim (CMS-1500), Institutional Claim (UB-04),
837P, 837I, 835 ERA, 270/271 Eligibility Transaction, 999 Acknowledgement,
Clearinghouse, Real-Time Adjudication, Batch Adjudication,
Remittance Advice (RA), Electronic Remittance Advice (ERA),
Explanation of Benefits (EOB), Allowed Amount, Contractual Adjustment,
Write-Off, Patient Responsibility, Deductible, Copay, Coinsurance,
Out-of-Pocket Maximum, In-Network, Out-of-Network,
CARC (Claim Adjustment Reason Code), RARC (Remittance Advice Remark Code),
Denial, Rejection, Denial Management, Appeal, Grievance,
Medical Necessity, Prior Authorization, Level of Care,
Accounts Receivable (AR), AR Aging, Days in AR, Write-Off,
Clean Claim Rate, First-Pass Resolution Rate, Denial Rate,
Revenue Cycle Management (RCM), Practice Management System (PMS),
Electronic Health Record (EHR), Health Information Exchange (HIE),
HIPAA, PHI (Protected Health Information), BAA (Business Associate Agreement),
EDI (Electronic Data Interchange), X12 Standard, ANSI X12,
Segment, Loop, Element, Delimiter (EDI concepts),
RAG (Retrieval-Augmented Generation), Vector Embedding,
Semantic Search, LLM (Large Language Model), Prompt Engineering,
CARC Accuracy, Faithfulness (in LLM evaluation), Hallucination

PROTOCOL FORMATS SECTION:
Include a dedicated section explaining the structure of:
- 837P transaction (professional claim) — show a minimal realistic example
  with key segments: ISA, GS, ST, BPR, NM1, CLM, SV1, SE, GE, IEA
- 835 ERA transaction — show key segments: ISA, GS, ST, BPR, CLP, SVC, CAS
- 270/271 eligibility — explain request/response pattern with key segments

STYLE:
- Plain English throughout
- When defining EDI terms, show short illustrative examples inline
- Tone: technical reference document, not a tutorial
- Do not use undefined acronyms without first defining them
==========================================

# ============================================================
# PROMPT-002: C4 Diagrams L1 + L2
# ============================================================
# GOAL: System Context diagram + Containers diagram
# DEPENDS ON: PROMPT-001
# OUTPUT: docs/diagrams/01-c4-system-context.md
#         docs/diagrams/02-c4-containers.md
# ACCEPTANCE CRITERIA:
#   1. System context shows: Biller user, Admin user, Clearinghouse,
#      Payer systems, EHR system, LLM Provider, Identity Provider
#   2. Container diagram shows all 5 services + all 4 data stores +
#      Kafka + Redis + Keycloak
#   3. Communication protocols labeled on every arrow
#      (REST, gRPC, Kafka, GraphQL, OIDC, JDBC, etc.)
#   4. Both diagrams use ASCII art (not Mermaid) — clean box-and-line style
# COMMON FAILURE MODES:
#   - Missing protocol labels on arrows — ask DeepSeek to add them
#   - Mermaid used instead of ASCII — specify ASCII explicitly
# ============================================================

PROMPT-002 CONTEXT — paste this into DeepSeek:
==========================================
You are generating architecture diagrams for a production-grade Revenue Cycle
Management (RCM) platform. Use the C4 Model format. All diagrams must be
ASCII art (NOT Mermaid, NOT PlantUML — plain ASCII box-and-line diagrams).

THE SYSTEM:
A healthcare Revenue Cycle Management platform with these components:

SERVICES:
- rcm-core: Spring Boot (Java 21) — RCM transactional backbone
- rcm-rag: FastAPI (Python 3.12) — RAG, embeddings, LLM, LangGraph agent
- rcm-notify: Express.js (Node.js 20) — notifications (email/SMS/webhook)
- rcm-bff: Apollo Server + Express (Node.js 20) — GraphQL BFF for UI
- rcm-ui: Next.js 14 — biller workbench UI

DATA STORES:
- PostgreSQL 16 + pgvector: RCM transactional data + vector embeddings
- MongoDB 7: PHI access audit log (append-only)
- CosmosDB (NoSQL API): claim processing event stream (Change Feed)
- Redis 7: L2 distributed cache + rate limit counters

INFRASTRUCTURE:
- Apache Kafka: async messaging (4 topics)
- Keycloak: OIDC identity provider
- Prometheus + Grafana + Loki + Tempo: observability stack
- Ollama: self-hosted LLM (dev only)

EXTERNAL SYSTEMS:
- Clearinghouse (mock): receives 837 claims, returns 835 ERAs
- Payer systems (mock): eligibility (270/271), adjudication
- EHR system (mock): patient data source
- Azure OpenAI: LLM provider (prod)
- Azure OpenAI Embeddings: embedding provider (prod)

USERS:
- Medical Biller: uses rcm-ui to review claims, manage denials, approve appeals
- RCM Admin: manages payer configurations, reviews reports
- System (automated): clearinghouse and payer systems calling rcm-core APIs

COMMUNICATION PROTOCOLS:
- rcm-ui → rcm-bff: GraphQL over HTTP + SSE for streaming
- rcm-bff → rcm-core: REST/JSON over HTTP
- rcm-bff → rcm-rag: REST/JSON over HTTP (status/polling endpoints)
- rcm-core → rcm-rag: gRPC (claim scrubbing, sync)
- rcm-core → rcm-notify: REST/JSON (notification trigger)
- rcm-core → Kafka: produce (claim.submitted, denial.received)
- rcm-rag → Kafka: consume (denial.received), produce (denial.explained)
- rcm-notify → Kafka: consume (claim.submitted, denial.received, denial.explained)
- All services → Keycloak: OIDC (JWT validation via JWKS)
- rcm-core → PostgreSQL: JDBC
- rcm-rag → PostgreSQL: asyncpg
- rcm-core → Redis: Lettuce
- rcm-rag → Redis: redis-py async
- rcm-core → MongoDB: MongoDB Java driver
- rcm-rag → MongoDB: Motor (async)
- rcm-core → CosmosDB: Azure Cosmos SDK for Java
- rcm-rag → CosmosDB: azure-cosmos Python SDK
- rcm-core → Azure OpenAI: Spring AI
- rcm-rag → Azure OpenAI: LangChain OpenAI client

OUTPUT — produce TWO files:

FILE 1: docs/diagrams/01-c4-system-context.md
- C4 Level 1: System Context
- Show: the RCM Platform as ONE box in the center
- Show: all external actors and systems around it
- Label every relationship with what data flows and which protocol
- ASCII art, clean alignment, minimum 80 chars wide

FILE 2: docs/diagrams/02-c4-containers.md
- C4 Level 2: Containers
- Zoom into the RCM Platform box from L1
- Show every service, data store, and infrastructure component as a box
- Label every box with: name, technology, brief purpose
- Label every arrow with: protocol + what flows
- Group related containers visually (app services group, data stores group,
  infra group, observability group)
- ASCII art, clean alignment

FORMAT FOR EACH FILE:
// FILE: docs/diagrams/XX-name.md
---
# [Diagram Title]

## Overview
[2-3 sentences describing what this diagram shows and why it matters]

## Diagram
```
[ASCII diagram here]
```

## Key Points
[5-7 bullet points explaining the most important relationships]

## Interview Talking Points
- [3 talking points specific to this diagram]
// ===== END OF FILE =====
==========================================

# ============================================================
# PROMPT-003: C4 L3 Component Diagrams — rcm-core + rcm-rag
# ============================================================
# GOAL: Internal component breakdown of the two main backend services
# DEPENDS ON: PROMPT-002
# OUTPUT: docs/diagrams/03-c4-components-rcm-core.md
#         docs/diagrams/04-c4-components-rcm-rag.md
# ACCEPTANCE CRITERIA:
#   1. rcm-core diagram shows all 7 bounded contexts + common module
#      with their key classes labeled
#   2. rcm-rag diagram shows all major modules: ingestion, retrieval,
#      agent (with all 7 nodes), LLM layer, prompt registry
#   3. Arrows show in-process calls (dashed) vs external calls (solid)
#   4. Technology labels on every component box
# ============================================================

PROMPT-003 CONTEXT — paste this into DeepSeek:
==========================================
You are generating C4 Level 3 Component diagrams for a production-grade RCM platform.
Use ASCII art. Show internal components of two services.

ARCHITECTURE CONTEXT:
[Paste the full text of docs/diagrams/02-c4-containers.md here after running PROMPT-002]

COMPONENT DETAILS:

rcm-core (Spring Boot Java 21) internal structure:
- common module: SecurityConfig, JwtAuthFilter, TenantContext/TenantFilter,
  TenantHibernateFilter, AuditAspect (AOP), AuditService, L1CacheConfig (Caffeine),
  CacheInvalidationListener, FeatureFlagService, DomainEventPublisher,
  GlobalExceptionHandler, MetricsConfig, TraceConfig
- registration: Patient (aggregate), PatientRepository, PatientService,
  PatientController (REST), PatientMapper (MapStruct)
- eligibility: EligibilityService, EligibilityCache (Redis L2),
  PayerEligibilityClient (mock 270/271), EligibilityController
- charge-capture: Encounter (aggregate), ChargeItem, CptCode, DiagnosisCode,
  ChargeService, ChargeController
- claims: Claim (aggregate), ClaimLine, ClaimService, ClaimScrubService,
  ClaimScrubGrpcClient (Resilience4j wrapped), ClaimSubmissionService (Kafka),
  ClaimSummaryService (Spring AI), Edi837Builder, CosmosDB event writer,
  ClaimController
- payments: Era, Edi835Parser, PaymentPostingService, PaymentController
- denials: Denial (aggregate), AppealDraft, DenialService, AppealService,
  DenialReceivedConsumer (Kafka), DenialExplainedConsumer (Kafka), DenialController
- ar: ArBalance, ArService, ArController

rcm-rag (FastAPI Python 3.12) internal structure:
- common: JWTAuth dependency, TenantContext, AuditDependency, PhiRedactor (Presidio),
  StructlogObservability, FeatureFlagClient
- db layer: AsyncPG/SQLAlchemy (Postgres), redis-py async, Motor (MongoDB),
  azure-cosmos (CosmosDB)
- ingestion (LlamaIndex): DocumentLoader, SemanticChunker, Embedder (provider-abstracted),
  PgVectorStore, FaissCache, IngestionPipeline
- retrieval (LangChain): HybridRetriever (pgvector + WHERE filters),
  SemanticCache (pgvector cosine lookup), CrossEncoderReranker
- prompts: PromptRegistry (YAML loader + semver resolver), 4 prompt YAML files
- llm: LLMClient (interface), AzureOpenAIClient, OllamaClient,
  StructuredOutputValidator (Pydantic), TokenCounter (tiktoken),
  BudgetMiddleware, RateLimitMiddleware, TokenCountingMiddleware
- agent (LangGraph): AgentState, DenialResolutionGraph,
  nodes: triage, lookup_carc, fetch_payer_policy, check_medical_necessity,
  draft_appeal, human_review (INTERRUPT), finalize
  tools: CarcLookupTool, PayerPolicyTool, MedicalNecessityTool, AppealDraftTool
  AgentStatePersistence (Postgres)
- flows: ClaimScrubbingFlow (gRPC servicer), DenialExplanationFlow (Kafka consumer)
- api: FastAPI routers (health, ingestion, retrieval, denial, eval)
- evals: EvalRunner, retrieval_metrics, generation_metrics, domain_metrics,
  operational_metrics

OUTPUT — produce TWO files with format:
// FILE: docs/diagrams/03-c4-components-rcm-core.md
[diagram + overview + key points + interview talking points]
// ===== END OF FILE =====

// FILE: docs/diagrams/04-c4-components-rcm-rag.md
[diagram + overview + key points + interview talking points]
// ===== END OF FILE =====

STYLE: ASCII art. Show components as boxes. Show relationships as labeled arrows.
Use dashed arrows (- - >) for in-process calls, solid arrows (-->) for external calls.
Group related components inside a larger labeled box.
==========================================

# ============================================================
# PROMPT-004: C4 L3 Components — rcm-bff + rcm-notify + Deployment Diagrams
# ============================================================
# GOAL: Component diagrams for Node.js services + prod and local deployment
# DEPENDS ON: PROMPT-002
# OUTPUT: docs/diagrams/05-c4-components-rcm-bff.md
#         docs/diagrams/06-c4-components-rcm-notify.md
#         docs/diagrams/07-deployment-prod.md
#         docs/diagrams/08-deployment-local.md
# ACCEPTANCE CRITERIA:
#   1. rcm-bff shows Apollo Server, all 6 resolvers, DataLoader, SSE endpoint,
#      2 REST data sources
#   2. rcm-notify shows KafkaJS consumer, all 3 handlers, all 3 channels,
#      Handlebars templates
#   3. Prod deployment shows AWS: VPC, public/private subnets, ALB, ECS tasks,
#      RDS, ElastiCache, MSK, CosmosDB (Azure), Secrets Manager
#   4. Local deployment shows docker-compose stack with all containers
# ============================================================

PROMPT-004 CONTEXT — paste this into DeepSeek:
==========================================
You are generating C4 Level 3 component diagrams and deployment diagrams
for a production-grade RCM platform. Use ASCII art throughout.

ARCHITECTURE CONTEXT:
[Paste the full text of docs/diagrams/02-c4-containers.md here]

rcm-bff (Apollo Server + Express, Node.js 20) internals:
- Apollo Server 4 with Express middleware
- GraphQL schema: merged from 6 type definition files
  (patient.graphql, claim.graphql, denial.graphql, payment.graphql,
  ar.graphql, agent.graphql)
- Resolvers: PatientResolver, ClaimResolver, DenialResolver,
  PaymentResolver, ArResolver, AgentResolver
- DataLoader: per-request batching for N+1 prevention
  (PatientLoader, ClaimLoader, DenialLoader)
- DataSources: RcmCoreApi (Axios REST client to rcm-core),
  RcmRagApi (Axios REST client to rcm-rag status endpoints)
- Postgres client: read-only queries against materialized views (reporting)
- SSE endpoint: /sse/denial/:id streams denial explanation progress to UI
- Auth: JWT validation middleware (Keycloak JWKS)
- Multi-tenancy: tenant context from JWT claims
- Observability: OTel auto-instrumentation + pino logging + prom-client

rcm-notify (Express, Node.js 20) internals:
- Express HTTP server (health endpoint only — main work is Kafka-driven)
- KafkaJS consumer: subscribes to 3 topics
  (claim.submitted, denial.received, denial.explained)
- Event handlers: ClaimSubmittedHandler, DenialReceivedHandler,
  DenialExplainedHandler
- Notification channels: EmailChannel (Nodemailer), SmsChannel (Twilio stub),
  WebhookChannel (outbound HTTP)
- Handlebars templates: claim-submitted.hbs, denial-received.hbs,
  appeal-ready-for-review.hbs
- Postgres client: writes to notification_log table
- Auth: JWT validation for any REST calls
- Observability: OTel + pino + prom-client

PROD DEPLOYMENT (AWS + Azure hybrid for CosmosDB):
- AWS region: us-east-1
- VPC: 3 AZs, public subnets (ALB), private subnets (ECS, RDS, MSK, ElastiCache)
- ALB: routes /api/* to rcm-core ECS, /rag/* to rcm-rag ECS,
  /graphql to rcm-bff ECS, /* to rcm-ui ECS
- ECS Fargate tasks: one task definition per service, auto-scaling
- RDS: Postgres 16 Multi-AZ, pgvector extension enabled
- ElastiCache: Redis 7 cluster mode
- MSK: Kafka 3.7, 3 brokers, TLS + SASL
- DocumentDB: MongoDB-compatible, 3-node cluster
- Azure CosmosDB: NoSQL API, multi-region write
- Secrets Manager: all secrets injected as env vars at task start
- CloudWatch: logs, metrics, alarms

LOCAL DEPLOYMENT (docker-compose):
All containers on bridge network rcm-network:
- postgres:16 (port 5432, pgvector extension)
- mongo:7 (port 27017)
- azure-cosmos-emulator (port 8081)
- redis:7 (port 6379)
- zookeeper (port 2181)
- kafka (port 9092)
- keycloak (port 8080)
- ollama (port 11434)
- prometheus (port 9090)
- grafana (port 3001)
- loki (port 3100)
- tempo (port 3200)
- rcm-core (port 8081) — depends on postgres, kafka, redis, mongo, cosmos, keycloak
- rcm-rag (port 8082) — depends on postgres, kafka, redis, mongo, cosmos
- rcm-notify (port 8083) — depends on kafka
- rcm-bff (port 8084) — depends on rcm-core, rcm-rag, postgres
- rcm-ui (port 3000) — depends on rcm-bff, keycloak

OUTPUT: 4 files. Each begins with // FILE: path and ends with // ===== END OF FILE =====
Include overview, diagram, key points, and interview talking points in each file.
==========================================

# ============================================================
# PROMPT-005: Security + Data Flow Diagrams
# ============================================================
# GOAL: Network trust boundaries, PHI data flow, multi-tenancy, observability topology
# DEPENDS ON: PROMPT-002
# OUTPUT: docs/diagrams/09-network-trust-boundaries.md
#         docs/diagrams/10-phi-data-flow.md
#         docs/diagrams/11-multi-tenancy.md
#         docs/diagrams/12-observability-topology.md
# ACCEPTANCE CRITERIA:
#   1. PHI data flow diagram shows EVERY place PHI crosses a boundary,
#      every encryption point, every redaction point — this is the HIPAA diagram
#   2. Trust boundary diagram shows: internet zone, DMZ, app tier, data tier
#      with TLS termination points marked
#   3. Multi-tenancy diagram shows shared schema with tenant discriminator
#      at DB level, ORM filter, and how tenant_id flows from JWT to query
#   4. Observability topology shows where logs/metrics/traces originate
#      and where they flow
# ============================================================

PROMPT-005 CONTEXT — paste this into DeepSeek:
==========================================
You are generating security and operational architecture diagrams for a
HIPAA-compliant RCM platform. Use ASCII art. These diagrams are the most
important for compliance and security interviews.

SYSTEM ARCHITECTURE (reference):
5 services: rcm-core (Java/Spring Boot), rcm-rag (Python/FastAPI),
rcm-notify (Node.js/Express), rcm-bff (Node.js/Apollo), rcm-ui (Next.js)
4 data stores: PostgreSQL+pgvector, MongoDB, CosmosDB, Redis
Messaging: Kafka
Auth: Keycloak (OIDC/JWT, RS256)

SECURITY ARCHITECTURE:
- TLS 1.3 on all external traffic (ALB terminates, re-encrypts to services)
- mTLS between services in prod (documented, self-signed in dev)
- JWT bearer tokens: user tokens from Keycloak (15min access, 8h refresh)
- Service-to-service: Client Credentials grant, separate tokens
- PHI fields in Postgres: encrypted at column level (pgcrypto)
- PHI in LLM calls: redacted via Presidio before leaving rcm-rag
  (tokens: [PATIENT_NAME], [DOB], [SSN], [MRN] etc.)
  rehydrated in response before returning to caller
- PHI in Kafka messages: encrypted payload
- PHI in logs: masked via log processors on all services
- Audit log: every PHI access → MongoDB audit_events collection
- Secrets: AWS Secrets Manager in prod, .env in dev

MULTI-TENANCY:
- Shared schema with tenant_id discriminator on every table
- Hibernate @Filter (Java): applied to every session, adds WHERE tenant_id = ?
- SQLAlchemy before_compile event (Python): same
- pg middleware (Node.js): appended to every query
- tenant_id extracted from JWT claims on every request
- Redis keys prefixed with tenant_id
- Kafka messages carry tenantId in header
- CosmosDB: tenantId is the partition key
- MongoDB: tenantId is indexed on every collection

OBSERVABILITY:
- Structured JSON logs: Logback (Java), structlog (Python), pino (Node.js)
  → all ship to Loki via Promtail/Alloy
- Metrics: Micrometer (Java), prometheus-client (Python), prom-client (Node.js)
  → all scraped by Prometheus → stored in Mimir (long-term)
- Traces: OpenTelemetry SDK on all 5 services
  → W3C Trace Context in HTTP headers, Kafka message headers, gRPC metadata
  → shipped to Tempo
- Grafana: unified dashboards reading from Loki + Prometheus/Mimir + Tempo

OUTPUT: 4 files.

DIAGRAM 1 (09-network-trust-boundaries.md):
Show trust zones: Internet → WAF/ALB (public subnet) → App tier (private subnet,
ECS tasks) → Data tier (private subnet, RDS/ElastiCache/MSK/DocumentDB).
Mark: where TLS terminates, where re-encryption happens, where mTLS applies,
which ports are open on which security group rules.

DIAGRAM 2 (10-phi-data-flow.md):
This is the HIPAA hero diagram. Trace PHI from its entry point (patient registration
via UI) through every system component, marking:
- [ENCRYPTED IN TRANSIT] at every network hop with PHI
- [ENCRYPTED AT REST] at every storage point
- [REDACTED] at the point PHI is removed before LLM calls
- [REHYDRATED] where tokens are replaced with real values
- [AUDIT LOGGED] at every PHI access point
- [MASKED IN LOGS] at logging points
Show the full journey: UI → BFF → rcm-core → DB (at rest) →
rcm-core → rcm-rag (PHI redacted here) → LLM provider (no PHI reaches here) →
rcm-rag → rcm-core (rehydrated) → audit log → notification (anonymized)

DIAGRAM 3 (11-multi-tenancy.md):
Show: JWT arrives with tenant_id claim → middleware extracts to thread-local/context-var
→ Hibernate filter / SQLAlchemy event adds WHERE clause → query hits shared table
with tenant_id column → result returned only for that tenant.
Show the same flow for Redis (key prefix), Kafka (header), CosmosDB (partition key).
Show a split-screen: "What the code sees" vs "What the DB sees".

DIAGRAM 4 (12-observability-topology.md):
Show: each service emitting logs/metrics/traces → collection layer
(Promtail for logs, Prometheus scrape for metrics, OTel collector for traces)
→ storage (Loki/Mimir/Tempo) → Grafana unified view.
Mark: where the cross-service trace is stitched together (W3C Trace Context
in Kafka headers — this is the key insight).

Each file: // FILE: path, overview, diagram, key points, interview talking points,
// ===== END OF FILE =====
Include especially strong interview talking points for the PHI data flow diagram —
this is what HIPAA interviewers probe.
==========================================

# ============================================================
# PROMPT-006: AI Architecture Diagrams
# ============================================================
# GOAL: Agent architecture, caching architecture, prompt registry
# DEPENDS ON: PROMPT-002 PROMPT-003
# OUTPUT: docs/diagrams/13-agent-architecture.md
#         docs/diagrams/14-caching-architecture.md
#         docs/diagrams/15-prompt-registry.md
# ACCEPTANCE CRITERIA:
#   1. Agent diagram shows LangGraph state machine with all 7 nodes,
#      conditional edges, INTERRUPT marker on human_review node,
#      and all 4 tools labeled
#   2. Caching diagram shows all 5 cache layers: L1 in-process,
#      L2 Redis (3 uses), L3 materialized views, embedding cache, semantic cache
#   3. Prompt registry diagram shows: YAML file → loader → version resolution
#      → prompt assembly → LLM call → eval feedback loop
# ============================================================

PROMPT-006 CONTEXT — paste this into DeepSeek:
==========================================
You are generating AI architecture diagrams for a production-grade RCM platform.
Use ASCII art. These diagrams demonstrate advanced AI system design.

AGENT ARCHITECTURE (LangGraph Denial Resolution Agent):
The agent is a LangGraph state machine triggered when a denial is received.
It has 7 nodes and 4 tools:

NODES (in execution order):
1. triage: classifies the denial (simple/complex/escalate) based on CARC code
   and claim details. Conditional edges based on classification.
2. lookup_carc: uses CarcLookupTool to fetch the CARC + RARC code definitions
   from the reference database
3. fetch_payer_policy: uses PayerPolicyTool to retrieve relevant payer policy
   chunks via RAG (pgvector similarity search filtered by payer_id)
4. check_medical_necessity: uses MedicalNecessityTool to retrieve medical
   necessity documentation relevant to the procedure code
5. draft_appeal: uses AppealDraftTool to assemble context and call the LLM
   (via prompt registry, phi redaction, structured output validation)
   to generate an appeal letter draft
6. human_review: INTERRUPT NODE — saves state to Postgres, suspends execution,
   waits for biller to review/edit/approve in the UI
7. finalize: resumes after human approval, records outcome, publishes
   denial.explained event to Kafka

CONDITIONAL EDGES:
- triage → lookup_carc: if simple or complex denial
- triage → finalize (escalate): if escalation required (no AI attempt)
- draft_appeal → human_review: always (mandatory human checkpoint)
- human_review → finalize: on approval
- human_review → draft_appeal: on rejection (re-draft with feedback)

TOOLS:
- CarcLookupTool: queries Postgres CARC/RARC reference tables (L1 cached)
- PayerPolicyTool: pgvector similarity search filtered by payer_id + effective_date
- MedicalNecessityTool: pgvector similarity search filtered by CPT code family
- AppealDraftTool: assembles prompt + calls LLM via client.py

CACHING ARCHITECTURE (5 layers):
L1 — In-process LRU (Caffeine/cachetools):
  - CPT/ICD10 reference data (loaded at startup, ~50K records)
  - CARC/RARC definitions (~300 codes)
  - Payer metadata (~500 payers)
  - Prompt templates (all versions, <1MB)
  - Feature flags (invalidated via Redis pub/sub)
  - TTL: service lifetime, Redis pub/sub invalidation

L2 — Redis (distributed, TTL-based):
  - Eligibility responses: key={tenantId}:{patientId}:{payerId}, TTL=24h
  - LLM exact-match cache: key=hash(promptVersionId+chunkIds+queryHash), TTL=7d
  - Rate limit counters: key={tenantId}:{endpoint}:{minuteBucket}, TTL=2min

L3 — PostgreSQL Materialized Views (nightly refresh via pg_cron):
  - ar_aging_buckets: AR aging report
  - denial_rate_by_payer: denial analytics
  - claim_throughput_by_day: operational metrics
  - eligibility_cache_hit_rate: cache effectiveness

L4 — Embedding cache (in-process, keyed by hash of text + model_version):
  - Prevents re-embedding identical text chunks on re-ingestion
  - Stored as dict in memory, persisted to Postgres on shutdown

L5 — Semantic cache (pgvector-based):
  - Incoming query → embed → cosine similarity search in cached_responses table
  - Threshold: 0.97 cosine similarity
  - On hit: return cached response (no LLM call)
  - On miss: call LLM, store embedding + response in cache table

PROMPT REGISTRY:
- YAML files in rcm-rag/prompts/ directory
- Schema: id, version (semver), model, template, output_schema, metadata
- metadata includes: purpose, author, created date, eval_scores
  (faithfulness, carc_accuracy, bleu4, rouge_l, cosine_similarity, usefulness_p50)
- PromptRegistry class: loads all YAMLs at startup, resolves by id+version
- If version omitted: returns latest
- Eval harness: runs after any prompt change, writes scores back to YAML metadata
- CI gate: build fails if eval scores regress below thresholds.yaml values

OUTPUT: 3 files. Each: // FILE: path, overview, diagram, key points,
interview talking points, // ===== END OF FILE =====

Make the agent diagram particularly detailed — show state transitions,
the INTERRUPT node clearly marked, and the human-in-the-loop flow.
Make the caching diagram show all 5 layers stacked vertically with
latency estimates and use cases at each layer.
==========================================

# ============================================================
# PROMPT-007: Data Model Diagrams — ERDs + CosmosDB + MongoDB
# ============================================================
# GOAL: All data model diagrams for all 4 stores
# DEPENDS ON: PROMPT-002
# OUTPUT: docs/diagrams/16-erd-rcm-core.md
#         docs/diagrams/17-erd-rag-schema.md
#         docs/diagrams/18-cosmosdb-event-stream.md
#         docs/diagrams/19-mongodb-audit-schema.md
# ACCEPTANCE CRITERIA:
#   1. RCM core ERD shows all 12 tables with columns, PKs, FKs, and tenant_id
#   2. RAG schema ERD shows documents, chunks, embeddings tables
#      with pgvector column type shown
#   3. CosmosDB diagram shows document structure + partition key + indexes
#   4. MongoDB diagram shows collection structure + indexes + retention policy
# ============================================================

PROMPT-007 CONTEXT — paste this into DeepSeek:
==========================================
You are generating data model diagrams for a production-grade RCM platform.
Use ASCII art for all diagrams. Show exact column names, data types, and
constraints as they will appear in the actual database.

DESIGN PRINCIPLES:
- Every Postgres table has: id UUID PK, tenant_id UUID NOT NULL FK,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
- All monetary amounts stored as INTEGER (cents), never DECIMAL
- Soft deletes via deleted_at TIMESTAMPTZ (null = active)
- All enums stored as VARCHAR with CHECK constraints

POSTGRES TABLES — RCM CORE SCHEMA (schema: rcm):

tenants: id, name, subdomain, status, config JSONB, created_at

patients: id, tenant_id, mrn VARCHAR(50), first_name, last_name,
  date_of_birth DATE, ssn_encrypted BYTEA, gender VARCHAR(10),
  address JSONB, phone VARCHAR(20), email VARCHAR(255),
  insurance_info JSONB, created_at, updated_at, deleted_at

payers: id, tenant_id, name, payer_id_external VARCHAR(50),
  payer_type VARCHAR(20), eligibility_endpoint VARCHAR(500),
  claim_endpoint VARCHAR(500), config JSONB, created_at, updated_at

encounters: id, tenant_id, patient_id FK→patients, rendering_provider_npi VARCHAR(10),
  billing_provider_npi VARCHAR(10), facility_npi VARCHAR(10),
  service_date DATE, discharge_date DATE, place_of_service VARCHAR(5),
  encounter_type VARCHAR(20), status VARCHAR(20), notes TEXT,
  created_at, updated_at

claims: id, tenant_id, encounter_id FK→encounters, patient_id FK→patients,
  payer_id FK→payers, claim_type VARCHAR(10), status VARCHAR(30),
  total_charge_cents INTEGER, allowed_amount_cents INTEGER,
  paid_amount_cents INTEGER, patient_responsibility_cents INTEGER,
  scrub_result JSONB, edi_837_raw TEXT, claim_summary TEXT,
  submitted_at TIMESTAMPTZ, adjudicated_at TIMESTAMPTZ,
  created_at, updated_at, deleted_at

claim_lines: id, tenant_id, claim_id FK→claims, line_number INTEGER,
  cpt_code VARCHAR(10), icd10_codes VARCHAR(10)[], modifiers VARCHAR(5)[],
  units INTEGER, charge_cents INTEGER, allowed_cents INTEGER,
  paid_cents INTEGER, revenue_code VARCHAR(4), service_date DATE,
  created_at, updated_at

eligibility_responses: id, tenant_id, patient_id FK→patients,
  payer_id FK→payers, check_date DATE, coverage_active BOOLEAN,
  coverage_start DATE, coverage_end DATE, deductible_cents INTEGER,
  deductible_met_cents INTEGER, out_of_pocket_max_cents INTEGER,
  out_of_pocket_met_cents INTEGER, copay_cents INTEGER, coinsurance_pct DECIMAL,
  raw_271_response TEXT, created_at

payments: id, tenant_id, claim_id FK→claims, era_id FK→eras,
  payment_type VARCHAR(20), amount_cents INTEGER, payment_date DATE,
  check_number VARCHAR(50), eft_trace_number VARCHAR(50), created_at

eras: id, tenant_id, payer_id FK→payers, era_date DATE, total_amount_cents INTEGER,
  check_number VARCHAR(50), raw_835_response TEXT, processed_at TIMESTAMPTZ,
  created_at

denials: id, tenant_id, claim_id FK→claims, denial_date DATE,
  carc_code VARCHAR(10), rarc_code VARCHAR(10), denial_reason TEXT,
  status VARCHAR(30), agent_run_id UUID, explanation TEXT,
  created_at, updated_at

appeals: id, tenant_id, denial_id FK→denials, draft_text TEXT,
  approved_text TEXT, approved_by UUID, approved_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ, outcome VARCHAR(20), outcome_date DATE,
  usefulness_score INTEGER CHECK(1-5), created_at, updated_at

ar_balances: id, tenant_id, patient_id FK→patients, claim_id FK→claims,
  balance_cents INTEGER, aging_bucket VARCHAR(10),
  last_follow_up_at TIMESTAMPTZ, created_at, updated_at

feature_flags: id, tenant_id, flag_name VARCHAR(100), enabled BOOLEAN,
  metadata JSONB, created_at, updated_at

POSTGRES TABLES — RAG SCHEMA (schema: rag):

rag_documents: id UUID, tenant_id UUID, source_type VARCHAR(50),
  source_name VARCHAR(500), payer_id UUID, effective_date DATE,
  expiry_date DATE, content TEXT, metadata JSONB,
  ingested_at TIMESTAMPTZ, embedding_model VARCHAR(100)

rag_chunks: id UUID, tenant_id UUID, document_id FK→rag_documents,
  chunk_index INTEGER, content TEXT, token_count INTEGER,
  metadata JSONB, created_at

rag_embeddings: id UUID, tenant_id UUID, chunk_id FK→rag_chunks,
  embedding vector(1536), model_version VARCHAR(100),
  created_at
  [INDEX: HNSW on embedding using cosine_ops]

cached_llm_responses: id UUID, tenant_id UUID,
  query_hash VARCHAR(64), prompt_version_id VARCHAR(100),
  chunk_ids UUID[], query_embedding vector(1536),
  response_text TEXT, response_metadata JSONB,
  hit_count INTEGER, created_at, last_hit_at

eval_results: id UUID, prompt_id VARCHAR(100), prompt_version VARCHAR(20),
  eval_set VARCHAR(100), run_at TIMESTAMPTZ,
  faithfulness DECIMAL, answer_relevance DECIMAL,
  recall_at_1 DECIMAL, recall_at_3 DECIMAL, recall_at_5 DECIMAL,
  precision_at_5 DECIMAL, mrr DECIMAL, ndcg_at_5 DECIMAL,
  bleu4 DECIMAL, rouge_l DECIMAL, cosine_similarity DECIMAL,
  carc_accuracy DECIMAL, metadata JSONB

agent_states: id UUID, tenant_id UUID, denial_id FK→denials,
  run_id UUID, current_node VARCHAR(50), state JSONB,
  interrupted_at TIMESTAMPTZ, resumed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ, created_at, updated_at

COSMOSDB (NoSQL API) — claim_events container:
Partition key: /claimId
Document structure:
{
  "id": "uuid",
  "claimId": "uuid",
  "tenantId": "uuid",
  "eventType": "eligibility_checked|scrub_passed|scrub_failed|
                submitted_to_clearinghouse|acknowledgement_received|
                adjudicated|payment_posted|denial_received|
                appeal_drafted|appeal_submitted|resolved",
  "timestamp": "ISO8601",
  "payload": { ... event-specific data ... },
  "metadata": { "userId": "uuid", "serviceVersion": "string" },
  "_ttl": 63072000
}
Indexes: eventType, tenantId, timestamp
Change Feed: enabled, consumed by analytics processor

MONGODB — audit_events collection:
{
  "tenantId": "uuid",
  "actorId": "uuid",
  "actorType": "user|service|agent",
  "action": "READ|WRITE|DELETE",
  "entityType": "Patient|Claim|Denial|Appeal|...",
  "entityId": "uuid",
  "timestamp": ISODate,
  "ipAddress": "string",
  "requestId": "uuid",
  "traceId": "string",
  "outcome": "SUCCESS|FAILURE",
  "llmCallId": "uuid|null",
  "agentRunId": "uuid|null"
}
Indexes: { tenantId: 1, timestamp: -1 }, { actorId: 1 }, { entityId: 1 }
TTL index: timestamp, expireAfterSeconds: 220752000 (7 years)
Role: insert-only (enforced via MongoDB role)

OUTPUT: 4 files. Each begins // FILE: path, ends // ===== END OF FILE =====
Show ERDs as ASCII table diagrams with column names, types, and FK arrows.
Show the pgvector column type explicitly (vector(1536)).
Include a "Schema Design Decisions" section in each file with 3-5 points
explaining why the schema is designed the way it is.
Include interview talking points.
==========================================

# ============================================================
# PROMPT-008: UML Class Diagrams
# ============================================================
# GOAL: Domain model class diagrams for RCM, RAG, and Agent domains
# DEPENDS ON: PROMPT-002 PROMPT-007
# OUTPUT: docs/diagrams/20-uml-class-rcm-domain.md
#         docs/diagrams/21-uml-class-rag-domain.md
#         docs/diagrams/22-uml-class-agent-domain.md
# ACCEPTANCE CRITERIA:
#   1. RCM class diagram shows all domain entities with attributes,
#      methods, and relationships (aggregation, composition, association)
#   2. Value objects distinguished from entities (marked differently)
#   3. Aggregate roots clearly marked
#   4. RAG and Agent class diagrams show correct inheritance/composition
# ============================================================

PROMPT-008 CONTEXT — paste this into DeepSeek:
==========================================
You are generating UML class diagrams for a production-grade RCM platform.
Use ASCII art UML notation. Show classes as boxes with three sections:
class name | attributes | methods. Mark stereotypes with <<stereotype>>.

DOMAIN DESIGN PRINCIPLES:
- Aggregate roots marked with <<Aggregate Root>>
- Value objects marked with <<Value Object>>
- Entities marked with <<Entity>>
- Domain events marked with <<Domain Event>>
- Use + for public, - for private, # for protected
- Show cardinality on associations (1, *, 0..1, 1..*)

RCM CORE DOMAIN (Java):
Key classes and relationships:

Patient <<Aggregate Root>>:
  - id: PatientId, tenantId: TenantId, mrn: String
  - demographics: Demographics <<Value Object>>
  - insuranceInfo: InsuranceInfo <<Value Object>>
  + register(), updateDemographics(), addInsurance()

PatientId <<Value Object>>: - value: UUID

Demographics <<Value Object>>: firstName, lastName, dateOfBirth, gender, address, phone, email

InsuranceInfo <<Value Object>>: payerId, memberId, groupNumber, coverageType

Encounter <<Entity>>: id, patientId, renderingProviderNpi, billingProviderNpi,
  serviceDate, placeOfService, status
  + addChargeItem(), submit()

ChargeItem <<Value Object>>: cptCode, diagnosisCodes[], modifiers[], units, chargeAmount

CptCode <<Value Object>>: - code: String (validated format XXXXX)

DiagnosisCode <<Value Object>>: - code: String (ICD-10 format)

Money <<Value Object>>: - amountCents: int, - currency: String
  + add(Money), subtract(Money), multiply(int)

Claim <<Aggregate Root>>:
  - id: ClaimId, tenantId: TenantId, encounterId, patientId, payerId
  - status: ClaimStatus (enum: DRAFT, SCRUBBING, SCRUBBED, SUBMITTED,
    ACKNOWLEDGED, ADJUDICATED, PAID, DENIED, APPEALED, CLOSED)
  - lines: List<ClaimLine>, totalCharge: Money
  - scrubResult: ClaimScrubResult, summary: ClaimSummary
  + scrub(), submit(), markPaid(), deny(), appeal()

ClaimLine <<Entity>>: lineNumber, cptCode, icd10Codes[], modifiers[],
  units, chargeAmount, allowedAmount, paidAmount

ClaimScrubResult <<Value Object>>: passed: boolean, issues: List<ScrubIssue>,
  scrubbedAt: Instant

Denial <<Aggregate Root>>:
  - id: DenialId, claimId: ClaimId, carcCode: CarcCode, rarcCode: RarcCode
  - status: DenialStatus (enum: RECEIVED, TRIAGED, ANALYZED,
    APPEAL_DRAFTED, HUMAN_REVIEW, APPEAL_SUBMITTED, RESOLVED, ESCALATED)
  - appealDraft: AppealDraft, agentRunId: UUID
  + triage(), startAgentAnalysis(), draftAppeal(), approveAppeal(), submit()

CarcCode <<Value Object>>: - code: String, - description: String
RarcCode <<Value Object>>: - code: String, - description: String

AppealDraft <<Value Object>>: draftText, approvedText, approvedBy, approvedAt

RAG DOMAIN (Python):
RagDocument: id, tenantId, sourceType, sourceName, payerId, effectiveDate, content, metadata
RagChunk: id, documentId, chunkIndex, content, tokenCount, metadata
RagEmbedding: id, chunkId, embedding: list[float], modelVersion
RetrievalQuery: tenantId, queryText, queryEmbedding, filters(payerId, dateRange), topK
RetrievalResult: chunks: list[RagChunk], scores: list[float], retrievalLatencyMs
PromptVersion: id, version, model, template, outputSchema, evalScores: EvalScores
EvalScores: faithfulness, answerRelevance, recallAt5, bleu4, rougeL, cosineSimilarity,
  carcAccuracy, usefulnessP50
CachedLlmResponse: queryHash, promptVersionId, chunkIds, queryEmbedding,
  responseText, hitCount
EvalResult: promptId, promptVersion, evalSet, runAt, all metric scores

AGENT DOMAIN (Python/LangGraph):
AgentState (TypedDict): denialId, tenantId, carcCode, rarcCode, claimContext,
  retrievedPolicies, retrievedMedicalNecessity, appealDraft, humanFeedback,
  currentNode, messages, interrupted, agentRunId

AgentNode (abstract): name, + execute(state: AgentState) → AgentState

TriageNode(AgentNode): + classify_denial() → DenialClassification
LookupCarcNode(AgentNode): + lookup_carc_definition()
FetchPayerPolicyNode(AgentNode): + retrieve_payer_policies()
CheckMedicalNecessityNode(AgentNode): + retrieve_medical_necessity_docs()
DraftAppealNode(AgentNode): + assemble_prompt(), + call_llm(), + validate_output()
HumanReviewNode(AgentNode): + interrupt(), + await_approval()
FinalizeNode(AgentNode): + persist_outcome(), + publish_event()

AgentTool (abstract): name, description, + invoke(input) → output
CarcLookupTool(AgentTool), PayerPolicyTool(AgentTool),
MedicalNecessityTool(AgentTool), AppealDraftTool(AgentTool)

DenialResolutionGraph: + compile() → CompiledGraph, + stream(state) → Iterator
AgentStatePersistence: + save(state), + load(runId) → AgentState

OUTPUT: 3 files. Each begins // FILE: path, ends // ===== END OF FILE =====
Show relationships between classes using ASCII notation:
  ──────── association
  ◆─────── composition (diamond at owner end)
  ◇─────── aggregation (open diamond)
  ──────▷  inheritance (open arrow)
Include interview talking points about DDD patterns used.
==========================================
