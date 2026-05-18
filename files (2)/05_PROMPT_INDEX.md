# Section 5 — Master Prompt Index
# Keep this open for the entire project.
# Run prompts IN ORDER. Do not skip. Do not reorder.
#
# COLUMN GUIDE:
#   ID       : prompt filename, also what you say to Claude to get next batch
#   Phase    : which batch this belongs to
#   Goal     : one-line description of what DeepSeek produces
#   Depends  : prompt IDs whose outputs must exist before running this one
#   Output   : files DeepSeek will produce
#   Rigidity : MAX = DeepSeek has no latitude | GUIDED = some latitude allowed
#   Time     : estimated DeepSeek response time + your copy time

---

## BATCH A — Documentation, Diagrams, ADRs (Prompts 001–015)
## Run these first. No code yet. Pure documentation and diagrams.
## After this batch: you can walk any architecture interview question.

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-001 | RCM glossary — every domain term defined | none | `docs/rcm-glossary.md` | MAX | 15 min |
| PROMPT-002 | C4 diagrams L1+L2: system context + containers | 001 | `docs/diagrams/01-c4-system-context.md` `docs/diagrams/02-c4-containers.md` | MAX | 20 min |
| PROMPT-003 | C4 L3 component diagrams: rcm-core + rcm-rag | 002 | `docs/diagrams/03-c4-components-rcm-core.md` `docs/diagrams/04-c4-components-rcm-rag.md` | MAX | 20 min |
| PROMPT-004 | C4 L3 component diagrams: rcm-bff + rcm-notify + deployment diagrams | 002 | `docs/diagrams/05-c4-components-rcm-bff.md` `docs/diagrams/06-c4-components-rcm-notify.md` `docs/diagrams/07-deployment-prod.md` `docs/diagrams/08-deployment-local.md` | MAX | 20 min |
| PROMPT-005 | Security + data flow diagrams: network boundaries, PHI flow, multi-tenancy, observability | 002 | `docs/diagrams/09-network-trust-boundaries.md` `docs/diagrams/10-phi-data-flow.md` `docs/diagrams/11-multi-tenancy.md` `docs/diagrams/12-observability-topology.md` | MAX | 20 min |
| PROMPT-006 | AI architecture diagrams: agent, caching, prompt registry | 002 003 | `docs/diagrams/13-agent-architecture.md` `docs/diagrams/14-caching-architecture.md` `docs/diagrams/15-prompt-registry.md` | MAX | 20 min |
| PROMPT-007 | Data model diagrams: ERDs + CosmosDB + MongoDB schemas | 002 | `docs/diagrams/16-erd-rcm-core.md` `docs/diagrams/17-erd-rag-schema.md` `docs/diagrams/18-cosmosdb-event-stream.md` `docs/diagrams/19-mongodb-audit-schema.md` | MAX | 20 min |
| PROMPT-008 | UML class diagrams: RCM domain + RAG domain + Agent domain | 002 007 | `docs/diagrams/20-uml-class-rcm-domain.md` `docs/diagrams/21-uml-class-rag-domain.md` `docs/diagrams/22-uml-class-agent-domain.md` | MAX | 20 min |
| PROMPT-009 | UML sequence diagrams: eligibility + claim scrubbing gRPC + claim submission Kafka | 002 003 | `docs/diagrams/23-seq-eligibility-verification.md` `docs/diagrams/24-seq-claim-scrubbing-grpc.md` `docs/diagrams/25-seq-claim-submission-kafka.md` | MAX | 20 min |
| PROMPT-010 | UML sequence diagrams: denial agent async + Spring AI + eval run + rate limiting | 002 006 | `docs/diagrams/26-seq-denial-agent-async.md` `docs/diagrams/27-seq-spring-ai-summarization.md` `docs/diagrams/28-seq-rag-eval-run.md` `docs/diagrams/29-seq-rate-limit-enforcement.md` | MAX | 20 min |
| PROMPT-011 | UML state + activity diagrams: claim lifecycle, denial lifecycle, agent execution, biller workflow, scrub decision | 002 008 | `docs/diagrams/30-state-claim-lifecycle.md` `docs/diagrams/31-state-denial-lifecycle.md` `docs/diagrams/32-state-agent-execution.md` `docs/diagrams/33-activity-biller-workflow.md` `docs/diagrams/34-activity-claim-scrub-decision.md` | MAX | 20 min |
| PROMPT-012 | ADRs batch 1: all ARCH decisions (ARCH-01 through ARCH-08) | 001 002 | `docs/adr/ARCH-01` through `docs/adr/ARCH-08` (8 files) | MAX | 25 min |
| PROMPT-013 | ADRs batch 2: all DATA decisions (DATA-01 through DATA-11) | 001 007 | `docs/adr/DATA-01` through `docs/adr/DATA-11` (11 files) | MAX | 25 min |
| PROMPT-014 | ADRs batch 3: all AI + SEC decisions (AI-01 through AI-10, SEC-01 through SEC-07) | 001 006 | `docs/adr/AI-01` through `docs/adr/AI-10` + `docs/adr/SEC-01` through `docs/adr/SEC-07` (17 files) | MAX | 25 min |
| PROMPT-015 | ADRs batch 4 + all guide docs: OPS decisions + architecture-overview + hipaa + multi-tenancy + caching + ai-governance + prompt-engineering + eval-methodology + local-dev-setup + api-conventions + INTERVIEW_PREP skeleton | 001–014 | `docs/adr/OPS-01` through `docs/adr/OPS-07` + 10 guide docs (17 files) | MAX | 30 min |

