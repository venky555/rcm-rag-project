# BATCH A — Prompts 009–015
# Sequence diagrams, state/activity diagrams, all ADRs, all guide docs
# Paste each CONTEXT block directly into DeepSeek web chat.
# ============================================================

# ============================================================
# PROMPT-009: UML Sequence Diagrams — Eligibility + Claim Scrubbing + Claim Submission
# ============================================================
# GOAL: Three sequence diagrams for the three most important sync/async flows
# DEPENDS ON: PROMPT-002 PROMPT-003
# OUTPUT: docs/diagrams/23-seq-eligibility-verification.md
#         docs/diagrams/24-seq-claim-scrubbing-grpc.md
#         docs/diagrams/25-seq-claim-submission-kafka.md
# ACCEPTANCE CRITERIA:
#   1. Eligibility sequence shows Redis cache hit AND miss paths side by side
#   2. Claim scrubbing sequence shows gRPC call with Resilience4j
#      circuit breaker, PHI redaction, and LLM call inside rcm-rag
#   3. Claim submission sequence shows Kafka publish, clearinghouse mock,
#      999 ack, CosmosDB event write at each step
#   4. All sequences show actor, lifelines, activation boxes, return messages
# ============================================================

PROMPT-009 CONTEXT — paste this into DeepSeek:
==========================================
You are generating UML sequence diagrams for a production-grade RCM platform.
Use ASCII art UML sequence diagram notation.

NOTATION GUIDE:
- Actors/participants shown as: Actor  Service  Database
- Lifelines shown as vertical dashed lines: |
- Messages shown as: Actor ──────────────> Service : methodName(params)
- Return messages shown as: Service - - - - - - - -> Actor : return value
- Activation boxes shown as: █ on the lifeline
- Async messages shown as: Service ──────────────> Kafka : publish(event)  [async]
- Notes shown as: Note over Service: text
- Alt/opt/loop boxes shown with: ╔══ alt [condition] ══╗ ... ╚══════════════════╝

SYSTEM PARTICIPANTS (use these exact names):
Biller, rcm-ui, rcm-bff, rcm-core, rcm-rag, rcm-notify,
Keycloak, PostgreSQL, Redis, MongoDB, CosmosDB, Kafka,
PayerSystem (mock), Clearinghouse (mock), AzureOpenAI

SEQUENCE 1: Eligibility Verification (with Redis cache hit/miss)
Flow:
1. Biller clicks "Verify Eligibility" in rcm-ui
2. rcm-ui calls rcm-bff GraphQL query: verifyEligibility(patientId, payerId)
3. rcm-bff resolves via RcmCoreApi REST call: GET /eligibility/verify
4. rcm-core JwtAuthFilter validates token with Keycloak JWKS
5. TenantFilter extracts tenant_id from JWT
6. EligibilityService checks Redis L2 cache
   ALT: cache HIT → return cached response immediately
   ALT: cache MISS →
     a. PayerEligibilityClient sends mock 270 transaction to PayerSystem
     b. PayerSystem returns 271 response
     c. EligibilityService stores in Redis (TTL 24h)
     d. EligibilityResponse saved to PostgreSQL
     e. AuditService writes PHI access event to MongoDB
7. Response flows back: rcm-core → rcm-bff → rcm-ui → Biller
Show both paths clearly with alt box

SEQUENCE 2: Claim Scrubbing via gRPC (sync, latency budget 3s)
Flow:
1. Biller submits claim via rcm-ui
2. rcm-ui → rcm-bff GraphQL mutation: submitClaim(claimInput)
3. rcm-bff → rcm-core REST: POST /claims
4. rcm-core validates JWT + tenant
5. ClaimService creates Claim entity, saves to PostgreSQL
6. ClaimSummaryService calls Spring AI (Azure OpenAI direct from Java)
   to generate claim narrative summary — async, doesn't block
7. ClaimScrubService calls ClaimScrubGrpcClient
8. Resilience4j circuit breaker check:
   ALT: circuit OPEN → return cached/fallback scrub result
   ALT: circuit CLOSED →
     a. gRPC call to rcm-rag: ScrubClaim(ClaimScrubRequest)
     b. rcm-rag ClaimScrubbingFlow receives request
     c. PhiRedactor removes PHI from claim data (Presidio)
     d. HybridRetriever queries PostgreSQL pgvector for relevant payer policies
        (WHERE payer_id = ? AND effective_date <= ? + cosine similarity)
     e. FAISS hot cache checked first (L1 retrieval)
     f. PromptRegistry loads claim-scrubbing-v1.0.0.yaml
     g. LLM client calls Azure OpenAI (gpt-4o-mini)
     h. StructuredOutputValidator validates Pydantic ScrubResult schema
     i. PhiRedactor rehydrates tokens in response
     j. AuditService logs LLM call to MongoDB
     k. gRPC response returned to rcm-core
9. ClaimScrubResult saved to PostgreSQL
10. ClaimEventStreamClient writes scrub_passed/scrub_failed event to CosmosDB
11. Response flows back to Biller
Mark latency at each step (approximate): Redis=1ms, gRPC overhead=5ms,
pgvector query=40ms, LLM call=800ms, total budget=3s

SEQUENCE 3: Claim Submission to Clearinghouse (async via Kafka)
Flow:
1. After scrub passes, ClaimSubmissionService triggers
2. Edi837Builder generates EDI 837P string from Claim entity
3. ClaimEventPublisher publishes claim.submitted event to Kafka
   (payload: claimId, tenantId, edi837String, metadata)
4. CosmosDB: submitted_to_clearinghouse event written
5. rcm-notify Kafka consumer picks up claim.submitted event
6. rcm-notify EmailChannel sends "claim submitted" email to provider
   using claim-submitted.hbs Handlebars template
7. rcm-notify writes to notification_log in PostgreSQL
   [Time passes — hours to days in reality]
8. Clearinghouse mock processes claim, returns 999 acknowledgement
   (success or error)
9. rcm-core receives 999 ack via webhook callback endpoint
10. ClaimService updates claim status (ACKNOWLEDGED or FAILED)
11. CosmosDB: acknowledgement_received event written
12. PostgreSQL: claim status updated
Show the time gap between steps 6 and 8 explicitly with a note