---

## BATCH B — Contracts and Infrastructure (Prompts 016–030)
## Produces all the "skeleton" files the code will implement against.
## After this batch: docker compose up works (infra only, no app services yet).

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-016 | Protobuf contract: claim_scrubbing.proto (gRPC between rcm-core and rcm-rag) | 001 002 | `proto/rcm/v1/claim_scrubbing.proto` | MAX | 15 min |
| PROMPT-017 | OpenAPI spec: rcm-core REST API (all 7 bounded contexts, full spec) | 001 007 | `docs/rcm-core-openapi.yaml` | MAX | 25 min |
| PROMPT-018 | OpenAPI spec: rcm-rag REST API + GraphQL schema for rcm-bff | 001 006 | `docs/rcm-rag-openapi.yaml` `rcm-bff/src/schema/typeDefs/*.graphql` (6 files) | MAX | 25 min |
| PROMPT-019 | Flyway migrations batch 1: extensions, tenants, patients, encounters, claims, claim_lines | 007 017 | `V001` through `V006` SQL files | MAX | 20 min |
| PROMPT-020 | Flyway migrations batch 2: payers, payments, eras, denials, appeals, ar_balances, feature_flags | 019 | `V007` through `V013` SQL files | MAX | 20 min |
| PROMPT-021 | Flyway migrations batch 3: RAG schema + pgvector indexes + materialized views | 019 020 | `V014` through `V016` SQL files | MAX | 20 min |
| PROMPT-022 | Kafka topic definitions + Avro/JSON event schemas for all 4 topics | 001 009 010 | `infrastructure/kafka/topics.yml` + schema files | MAX | 15 min |
| PROMPT-023 | Seed data batch 1: synthetic patients + payers + CARC/RARC codes | 019 020 | `synthetic-patients.sql` `synthetic-payers.sql` `carc-codes.sql` `rarc-codes.sql` | MAX | 20 min |
| PROMPT-024 | Seed data batch 2: CPT codes + ICD10 codes + synthetic payer policies (RAG corpus) + appeal templates | 019 | `cpt-codes.sql` `icd10-codes.sql` + 4 policy txt files + 3 appeal template txt files | MAX | 20 min |
| PROMPT-025 | docker-compose.yml: full wired local stack (all 15 infrastructure services + 5 app services stubbed) | 001–024 | `infrastructure/docker-compose.yml` `infrastructure/.env.example` | MAX | 25 min |
| PROMPT-026 | Observability configs: Prometheus + Loki + Tempo + Mimir + Grafana provisioning | 025 | All files under `infrastructure/observability/` | MAX | 20 min |
| PROMPT-027 | Grafana dashboards: service-overview + llm-cost + rag-quality + claim-throughput + agent-execution | 026 | 5 dashboard JSON files | MAX | 25 min |
| PROMPT-028 | Terraform stubs: all 6 AWS modules (networking, ecs, rds, elasticache, msk, cosmosdb) | 025 | All files under `infrastructure/terraform/` | MAX | 20 min |
| PROMPT-029 | GitHub Actions CI workflows: all 6 workflow files | 025 | All `.github/workflows/*.yml` files | MAX | 20 min |
| PROMPT-030 | Makefile + root config files: .gitignore + .editorconfig + .gitattributes + .pre-commit-config + commitlint + buf.yaml | 025 | `Makefile` + 6 root config files | MAX | 15 min |