OUTPUT: 3 files. Each begins // FILE: path, ends // ===== END OF FILE =====
Each file: overview, sequence diagram, step-by-step explanation,
latency notes, interview talking points.
==========================================

# ============================================================
# PROMPT-010: UML Sequence Diagrams — Denial Agent + Spring AI + Eval + Rate Limit
# ============================================================
# GOAL: Four sequence diagrams for AI-heavy flows
# DEPENDS ON: PROMPT-002 PROMPT-006
# OUTPUT: docs/diagrams/26-seq-denial-agent-async.md
#         docs/diagrams/27-seq-spring-ai-summarization.md
#         docs/diagrams/28-seq-rag-eval-run.md
#         docs/diagrams/29-seq-rate-limit-enforcement.md
# ACCEPTANCE CRITERIA:
#   1. Denial agent sequence shows full LangGraph flow including
#      INTERRUPT at human_review and resume after biller approval
#   2. Spring AI sequence is simpler — shows in-Java LLM call with no
#      Python service involved
#   3. Eval run sequence shows golden set → pipeline → metrics → YAML update
#   4. Rate limit sequence shows both budget enforcement AND provider rate limiting
# ============================================================

PROMPT-010 CONTEXT — paste this into DeepSeek:
==========================================
You are generating UML sequence diagrams for AI flows in a production-grade
RCM platform. Use ASCII art UML sequence diagram notation (same style as
previous prompts).

PARTICIPANTS: Biller, rcm-ui, rcm-bff, rcm-core, rcm-rag, Kafka,
PostgreSQL, MongoDB, CosmosDB, Redis, AzureOpenAI, EvalHarness

SEQUENCE 1: Denial Resolution Agent (async, human-in-the-loop)
This is the most complex flow. Show it in full detail.

Phase A — Denial ingestion (triggered by 835 ERA processing):
1. Clearinghouse sends 835 ERA to rcm-core webhook
2. Edi835Parser parses ERA, identifies denied claim lines
3. DenialService creates Denial entity in PostgreSQL
4. CosmosDB: denial_received event written
5. DenialReceivedConsumer publishes denial.received to Kafka
   (payload: denialId, tenantId, claimId, carcCode, rarcCode, claimContext)

Phase B — Agent execution (rcm-rag consumes from Kafka):
6. rcm-rag Kafka consumer picks up denial.received
7. DenialExplanationFlow triggers DenialResolutionGraph
8. AgentStatePersistence saves initial state to PostgreSQL (agent_states table)
9. Graph execution begins:
   Node 1 — triage: classifies denial as simple/complex/escalate
   (conditional edge: if escalate → jump to finalize with no LLM)
   Node 2 — lookup_carc: CarcLookupTool queries PostgreSQL CARC table
   (L1 Caffeine cache checked first)
   Node 3 — fetch_payer_policy: PayerPolicyTool does pgvector hybrid search
   (WHERE payer_id = ? AND effective_date <= ? ORDER BY cosine similarity)
   Node 4 — check_medical_necessity: MedicalNecessityTool does pgvector search
   (WHERE cpt_code_family = ?)
   Node 5 — draft_appeal:
     a. PhiRedactor removes PHI from claim context
     b. PromptRegistry loads appeal-drafting-v1.0.0.yaml
     c. BudgetMiddleware checks tenant token budget in Redis
     d. RateLimitMiddleware checks provider rate limits
     e. LLM client calls AzureOpenAI (gpt-4o)
     f. StructuredOutputValidator validates AppealDraft Pydantic schema
     g. PhiRedactor rehydrates tokens
     h. AuditService logs LLM call to MongoDB (actorType: agent)
   Node 6 — human_review: INTERRUPT
     a. AgentStatePersistence saves state to PostgreSQL
     b. Denial record updated: status=APPEAL_DRAFTED, agentRunId saved
     c. CosmosDB: appeal_drafted event written
     d. Kafka: notification.requested published
     e. rcm-notify sends email to biller: "Appeal ready for review"
     [==== EXECUTION SUSPENDED — WAITING FOR HUMAN ====]

Phase C — Human review in UI (could be hours later):
10. Biller opens rcm-ui denial queue
11. rcm-ui → rcm-bff GraphQL query: denial(id) with appealDraft field
12. rcm-bff → rcm-core REST: GET /denials/{id}
13. Biller reads AI-drafted appeal on DenialReviewPanel
14. rcm-ui establishes SSE connection: GET /sse/denial/{id} (via rcm-bff)
15. Biller edits appeal text in AppealDraftEditor
16. Biller clicks Approve
17. rcm-ui → rcm-bff GraphQL mutation: approveAppeal(denialId, approvedText)
18. rcm-bff → rcm-core REST: POST /denials/{id}/approve
19. rcm-core AppealService saves approved text, updates status
20. rcm-core resumes agent: rcm-core → rcm-rag REST: POST /agent/resume/{runId}

Phase D — Agent finalization:
21. rcm-rag AgentStatePersistence loads state from PostgreSQL
22. Graph resumes at finalize node:
    a. Outcome persisted to PostgreSQL (appeals table)
    b. CosmosDB: appeal_submitted event written
    c. Kafka: denial.explained published
23. rcm-core DenialExplainedConsumer picks up denial.explained
24. Denial status updated to APPEAL_SUBMITTED
25. rcm-notify sends confirmation to biller

SEQUENCE 2: Spring AI Claim Summarization (simple, in-Java)
1. ClaimService creates new Claim in PostgreSQL
2. ClaimSummaryService.summarize(claim) called asynchronously
3. Spring AI ChatClient builds prompt from claim fields
4. Spring AI calls Azure OpenAI directly (no rcm-rag involved)
5. Response parsed to ClaimSummary value object
6. summary field updated on Claim entity in PostgreSQL
Total: <2s, fully in Java, no service boundary crossed

SEQUENCE 3: RAG Eval Harness Run (CI-triggered)
1. GitHub Actions triggers rcm-rag-ci.yml
2. Eval runner loads golden_sets/denial_explanation_golden.json (20 cases)
3. For each case:
   a. Run retrieval pipeline → get top-k chunks
   b. Calculate recall@k, precision@k, MRR, NDCG@k (custom metrics)
   c. Run generation pipeline → get LLM response
   d. RAGAS evaluates faithfulness + answer_relevance (calls AzureOpenAI as judge)
   e. evaluate library calculates BLEU-4, ROUGE-L, BERTScore
   f. domain_metrics checks carc_accuracy
4. Aggregate scores calculated
5. Scores compared to thresholds.yaml
6. If any score below threshold: CI FAILS with report
7. If all pass: eval_results written to PostgreSQL eval_results table
8. Prompt YAML metadata updated with new scores
9. HTML report generated to evals/reports/

SEQUENCE 4: Rate Limit + Token Budget Enforcement
Show what happens when a tenant hits their token budget:
1. Request arrives at rcm-rag /denial endpoint
2. TenantBudgetMiddleware: GET {tenantId}:token_budget from Redis
3. ALT: budget EXCEEDED →
   Return HTTP 429, body: {error: "token_budget_exceeded",
   resetAt: "2024-01-15T00:00:00Z", used: 50000, limit: 50000}
   Prometheus counter: llm_budget_exceeded_total{tenant} += 1
4. ALT: budget OK →
   a. ProviderRateLimitMiddleware: check token bucket in Redis
      (Azure OpenAI has 100K TPM limit)
   b. ALT: rate limit HIT → queue request (bounded queue, max 10 items)
      If queue full: return HTTP 429 with retry-after header
   c. ALT: rate limit OK → proceed
   d. LLM call made to AzureOpenAI
   e. TokenCountingMiddleware: count tokens in response (tiktoken)
   f. Redis: INCRBY {tenantId}:tokens_used_today count
   g. Prometheus: llm_tokens_used_total{tenant,model,prompt} += count
   h. Response returned to caller

OUTPUT: 4 files. Each begins // FILE: path, ends // ===== END OF FILE =====
Include: overview, diagram, step explanation, interview talking points.
The denial agent sequence is the crown jewel — make it detailed and complete.
==========================================

# ============================================================
# PROMPT-011: UML State + Activity Diagrams
# ============================================================
# GOAL: All 5 state and activity diagrams
# DEPENDS ON: PROMPT-002 PROMPT-008
# OUTPUT: docs/diagrams/30-state-claim-lifecycle.md
#         docs/diagrams/31-state-denial-lifecycle.md
#         docs/diagrams/32-state-agent-execution.md
#         docs/diagrams/33-activity-biller-workflow.md
#         docs/diagrams/34-activity-claim-scrub-decision.md
# ACCEPTANCE CRITERIA:
#   1. Claim lifecycle state diagram shows all 10 states with
#      valid transitions and trigger events labeled
#   2. Agent execution state diagram maps 1:1 to LangGraph nodes
#   3. Biller activity diagram shows the human workflow from login
#      to approved appeal with decision diamonds
#   4. Scrub decision activity shows the rules engine + RAG combined logic
# ============================================================

PROMPT-011 CONTEXT — paste this into DeepSeek:
==========================================
You are generating UML state diagrams and activity diagrams for a
production-grade RCM platform. Use ASCII art UML notation.

STATE DIAGRAM NOTATION:
- States shown as: [STATE_NAME]
- Initial state: (●) → [FIRST_STATE]
- Final state: [LAST_STATE] → (◎)
- Transitions: [STATE_A] ──event/guard──> [STATE_B]
- Self-transitions: [STATE] ──event──> [STATE]

ACTIVITY DIAGRAM NOTATION:
- Start: (●)
- End: (◎)
- Action: [ action description ]
- Decision: ◇ condition? → yes/no branches
- Fork/Join (parallel): ═══ fork ═══ / ═══ join ═══
- Swimlane: | Actor Name | for each lane

STATE DIAGRAM 1: Claim Lifecycle (30-state-claim-lifecycle.md)
States: DRAFT, SCRUBBING, SCRUB_FAILED, SCRUBBED, SUBMITTED,
ACKNOWLEDGED, ADJUDICATED, PAID, DENIED, APPEALED, CLOSED

Transitions (event → next state):
DRAFT ──claimCreated──> DRAFT (self, adding lines)
DRAFT ──submitForScrubbing──> SCRUBBING
SCRUBBING ──scrubPassed──> SCRUBBED
SCRUBBING ──scrubFailed──> SCRUB_FAILED
SCRUB_FAILED ──corrected──> DRAFT
SCRUB_FAILED ──overridden/[managerApproval]──> SCRUBBED
SCRUBBED ──submitted──> SUBMITTED
SUBMITTED ──ackReceived[success]──> ACKNOWLEDGED
SUBMITTED ──ackReceived[error]──> SCRUB_FAILED
ACKNOWLEDGED ──adjudicated[paid]──> PAID
ACKNOWLEDGED ──adjudicated[denied]──> DENIED
DENIED ──appealFiled──> APPEALED
DENIED ──written off──> CLOSED
APPEALED ──appealAccepted──> PAID
APPEALED ──appealDenied──> CLOSED
PAID ──balanceZero──> CLOSED
Note which states trigger CosmosDB events and which trigger Kafka events

STATE DIAGRAM 2: Denial Lifecycle (31-state-denial-lifecycle.md)
States: RECEIVED, TRIAGED, AGENT_ANALYZING, APPEAL_DRAFTED,
HUMAN_REVIEW, APPEAL_SUBMITTED, RESOLVED, ESCALATED, CLOSED

Transitions:
RECEIVED ──kafkaConsumed──> TRIAGED
TRIAGED ──[simple/complex]──> AGENT_ANALYZING
TRIAGED ──[escalate]──> ESCALATED
AGENT_ANALYZING ──draftComplete──> APPEAL_DRAFTED
APPEAL_DRAFTED ──agentInterrupt──> HUMAN_REVIEW
HUMAN_REVIEW ──billerApproved──> APPEAL_SUBMITTED
HUMAN_REVIEW ──billerRejected──> AGENT_ANALYZING (re-draft)
APPEAL_SUBMITTED ──payer accepted──> RESOLVED
APPEAL_SUBMITTED ──payer denied──> ESCALATED
ESCALATED ──manualResolution──> CLOSED
RESOLVED ──> CLOSED