---

## BATCH C1 — rcm-core Spring Boot (Prompts 031–045)
## The Java transactional backbone. One bounded context per prompt where possible.
## Guided latitude: DeepSeek implements against contracts, chooses implementation details.

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-031 | rcm-core: Gradle build files (root + all 8 subprojects) + application entry point + all application.yml variants | 003 017 019–021 | `build.gradle` `settings.gradle` all subproject `build.gradle` files `RcmCoreApplication.java` all `application*.yml` | MAX | 20 min |
| PROMPT-032 | rcm-core common: config classes (Security, JWT, Redis, Kafka, gRPC, SpringAI, Observability) | 031 | 7 config Java files | GUIDED | 25 min |
| PROMPT-033 | rcm-core common: cross-cutting concerns (TenantContext, TenantFilter, HibernateFilter, JwtAuthFilter, InternalContextFilter, PhiAccess annotation) | 031 032 | 6 Java files | GUIDED | 25 min |
| PROMPT-034 | rcm-core common: audit (AuditEvent, AuditService, AuditAspect AOP) + feature flags (FeatureFlag enum, FeatureFlagService, FeatureFlagEntity) + domain events | 031 033 | 9 Java files | GUIDED | 25 min |
| PROMPT-035 | rcm-core common: exception handling (RcmException, TenantIsolationException, GlobalExceptionHandler) + observability (MetricsConfig, TraceConfig) + cache (L1CacheConfig, CacheInvalidationListener) | 031 034 | 7 Java files + TenantIsolationTest + AuditAspectTest | GUIDED | 25 min |
| PROMPT-036 | rcm-core registration bounded context: all domain, repository, service, API, mapper, events, tests | 031–035 017 | ~12 Java files | GUIDED | 30 min |
| PROMPT-037 | rcm-core eligibility bounded context: domain, repository, service, Redis cache, mock payer client, API, tests | 031–035 017 | ~10 Java files | GUIDED | 30 min |
| PROMPT-038 | rcm-core charge-capture bounded context: domain, repository, service, API, tests | 031–035 017 | ~10 Java files | GUIDED | 25 min |
| PROMPT-039 | rcm-core claims bounded context part 1: domain objects + repository + ClaimService + Edi837Builder + ClaimSummaryService (Spring AI) | 031–035 016 017 | ~10 Java files | GUIDED | 30 min |
| PROMPT-040 | rcm-core claims bounded context part 2: ClaimScrubService + ClaimScrubGrpcClient (Resilience4j) + ClaimSubmissionService (Kafka) + CosmosDB event writer + API controller + all tests | 039 016 022 | ~10 Java files | GUIDED | 30 min |
| PROMPT-041 | rcm-core payments bounded context: Edi835Parser + domain + repository + PaymentPostingService + API + tests | 031–035 017 | ~10 Java files | GUIDED | 25 min |
| PROMPT-042 | rcm-core denials bounded context: domain + repository + DenialService + AppealService + Kafka consumers (denial.received + denial.explained) + API + tests | 031–035 017 022 | ~12 Java files | GUIDED | 30 min |
| PROMPT-043 | rcm-core ar bounded context: domain + repository + ArService + API + tests | 031–035 017 | ~8 Java files | GUIDED | 20 min |
| PROMPT-044 | rcm-core logback config + Flyway runner verification + Dockerfile | 031 | `logback-spring.xml` `Dockerfile` `.dockerignore` | MAX | 15 min |
| PROMPT-045 | rcm-core integration tests: Testcontainers setup + PatientControllerIntegrationTest + EligibilityControllerIntegrationTest + ClaimControllerIntegrationTest + Pact consumer test stubs | 036–043 004 | ~5 test Java files | GUIDED | 30 min |

---

## BATCH C2 — rcm-rag FastAPI (Prompts 046–057)
## The Python RAG + agent service. Most technically complex batch.

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-046 | rcm-rag: pyproject.toml + ruff.toml + mypy.ini + main.py + config.py + Dockerfile | 003 018 | 6 files | MAX | 20 min |
| PROMPT-047 | rcm-rag common layer: auth.py + multitenancy.py + audit.py + phi_redactor.py + observability.py + feature_flags.py + exceptions.py | 046 | 7 Python files | GUIDED | 30 min |
| PROMPT-048 | rcm-rag database clients: postgres.py (SQLAlchemy async) + redis_client.py + mongo_client.py + cosmosdb_client.py | 046 047 | 4 Python files | GUIDED | 25 min |
| PROMPT-049 | rcm-rag ingestion pipeline (LlamaIndex): document_loader + chunker + embedder (provider-abstracted) + pgvector_store + faiss_cache + ingestion_pipeline orchestrator | 046–048 016 021 | 6 Python files | GUIDED | 35 min |
| PROMPT-050 | rcm-rag retrieval layer: retriever (hybrid pgvector) + semantic_cache + reranker | 049 | 3 Python files | GUIDED | 25 min |
| PROMPT-051 | rcm-rag prompt registry: registry.py loader + all 4 prompt YAML files (scrubbing, denial-explanation, appeal-drafting, medical-necessity) | 046 | 5 files | MAX | 20 min |
| PROMPT-052 | rcm-rag LLM layer: client.py (provider-abstracted interface) + azure_openai_client.py + ollama_client.py + structured_output.py + token_counter.py | 046 047 051 | 5 Python files | GUIDED | 30 min |
| PROMPT-053 | rcm-rag LLM middleware: budget_middleware.py + rate_limit_middleware.py + token_counting_middleware.py | 052 | 3 Python files | GUIDED | 25 min |
| PROMPT-054 | rcm-rag LangGraph agent: state.py + graph.py + all 7 node files + all 4 tool files + persistence.py | 046–053 | 14 Python files | GUIDED | 40 min |
| PROMPT-055 | rcm-rag flows + gRPC + Kafka: claim_scrubbing.py (gRPC servicer) + denial_explanation.py (Kafka consumer+agent trigger) + grpc servicer + kafka consumer/producer | 049–054 016 022 | 6 Python files | GUIDED | 30 min |
| PROMPT-056 | rcm-rag API routes + schemas: all Pydantic schemas + all FastAPI routers (health, ingestion, retrieval, denial, eval) | 046–055 018 | 9 Python files | GUIDED | 25 min |
| PROMPT-057 | rcm-rag eval harness: runner.py + all 4 metric modules + golden set JSONs + thresholds.yaml + ingest_corpus.py script + all unit + integration + pact tests | 046–056 | ~15 files | GUIDED | 40 min |

---

## BATCH C3 — rcm-notify + rcm-bff Node.js (Prompts 058–063)

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-058 | rcm-notify: package.json + tsconfig + index.ts + config.ts + all common layer files | 004 025 | 7 files | MAX | 20 min |
| PROMPT-059 | rcm-notify: Kafka consumer + all 3 event handlers + all 3 notification channels (email/SMS/webhook) + Handlebars templates + postgres db client + API routes + all tests | 058 022 | ~15 files | GUIDED | 35 min |
| PROMPT-060 | rcm-bff: package.json + tsconfig + index.ts + config.ts + all common layer files (auth, multitenancy, observability, dataloader, errors) | 004 018 025 | 7 files | MAX | 20 min |
| PROMPT-061 | rcm-bff: all GraphQL type definitions (6 .graphql files) + schema/index.ts + all 6 resolvers + DataLoader setup | 060 018 | ~14 files | GUIDED | 35 min |
| PROMPT-062 | rcm-bff: dataSources (RcmCoreApi + RcmRagApi REST clients) + postgres client (mat views) + SSE endpoint + health route | 060 061 | 5 files | GUIDED | 25 min |
| PROMPT-063 | rcm-bff + rcm-notify: Dockerfiles + all tests (unit + integration + Pact consumer) for both services | 058–062 | ~8 files | GUIDED | 30 min |

---