STATE DIAGRAM 3: LangGraph Agent Execution (32-state-agent-execution.md)
States map 1:1 to LangGraph nodes:
IDLE → TRIAGE → LOOKUP_CARC → FETCH_PAYER_POLICY →
CHECK_MEDICAL_NECESSITY → DRAFT_APPEAL → HUMAN_REVIEW (SUSPENDED) →
FINALIZING → COMPLETED | FAILED | ESCALATED

Show:
- Conditional edge from TRIAGE: [simple/complex] → LOOKUP_CARC,
  [escalate] → FINALIZING
- HUMAN_REVIEW is a persisted interrupted state (show storage symbol)
- Retry edge: HUMAN_REVIEW ──[rejected]──> DRAFT_APPEAL
- Timeout edge: HUMAN_REVIEW ──[48h timeout]──> ESCALATED
- Error edges from any node → FAILED with compensating action

ACTIVITY DIAGRAM 1: Biller Daily Workflow (33-activity-biller-workflow.md)
Swimlanes: Biller | rcm-ui | rcm-bff | rcm-core | rcm-rag

Flow:
1. Biller: Login to rcm-ui
2. rcm-ui/Keycloak: OIDC Authorization Code flow
3. Biller: View Claims Dashboard
4. rcm-bff: GraphQL query aggregates claims from rcm-core
5. Biller: Filter claims by status
6. Decision: Any SCRUB_FAILED claims?
   Yes → Biller opens claim → reviews scrub errors → corrects → resubmits
   No → continue
7. Decision: Any DENIED claims with APPEAL_DRAFTED status?
   Yes → Biller opens denial review panel
       → Reads AI-drafted appeal (SSE stream from rcm-bff)
       → Reviews agent reasoning steps (AgentStepsTimeline)
       → Decision: Approve as-is OR Edit text?
         Edit → Biller modifies in AppealDraftEditor
       → Biller clicks Approve
       → rcm-core: saves approved appeal, resumes agent
       → rcm-rag: finalizes, publishes to Kafka
   No → continue
8. Biller: Review AR Aging Report
9. rcm-bff: GraphQL query reads PostgreSQL materialized view
10. Biller: Mark follow-up actions
11. End of workflow

ACTIVITY DIAGRAM 2: Claim Scrub Decision Tree (34-activity-claim-scrub-decision.md)
This shows the combined rules-engine + RAG logic inside ClaimScrubService:

Decision tree:
1. Receive claim for scrubbing
2. [Rules check] Does claim have required fields? (patient, payer, provider NPI, dates)
   No → FAIL with missing_required_fields
3. [Rules check] Is CPT code valid and active as of service date?
   No → FAIL with invalid_cpt_code
4. [Rules check] Is ICD-10 code valid?
   No → FAIL with invalid_diagnosis_code
5. [Rules check] Does CPT + ICD-10 combination make clinical sense? (CCI edits)
   No → FAIL with medical_necessity_mismatch
6. [RAG check] Feature flag rag.claim-scrubbing enabled?
   No → PASS (rules-only scrub)
   Yes →
     a. Retrieve payer-specific policy chunks via pgvector
        (filter: payer_id, effective_date, cpt_code_family)
     b. Any relevant policies retrieved?
        No → PASS (no payer-specific rules found)
        Yes →
          c. LLM evaluates claim against retrieved policies
          d. LLM returns: PASS, WARN, or FAIL with specific issue
          e. WARN → add warning to scrub result but don't block
          f. FAIL → add issue to scrub result, block submission
7. Aggregate all issues
8. Any blocking issues? → SCRUB_FAILED
9. No blocking issues? → SCRUB_PASSED (with optional warnings)
10. ClaimScrubResult persisted to PostgreSQL
11. CosmosDB event written (scrub_passed or scrub_failed)

OUTPUT: 5 files. Each begins // FILE: path, ends // ===== END OF FILE =====
Include overview, diagram, explanation, and interview talking points.
For state diagrams: note which transitions produce domain events.
For activity diagrams: note where latency matters and why.
==========================================

# ============================================================
# PROMPT-012: ADRs Batch 1 — All ARCH Decisions
# ============================================================
# GOAL: Generate all 8 ARCH ADR markdown files
# DEPENDS ON: PROMPT-001 PROMPT-002
# OUTPUT: docs/adr/ARCH-01 through docs/adr/ARCH-08 (8 files)
# ACCEPTANCE CRITERIA:
#   1. Every ADR follows the exact template with all sections
#   2. Interview talking points section has: one-sentence defense,
#      3 follow-up questions, what a weak answer looks like
#   3. Alternatives considered section names at least 2 real alternatives
#      with honest evaluation of why they lost
#   4. Consequences section is honest about downsides, not just upsides
# ============================================================

PROMPT-012 CONTEXT — paste this into DeepSeek:
==========================================
You are generating Architecture Decision Records (ADRs) for a production-grade
RCM platform. Each ADR must follow the exact template below.

ADR TEMPLATE (use for every ADR):
---
# ADR-[ID]: [Short Title]
**Status:** Accepted
**Date:** 2025-01-15
**Deciders:** RCM Platform Team

## Context
[2-3 paragraphs: what problem needed solving, what constraints existed,
what options were on the table]

## Decision
[Precise statement of what was decided — no ambiguity]

## Rationale
[Why this option over the alternatives — specific, not generic]

## Alternatives Considered
### Alternative 1: [Name]
[What it is, why it was rejected — be honest]
### Alternative 2: [Name]
[What it is, why it was rejected — be honest]

## Consequences
### Positive
- [specific benefit]
### Negative / Trade-offs
- [specific cost or limitation — be honest about downsides]

## Interview Talking Point
**One-sentence defense:**
"[The sentence]"

**Follow-up questions to prepare for:**
1. [Question an interviewer would ask]
2. [Question an interviewer would ask]
3. [Question an interviewer would ask]

**What a weak answer looks like (avoid this):**
"[Example of a vague or wrong answer]"
---

DECISIONS TO DOCUMENT (generate all 8 as separate files):

ARCH-01 (docs/adr/ARCH-01-polyglot-topology.md):
Decision: 5 services — Spring Boot (Java), FastAPI (Python), Express notify (Node),
Apollo BFF (Node), Next.js UI. Each justified by genuine polyglot reason.
Java for transactional core, Python for AI ecosystem, Node for I/O-bound notification
and GraphQL BFF aggregation.
Alternatives: All-Java (Spring Boot + Spring AI), All-Python (FastAPI everywhere)