## BATCH C4 — rcm-ui Next.js (Prompts 064–067)

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-064 | rcm-ui: package.json + tsconfig + next.config + tailwind.config + lib layer (auth, graphql-client, sse-client, api) + layout.tsx + root page.tsx | 025 060 | ~8 files | MAX | 20 min |
| PROMPT-065 | rcm-ui: claims screens — ClaimsDashboard + ClaimCard + ClaimStatusBadge + claims/page.tsx + claims/[claimId]/page.tsx + shared components | 064 061 | ~8 files | GUIDED | 30 min |
| PROMPT-066 | rcm-ui: denial screens — DenialQueue + DenialReviewPanel + AppealDraftEditor (SSE streaming) + AgentStepsTimeline + denials/page.tsx + denials/[denialId]/page.tsx | 064 065 062 | ~8 files | GUIDED | 35 min |
| PROMPT-067 | rcm-ui: auth pages (login + callback) + GraphQL queries + Dockerfile + Playwright E2E tests + unit tests | 064–066 | ~8 files | GUIDED | 25 min |

---

## BATCH D — Tests, Observability, Polish (Prompts 068–075)

| ID | Goal | Depends | Output Files | Rigidity | Est. Time |
|---|---|---|---|---|---|
| PROMPT-068 | Pact contract tests: rcm-bff consumer pacts (against rcm-core) + rcm-core Pact provider verification + rcm-rag Pact provider verification | 036–057 060–063 | ~4 test files | GUIDED | 30 min |
| PROMPT-069 | rcm-core Testcontainers integration tests: full suite for claims scrub flow + denial kafka flow + eligibility cache flow | 036–045 | ~3 Java test files | GUIDED | 30 min |
| PROMPT-070 | rcm-rag integration tests: ingestion pipeline + claim scrubbing gRPC + denial Kafka flow + semantic cache (all with Testcontainers) | 046–057 | ~4 Python test files | GUIDED | 30 min |
| PROMPT-071 | Eval harness golden sets: 20 denial explanation cases + 20 claim scrubbing cases (realistic synthetic data with CARC codes, payer policies, expected outputs) | 001 023 024 | 2 JSON golden set files | MAX | 25 min |
| PROMPT-072 | Grafana dashboards finalized: all 5 dashboard JSONs with real metric names from Prometheus configs + alerting rules | 026 027 | 5 dashboard JSON files + 1 alerts file | MAX | 30 min |
| PROMPT-073 | Process docs: PR template + issue templates + CODEOWNERS + CONTRIBUTING.md + sprint plan template + retro template + code review checklist + pre-commit config | 030 | ~8 files | MAX | 20 min |
| PROMPT-074 | INTERVIEW_PREP.md: complete cross-reference of all ADRs by interview question category, with file pointers and talking points | 012–015 | `docs/INTERVIEW_PREP.md` | GUIDED | 30 min |
| PROMPT-075 | README.md: full project README with embedded diagram references, demo instructions, architecture summary, local setup in 5 commands, and project structure overview | 001–074 | `README.md` | GUIDED | 25 min |

---

## QUICK REFERENCE — Running a prompt

1. Open DeepSeek web chat (chat.deepseek.com)
2. Open the prompt file from your `prompts\batch-X\` folder
3. Copy the entire CONTEXT block (between the === lines)
4. Paste into DeepSeek. Press send.
5. Wait for full response.
6. For each file in the response:
   a. Find the `// FILE: path/to/file` header
   b. Copy everything between that header and the next `// ===== END OF FILE =====`
   c. Paste into the correct file in your `rcm-platform\` directory
7. Run `.\verify-scaffold.ps1` to confirm files landed correctly
8. Check the ACCEPTANCE CRITERIA section of the prompt
9. If criteria pass: tick the prompt off this index, move to next
10. If criteria fail: see COMMON FAILURE MODES in the prompt and retry

## QUICK REFERENCE — Session handoff

When stopping for the day, note:
- Last completed prompt ID: PROMPT-0XX
- Next prompt to run: PROMPT-0YY
- Any files that need retry: [list]
- Start next Claude session with:
  "Continuing RCM project. Last completed: PROMPT-0XX.
   Need: PROMPT-0YY. Locked decisions in 01_LOCKED_DECISIONS_v2.md,
   file tree in 02_CANONICAL_FILE_TREE.md."