ARCH-02 (docs/adr/ARCH-02-modular-monolith.md):
Decision: rcm-core is one deployable JAR with 7 Gradle subprojects (bounded contexts).
Contexts communicate in-process. Module boundaries don't equal deployment boundaries.
Alternatives: 7 microservices (one per RCM stage), single-module monolith

ARCH-03 (docs/adr/ARCH-03-protocol-choices.md):
Decision: REST for external/CRUD APIs (rcm-core), GraphQL for BFF aggregation (rcm-bff),
gRPC for internal high-frequency sync (rcm-core→rcm-rag claim scrubbing),
Kafka for genuinely async flows.
Alternatives: REST everywhere, gRPC everywhere, GraphQL everywhere

ARCH-04 (docs/adr/ARCH-04-kafka-async-flows.md):
Decision: Kafka for exactly 4 topics (claim.submitted, denial.received,
denial.explained, notification.requested). Everything else is sync.
Alternatives: RabbitMQ, HTTP callbacks, polling

ARCH-05 (docs/adr/ARCH-05-no-api-gateway.md):
Decision: No API gateway in v1. BFF handles aggregation. Gateway designed for v2
when cross-service concerns (WAF, centralized rate limiting) justify it.
Alternatives: Kong, AWS API Gateway, Spring Cloud Gateway from day one

ARCH-06 (docs/adr/ARCH-06-multi-tenancy.md):
Decision: Shared schema with tenant_id discriminator enforced at ORM layer
(Hibernate @Filter + SQLAlchemy before_compile). Every table, every query.
Alternatives: Schema-per-tenant, Database-per-tenant, no multi-tenancy now

ARCH-07 (docs/adr/ARCH-07-resilience-patterns.md):
Decision: Resilience4j (Java) + Tenacity (Python) for all outbound calls.
Specific timeouts and circuit breaker settings for each call type.
LLM calls get 30s timeout + circuit breaker. Scrubbing calls get 3s timeout.
Alternatives: Manual try/catch, Hystrix (deprecated), no resilience patterns

ARCH-08 (docs/adr/ARCH-08-human-in-the-loop.md):
Decision: No LLM output reaches external parties without human approval.
LangGraph INTERRUPT node at human_review. State persisted to Postgres.
Biller reviews in UI, approves/edits, then agent finalizes.
Alternatives: Fully automated (no human checkpoint), approval via email only

Each ADR goes in its own file. Format:
// FILE: docs/adr/ARCH-XX-name.md
[full ADR content]
// ===== END OF FILE =====
==========================================

# ============================================================
# PROMPT-013: ADRs Batch 2 — All DATA Decisions
# ============================================================
# GOAL: Generate all 11 DATA ADR markdown files
# DEPENDS ON: PROMPT-001 PROMPT-007
# OUTPUT: docs/adr/DATA-01 through docs/adr/DATA-11 (11 files)
# ACCEPTANCE CRITERIA: Same as PROMPT-012
# ============================================================

PROMPT-013 CONTEXT — paste this into DeepSeek:
==========================================
You are generating Architecture Decision Records (ADRs) for data decisions
in a production-grade RCM platform. Use the same ADR template as ARCH ADRs.

[Paste the ADR template from PROMPT-012 here]

DATA DECISIONS TO DOCUMENT:

DATA-01 (docs/adr/DATA-01-four-data-stores.md):
Decision: 4 stores with distinct jobs. PostgreSQL+pgvector (transactional + vector),
MongoDB (PHI audit log), CosmosDB NoSQL (claim event stream + Change Feed),
Redis (L2 cache + rate limits). Each store chosen for its access pattern.
Alternatives: PostgreSQL only (everything in one DB), PostgreSQL + Redis only

DATA-02 (docs/adr/DATA-02-pgvector-retrieval.md):
Decision: pgvector as primary vector store. HNSW indexes. Hybrid SQL+vector queries.
Justification: RCM retrieval is FILTERED vector search (by payer, date, code family).
pgvector wins for filtered search at single-digit-million vector scale.
Alternatives: Pinecone, ChromaDB, Weaviate, Qdrant, dedicated vector DB

DATA-03 (docs/adr/DATA-03-cosmosdb-event-stream.md):
Decision: CosmosDB NoSQL API for claim processing event stream.
Partition key: claimId. Change Feed for analytics pipeline.
Justification: High-write append-only events, natural partition key,
Change Feed is native CosmosDB feature, global distribution if needed.
Alternatives: PostgreSQL event table, MongoDB, Kafka as event store (Kafka is messaging not storage)

DATA-04 (docs/adr/DATA-04-faiss-hot-cache.md):
Decision: FAISS as in-process hot cache for highest-QPS retrieval path.
Rebuilt from pgvector at service start. pgvector is source of truth.
This is a library (not a database) used as an in-memory index.
Alternatives: Keep all retrieval in pgvector, use Redis for vector cache,
use Annoy instead of FAISS

DATA-05 (docs/adr/DATA-05-mongodb-audit-log.md):
Decision: MongoDB 7 for PHI access audit log. Append-only.
Insert-only role at database level. 7-year retention. Indexed by tenantId + timestamp.
Justification: Audit events are append-only, schema-flexible per event type,
queried by filter — textbook document store workload.
Alternatives: PostgreSQL audit table, Elasticsearch, Splunk, file-based audit log

DATA-06 (docs/adr/DATA-06-redis-cache.md):
Decision: Redis 7 for exactly 3 things: eligibility responses (TTL 24h),
LLM response cache (TTL 7d), rate limit counters (TTL 2min).
Justification: These 3 need cross-instance shared state with TTL.
Alternatives: Memcached, in-process cache only, database-backed cache

DATA-07 (docs/adr/DATA-07-caffeine-l1-cache.md):
Decision: Caffeine (Java) + cachetools (Python) for L1 in-process cache.
CPT/ICD10, CARC/RARC, payer metadata, prompt templates. Loaded at startup.
Invalidated via Redis pub/sub on change.
Alternatives: Redis for everything, Guava Cache, EHCache

DATA-08 (docs/adr/DATA-08-materialized-views.md):
Decision: PostgreSQL materialized views refreshed nightly via pg_cron.
AR aging, denial rate by payer, claim throughput, cache hit rates.
Read by reporting endpoints. No real-time analytics on transactional tables.
Alternatives: Real-time aggregation queries, separate analytics database (BigQuery, Redshift)

DATA-09 (docs/adr/DATA-09-flyway-migrations.md):
Decision: Flyway for all Postgres schema changes. SQL-first. Numbered files.
Immutable once merged. Run at service startup.
Alternatives: Liquibase, manual migrations, JPA DDL auto-generation

DATA-10 (docs/adr/DATA-10-embedding-model.md):
Decision: Azure OpenAI text-embedding-3-small (prod, under BAA) +
BAAI/bge-small-en-v1.5 via sentence-transformers (dev, offline).
Dimension difference (1536 vs 384) handled via Flyway profile.
Model version stored with each embedding vector.
Alternatives: OpenAI standard API (no BAA available), self-hosted only, Cohere Embed

DATA-11 (docs/adr/DATA-11-llm-provider.md):
Decision: Azure OpenAI gpt-4o (agent) + gpt-4o-mini (classification) in prod.
Ollama Llama-3-8B (dev). Recorded response mock (tests).
Provider is an interface, implementation is config-selected.
DeepSeek generates the code; Azure OpenAI runs it.
Alternatives: OpenAI direct (no HIPAA BAA), Anthropic Claude, self-hosted only,
single provider no abstraction

Each ADR in its own file. Format:
// FILE: docs/adr/DATA-XX-name.md
[full ADR]
// ===== END OF FILE =====
==========================================

# ============================================================
# PROMPT-014: ADRs Batch 3 — All AI + SEC Decisions
# ============================================================
# GOAL: Generate all 17 AI and SEC ADR files
# DEPENDS ON: PROMPT-001 PROMPT-006
# OUTPUT: docs/adr/AI-01 through AI-10 + SEC-01 through SEC-07 (17 files)
# ACCEPTANCE CRITERIA: Same as PROMPT-012
# ============================================================

PROMPT-014 CONTEXT — paste this into DeepSeek:
==========================================
You are generating Architecture Decision Records for AI and Security decisions
in a production-grade RCM platform. Use the same ADR template as previous ADRs.

[Paste the ADR template from PROMPT-012 here]

AI DECISIONS TO DOCUMENT:

AI-01 (docs/adr/AI-01-llamaindex-langchain.md):
Decision: LlamaIndex for ingestion pipeline (document loading, semantic chunking,
embedding, pgvector upsert). LangChain+LangGraph for runtime orchestration
(prompt assembly, tool calling, agent state machine).
Justification: Each framework excels at its designated job.
LlamaIndex has richer loaders and smarter chunking. LangChain has better agent primitives.
Alternatives: LlamaIndex for everything, LangChain for everything, raw OpenAI SDK

AI-02 (docs/adr/AI-02-langgraph-agent.md):
Decision: LangGraph state machine for denial resolution agent. 7 nodes, 4 tools,
conditional edges, INTERRUPT at human_review, durable state in Postgres.
Justification: Graph-based > ReAct loops for production (debuggable, constrainable,
human-in-the-loop support).
Alternatives: ReAct loop, OpenAI Assistants API, CrewAI, AutoGen

AI-03 (docs/adr/AI-03-phi-redaction.md):
Decision: Microsoft Presidio runs on every prompt before it leaves the service.
PHI replaced with typed tokens. Rehydrated after LLM response.
Even with BAA, minimize PHI in LLM calls (defense in depth).
Alternatives: No redaction (BAA-only), field-level filtering, regex-based masking

AI-04 (docs/adr/AI-04-prompt-registry.md):
Decision: Prompts as YAML files with semver, tracked eval scores, Pydantic output schema refs.
Eval harness writes scores back to YAML. CI fails on regression.
Alternatives: Prompts in code (string literals), prompts in database, LangSmith hosted

AI-05 (docs/adr/AI-05-structured-outputs.md):
Decision: OpenAI function calling / structured output mode with Pydantic schemas.
Validate on receipt. Retry once with correction prompt on failure.
Return typed LLMFailureResponse on second failure.
Alternatives: Free-text parsing with regex, no validation, always retry 3x

AI-06 (docs/adr/AI-06-spring-ai.md):
Decision: Spring AI for one in-Java LLM flow (claim narrative summarization).
Justification: Simple prompt-only flow, latency-sensitive, no RAG infrastructure needed.
Adding service boundary for a single LLM call adds latency with no benefit.
Alternatives: All AI in Python service, Java calls Python via REST for everything

AI-07 (docs/adr/AI-07-feature-flags.md):
Decision: Postgres-backed feature flags with L1 cache + Redis pub/sub invalidation.
Every AI feature gated. Flip takes seconds in prod. 50-line abstraction not a vendor.
Alternatives: Unleash, LaunchDarkly, hardcoded config booleans, environment variables

AI-08 (docs/adr/AI-08-eval-metrics.md):
Decision: 4-layer eval: retrieval (recall@k, precision@k, MRR, NDCG, hit_rate, context_relevance),
generation (faithfulness, answer_relevance, BLEU-4, ROUGE-L, cosine similarity, BERTScore),
domain (carc_accuracy, usefulness_score, appeal_acceptance_rate),
operational (latency p50/p95/p99, tokens, cache hit rate, agent steps, hallucination rate).
Alternatives: BLEU only, manual evaluation, no evaluation

AI-09 (docs/adr/AI-09-semantic-cache.md):
Decision: Two-tier LLM cache: exact (Redis, keyed by hash) +
semantic (pgvector, 0.97 cosine threshold). Semantic cache gets 50-70% hit rate vs 20% exact.
Threshold is a business decision (tuned via eval harness).
Alternatives: Exact cache only, no cache, GPTCache library

AI-10 (docs/adr/AI-10-token-budget.md):
Decision: BudgetMiddleware (per-tenant daily budget) + RateLimitMiddleware (provider TPM/RPM).
Two separate concerns: tenant economics vs provider limits.
Prometheus metrics for both. 429 responses with reset-at timestamp.
Alternatives: No budget control, single rate limiter for both concerns,
quota enforced at billing level only

SECURITY DECISIONS TO DOCUMENT:

SEC-01 (docs/adr/SEC-01-oidc-keycloak.md):
Decision: OAuth2/OIDC via Keycloak. Authorization Code + PKCE for UI.
Client Credentials for service-to-service. RS256 JWT. JWKS endpoint validation.
Alternatives: HS256 shared secret, API keys, Basic auth, Auth0, Okta

SEC-02 (docs/adr/SEC-02-no-token-propagation.md):
Decision: Services present their own Client Credentials token to other services.
User identity travels as signed internal header (X-Internal-Context).
User token not forwarded.
Alternatives: Forward user token to all internal services, no service-to-service auth

SEC-03 (docs/adr/SEC-03-phi-encryption.md):
Decision: PHI columns encrypted at rest via pgcrypto (symmetric, key from Secrets Manager).
TLS 1.3 in transit. PHI redacted in LLM calls. Log masking on all services.
PHI encrypted in Kafka messages.
Alternatives: Database-level encryption only (TDE), no column-level encryption,
application-level encryption with different keys per field

SEC-04 (docs/adr/SEC-04-row-level-security.md):
Decision: Hibernate @Filter (Java) + SQLAlchemy before_compile (Python) +
pg middleware (Node.js) enforce tenant_id on every query.
TenantIsolationTest verifies isolation on every PR.
Alternatives: Manual WHERE clause in every query, Postgres Row-Level Security policies,
separate schemas

SEC-05 (docs/adr/SEC-05-secrets-management.md):
Decision: .env.example checked in, .env git-ignored, docker-compose loads from .env.
Prod: AWS Secrets Manager loaded at startup. Application code reads from env vars only.
Alternatives: HashiCorp Vault, k8s Secrets, secrets in config files, secrets in code

SEC-06 (docs/adr/SEC-06-hipaa-audit-log.md):
Decision: AOP @Around advice (Java) + FastAPI dependency (Python) write MongoDB audit events
on every PHI access. Developers annotate @PhiAccess, framework writes the event.
Alternatives: Manual audit calls in every method, database triggers, external audit service

SEC-07 (docs/adr/SEC-07-input-validation.md):
Decision: 3-layer validation: API boundary (Bean Validation/Pydantic/Zod),
domain layer (invariant checks in domain objects), database (Postgres CHECK constraints).
Each layer independently correct.
Alternatives: API boundary only, database only, no validation

Each ADR in its own file:
// FILE: docs/adr/XX-XX-name.md
[full ADR]
// ===== END OF FILE =====
==========================================

# ============================================================
# PROMPT-015: ADRs Batch 4 (OPS) + All 10 Guide Documents
# ============================================================
# GOAL: 7 OPS ADRs + 10 guide documents + INTERVIEW_PREP skeleton
# DEPENDS ON: PROMPT-001 through PROMPT-014
# OUTPUT: docs/adr/OPS-01 through OPS-07 (7 files)
#         docs/architecture-overview.md
#         docs/hipaa-security-guide.md
#         docs/multi-tenancy-guide.md
#         docs/caching-strategy.md
#         docs/ai-governance.md
#         docs/prompt-engineering-guide.md
#         docs/eval-methodology.md
#         docs/local-dev-setup.md
#         docs/api-conventions.md
#         docs/INTERVIEW_PREP.md (skeleton only — filled in PROMPT-074)
# ACCEPTANCE CRITERIA:
#   1. All 7 OPS ADRs follow the template
#   2. local-dev-setup.md has step-by-step setup that works on Windows
#      with PowerShell commands
#   3. api-conventions.md covers REST conventions, GraphQL conventions,
#      gRPC conventions, and error response formats for all three
#   4. INTERVIEW_PREP.md skeleton has all section headings populated
#      but content marked as TODO — PROMPT-074 fills it
# ============================================================

PROMPT-015 CONTEXT — paste this into DeepSeek:
==========================================
You are generating the final documentation batch for a production-grade
RCM platform. This includes OPS ADRs and all guide documents.

[Paste the ADR template from PROMPT-012 here]

OPS DECISIONS TO DOCUMENT (follow ADR template):

OPS-01 (docs/adr/OPS-01-observability-triad.md):
Decision: Structured JSON logs (Logback/structlog/pino) + Prometheus metrics
(Micrometer/prometheus-client/prom-client) + OpenTelemetry traces (all 5 services).
W3C Trace Context in HTTP headers, Kafka message headers, gRPC metadata.
Cross-service traces are the key operational capability.
Alternatives: Logging only, APM vendor (Datadog/New Relic), manual correlation IDs

OPS-02 (docs/adr/OPS-02-lgtm-stack.md):
Decision: Grafana LGTM stack locally (Loki + Grafana + Tempo + Mimir).
Pre-provisioned dashboards as code. No manual Grafana setup after docker compose up.
5 dashboards: service overview, LLM cost, RAG quality, claim throughput, agent execution.
Alternatives: ELK stack, Datadog, CloudWatch only, no local observability

OPS-03 (docs/adr/OPS-03-testcontainers.md):
Decision: Testcontainers for all integration tests (Java, Python, Node.js).
Real Postgres, Kafka, Redis, MongoDB, Keycloak in containers for every integration test.
No H2, no mocked Kafka, no faked Redis.
Alternatives: H2 in-memory, WireMock, embedded Kafka (EmbeddedKafkaRule)

OPS-04 (docs/adr/OPS-04-pact-contracts.md):
Decision: Consumer-driven contract tests via Pact for all synchronous boundaries.
rcm-bff consumes rcm-core. rcm-core consumes rcm-rag (gRPC + REST).
Pact verification runs in CI and blocks PR merge on failure.
Alternatives: Integration tests only, shared Postman collections, OpenAPI diff only

OPS-05 (docs/adr/OPS-05-github-actions.md):
Decision: 6 GitHub Actions workflows. One per service (build+test+containerize+push GHCR)
+ shared contract-tests.yml. Deploy step written but commented out.
Alternatives: Jenkins, CircleCI, GitLab CI, manual deployment

OPS-06 (docs/adr/OPS-06-docker-compose.md):
Decision: docker-compose.yml at repo root. Single command: docker compose up --build.
All 15 infra services + 5 app services. Terraform stubs document prod target.
Alternatives: Skaffold, Tilt, Minikube, manual startup scripts

OPS-07 (docs/adr/OPS-07-feature-flags-ops.md):
Decision: Postgres-backed flags with L1 cache + Redis pub/sub invalidation.
3 clients (Java, Python, Node.js) sharing same interface. Flip takes <1s.
Alternatives: Environment variable feature flags, config file flags,
Unleash OSS, LaunchDarkly

--- GUIDE DOCUMENTS ---

docs/architecture-overview.md:
- 1-page executive summary of the system
- Technology choices table (service → language → framework → why)
- Key architectural principles (5-7 bullet points)
- Links to all diagram files
- Links to all ADRs
- "Getting started" pointer to local-dev-setup.md

docs/hipaa-security-guide.md:
- PHI classification: what counts as PHI in this system
- How PHI is protected at rest (pgcrypto, CosmosDB encryption)
- How PHI is protected in transit (TLS 1.3, mTLS)
- How PHI is protected in AI calls (Presidio redaction + rehydration)
- Audit logging: what gets logged, where, how long retained
- Access control: RBAC roles (Biller, Admin, Service), what each can do
- BAA requirements: which providers need BAAs and why
- Incident response: what to do if PHI is exposed
- HIPAA compliance checklist: 10 items with where each is implemented

docs/multi-tenancy-guide.md:
- Design choice: shared schema with tenant discriminator
- How tenant_id flows from JWT → middleware → ORM → query
- Code examples (pseudocode) showing Hibernate @Filter and SQLAlchemy event
- How tenant isolation is tested (TenantIsolationTest)
- How to add a new tenant (operational runbook)
- How to promote a tenant to dedicated schema (future path)
- Tenant data boundaries: what data is shared vs isolated

docs/caching-strategy.md:
- The 5-layer cache hierarchy diagram (text version)
- L1: Caffeine/cachetools — what's cached, sizing, invalidation
- L2: Redis — 3 specific uses, TTLs, key naming convention
- L3: Postgres materialized views — what views, refresh schedule
- L4: Embedding cache — how it works, persistence
- L5: Semantic cache — threshold selection, implementation
- Cache invalidation strategies per layer
- What to monitor: cache hit rates by layer, latency impact

docs/ai-governance.md:
- Model cards for each LLM used (Azure OpenAI gpt-4o, gpt-4o-mini)
- Risk register: hallucination risk, bias risk, privacy risk (per use case)
- Human-in-the-loop policy: when required, when optional
- PHI in AI calls: policy and implementation
- Prompt versioning and change management process
- Eval gates: what must pass before a new prompt version goes to prod
- Incident response for AI failures (hallucination in production, etc.)
- Compliance notes: HIPAA implications of AI-generated clinical content

docs/prompt-engineering-guide.md:
- Prompt structure used in this system (system/user/assistant roles)
- The 4 prompts in the registry and their design rationale
- Chain-of-thought usage: where and why
- Structured output techniques: function calling vs JSON mode
- Few-shot examples: where used (carc lookup, appeal drafting)
- PHI redaction impact on prompt quality: how to write prompts
  that work with redacted PHI tokens
- Prompt testing: how to iterate using the eval harness
- Common prompt engineering mistakes to avoid in healthcare AI

docs/eval-methodology.md:
- The 4 evaluation layers explained
- How to create a golden set (what makes a good test case)
- Running the eval harness (commands)
- Interpreting results: what each metric means for RCM
- Threshold selection rationale (why 0.85 faithfulness, why 0.80 carc_accuracy)
- How to handle eval set contamination
- CI integration: how evals gate prompt changes
- Continuous eval in production: usefulness scores from billers

docs/local-dev-setup.md:
Prerequisites:
- Docker Desktop 4.34+ with at least 8GB RAM allocated
- Git 2.46+
- Java 21 (use SDKMAN or Adoptium)
- Python 3.12 (use pyenv or official installer)
- Node.js 20 LTS (use nvm-windows or official installer)
- PowerShell 7+ (pwsh)

Step-by-step setup (PowerShell commands):
1. Clone repo
2. Run scaffold.ps1 (if not already run)
3. Copy .env.example to .env and fill in required values (list each value)
4. Start infrastructure only: docker compose up postgres mongo redis kafka keycloak
5. Run Flyway migrations: ./gradlew :app:flywayMigrate
6. Ingest RAG corpus: python rcm-rag/scripts/ingest_corpus.py
7. Start all services: docker compose up --build
8. Verify: curl http://localhost:8081/actuator/health
9. Open Grafana: http://localhost:3001 (admin/admin)
10. Open rcm-ui: http://localhost:3000

Common issues and fixes (at least 5)

docs/api-conventions.md:
REST conventions:
- URL naming: plural nouns, kebab-case (/claim-lines not /claimLines)
- HTTP methods: GET/POST/PUT/PATCH/DELETE semantics
- Status codes: which codes used and when
- Pagination: cursor-based (not offset), response envelope format
- Error response format: {code, message, details[], traceId, timestamp}
- Versioning: URI versioning (/v1/) for external APIs
- Authentication: Bearer token in Authorization header
- Tenant context: extracted from JWT, never in URL

GraphQL conventions:
- Naming: camelCase fields, PascalCase types
- Error handling: GraphQL errors vs partial data
- Pagination: Relay cursor connections
- N+1 prevention: DataLoader mandatory for list fields
- Authentication: same JWT Bearer, validated in context function

gRPC conventions:
- Proto style: snake_case fields, PascalCase messages and services
- Error codes: map to gRPC status codes
- Deadlines: always set, match to service SLAs
- Metadata: tenant_id and trace_id in every call

docs/INTERVIEW_PREP.md (skeleton only):
Create the file with these section headings and TODO markers:
# Interview Prep Guide — RCM Platform
## System Design Questions — TODO (generated by PROMPT-074)
## AI/ML and RAG Questions — TODO
## Data Architecture Questions — TODO
## Security and Compliance Questions — TODO
## Scalability Questions — TODO
## Protocol Choice Questions (REST vs GraphQL vs gRPC) — TODO
## Process and Agile Questions — TODO
## Quick Reference: Question → ADR → File — TODO

Each file: // FILE: path, // ===== END OF FILE =====
Guide documents should be comprehensive — 3-5 pages each.
ADRs follow the strict template.
==========================================
