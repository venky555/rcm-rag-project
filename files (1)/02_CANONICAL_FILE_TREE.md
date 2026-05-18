# Section 2 — Canonical File Tree
# STATUS: LOCKED after sign-off on 01_LOCKED_DECISIONS_v2.md
#
# This is the exact directory structure of the final repo.
# Every DeepSeek prompt references paths from this tree.
# DeepSeek must not invent directories or rename files.
# If a prompt needs a file not listed here, STOP and flag it.
#
# Legend:
#   [J]  = Java/Spring Boot (rcm-core)
#   [P]  = Python/FastAPI (rcm-rag)
#   [N]  = Node.js/Express (rcm-notify, rcm-bff)
#   [U]  = Next.js UI (rcm-ui)
#   [I]  = Infrastructure / shared
#   [D]  = Documentation
#   [*]  = Generated (do not hand-edit)

rcm-platform/                                        [I] repo root
│
├── .github/
│   ├── workflows/
│   │   ├── rcm-core-ci.yml                          [I] Java service CI
│   │   ├── rcm-rag-ci.yml                           [I] Python service CI
│   │   ├── rcm-notify-ci.yml                        [I] Notify service CI
│   │   ├── rcm-bff-ci.yml                           [I] BFF service CI
│   │   ├── rcm-ui-ci.yml                            [I] UI CI
│   │   └── contract-tests.yml                       [I] Pact contract tests
│   ├── PULL_REQUEST_TEMPLATE.md                     [D]
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md                            [D]
│   │   └── feature_request.md                       [D]
│   └── CODEOWNERS                                   [I]
│
├── docs/
│   ├── adr/                                         [D] Architecture Decision Records
│   │   ├── ARCH-01-polyglot-topology.md
│   │   ├── ARCH-02-modular-monolith.md
│   │   ├── ARCH-03-protocol-choices.md
│   │   ├── ARCH-04-kafka-async-flows.md
│   │   ├── ARCH-05-no-api-gateway.md
│   │   ├── ARCH-06-multi-tenancy.md
│   │   ├── ARCH-07-resilience-patterns.md
│   │   ├── ARCH-08-human-in-the-loop.md
│   │   ├── DATA-01-four-data-stores.md
│   │   ├── DATA-02-pgvector-retrieval.md
│   │   ├── DATA-03-cosmosdb-event-stream.md
│   │   ├── DATA-04-faiss-hot-cache.md
│   │   ├── DATA-05-mongodb-audit-log.md
│   │   ├── DATA-06-redis-cache.md
│   │   ├── DATA-07-caffeine-l1-cache.md
│   │   ├── DATA-08-materialized-views.md
│   │   ├── DATA-09-flyway-migrations.md
│   │   ├── DATA-10-embedding-model.md
│   │   ├── DATA-11-llm-provider.md
│   │   ├── AI-01-llamaindex-langchain.md
│   │   ├── AI-02-langgraph-agent.md
│   │   ├── AI-03-phi-redaction.md
│   │   ├── AI-04-prompt-registry.md
│   │   ├── AI-05-structured-outputs.md
│   │   ├── AI-06-spring-ai.md
│   │   ├── AI-07-feature-flags.md
│   │   ├── AI-08-eval-metrics.md
│   │   ├── AI-09-semantic-cache.md
│   │   ├── AI-10-token-budget.md
│   │   ├── SEC-01-oidc-keycloak.md
│   │   ├── SEC-02-no-token-propagation.md
│   │   ├── SEC-03-phi-encryption.md
│   │   ├── SEC-04-row-level-security.md
│   │   ├── SEC-05-secrets-management.md
│   │   ├── SEC-06-hipaa-audit-log.md
│   │   ├── SEC-07-input-validation.md
│   │   ├── OPS-01-observability-triad.md
│   │   ├── OPS-02-lgtm-stack.md
│   │   ├── OPS-03-testcontainers.md
│   │   ├── OPS-04-pact-contracts.md
│   │   ├── OPS-05-github-actions.md
│   │   ├── OPS-06-docker-compose.md
│   │   └── OPS-07-feature-flags-ops.md
│   │
│   ├── diagrams/                                    [D] All 34 architecture diagrams
│   │   ├── 01-c4-system-context.md
│   │   ├── 02-c4-containers.md
│   │   ├── 03-c4-components-rcm-core.md
│   │   ├── 04-c4-components-rcm-rag.md
│   │   ├── 05-c4-components-rcm-bff.md
│   │   ├── 06-c4-components-rcm-notify.md
│   │   ├── 07-deployment-prod.md
│   │   ├── 08-deployment-local.md
│   │   ├── 09-network-trust-boundaries.md
│   │   ├── 10-phi-data-flow.md
│   │   ├── 11-multi-tenancy.md
│   │   ├── 12-observability-topology.md
│   │   ├── 13-agent-architecture.md
│   │   ├── 14-caching-architecture.md
│   │   ├── 15-prompt-registry.md
│   │   ├── 16-erd-rcm-core.md
│   │   ├── 17-erd-rag-schema.md
│   │   ├── 18-cosmosdb-event-stream.md
│   │   ├── 19-mongodb-audit-schema.md
│   │   ├── 20-uml-class-rcm-domain.md
│   │   ├── 21-uml-class-rag-domain.md
│   │   ├── 22-uml-class-agent-domain.md
│   │   ├── 23-seq-eligibility-verification.md
│   │   ├── 24-seq-claim-scrubbing-grpc.md
│   │   ├── 25-seq-claim-submission-kafka.md
│   │   ├── 26-seq-denial-agent-async.md
│   │   ├── 27-seq-spring-ai-summarization.md
│   │   ├── 28-seq-rag-eval-run.md
│   │   ├── 29-seq-rate-limit-enforcement.md
│   │   ├── 30-state-claim-lifecycle.md
│   │   ├── 31-state-denial-lifecycle.md
│   │   ├── 32-state-agent-execution.md
│   │   ├── 33-activity-biller-workflow.md
│   │   └── 34-activity-claim-scrub-decision.md
│   │
│   ├── architecture-overview.md                     [D]
│   ├── hipaa-security-guide.md                      [D]
│   ├── multi-tenancy-guide.md                       [D]
│   ├── caching-strategy.md                          [D]
│   ├── ai-governance.md                             [D]
│   ├── prompt-engineering-guide.md                  [D]
│   ├── eval-methodology.md                          [D]
│   ├── local-dev-setup.md                           [D]
│   ├── api-conventions.md                           [D]
│   ├── rcm-glossary.md                              [D] RCM domain terms
│   ├── INTERVIEW_PREP.md                            [D] Generated last
│   └── process/
│       ├── sprint-plan-template.md                  [D]
│       ├── retro-template.md                        [D]
│       └── code-review-checklist.md                 [D]
│
├── infrastructure/
│   ├── docker-compose.yml                           [I] Full local stack
│   ├── docker-compose.override.yml                  [I] Dev overrides
│   ├── .env.example                                 [I] All env vars documented
│   │
│   ├── terraform/                                   [I] AWS prod stubs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── modules/
│   │   │   ├── networking/
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   ├── ecs/
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   ├── rds/
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   ├── elasticache/
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   ├── msk/
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   └── cosmosdb/
│   │   │       ├── main.tf
│   │   │       └── variables.tf
│   │   └── environments/
│   │       ├── dev.tfvars
│   │       └── prod.tfvars
│   │
│   ├── observability/
│   │   ├── prometheus/
│   │   │   └── prometheus.yml
│   │   ├── grafana/
│   │   │   ├── provisioning/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── datasources.yml
│   │   │   │   └── dashboards/
│   │   │   │       └── dashboards.yml
│   │   │   └── dashboards/
│   │   │       ├── service-overview.json
│   │   │       ├── llm-cost.json
│   │   │       ├── rag-quality.json
│   │   │       ├── claim-throughput.json
│   │   │       └── agent-execution.json
│   │   ├── loki/
│   │   │   └── loki-config.yml
│   │   ├── tempo/
│   │   │   └── tempo-config.yml
│   │   └── mimir/
│   │       └── mimir-config.yml
│   │
│   ├── kafka/
│   │   └── topics.yml                               [I] Topic definitions
│   │
│   └── seed-data/
│       ├── synthetic-patients.sql
│       ├── synthetic-payers.sql
│       ├── cpt-codes.sql                            [I] Public CMS data
│       ├── icd10-codes.sql                          [I] Public CMS data
│       ├── carc-codes.sql                           [I] Public data
│       ├── rarc-codes.sql                           [I] Public data
│       ├── synthetic-payer-policies/                [I] RAG corpus
│       │   ├── aetna-policy-001.txt
│       │   ├── cigna-policy-001.txt
│       │   ├── uhc-policy-001.txt
│       │   └── bcbs-policy-001.txt
│       └── synthetic-appeal-templates/
│           ├── medical-necessity-appeal.txt
│           ├── coding-error-appeal.txt
│           └── timely-filing-appeal.txt
│
├── proto/                                           [I] Shared protobuf definitions
│   └── rcm/
│       └── v1/
│           ├── claim_scrubbing.proto
│           ├── claim_scrubbing_pb2.py               [*] generated
│           ├── claim_scrubbing_pb2_grpc.py          [*] generated
│           └── ClaimScrubbingGrpc.java              [*] generated
│
├── rcm-core/                                        [J] Spring Boot monolith
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle/
│   │   └── wrapper/
│   │       ├── gradle-wrapper.jar
│   │       └── gradle-wrapper.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── checkstyle/
│   │   └── checkstyle.xml
│   ├── spotless/
│   │   └── java-format.xml
│   │
│   ├── common/                                      [J] Shared across all contexts
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/common/
│   │       │   ├── config/
│   │       │   │   ├── SecurityConfig.java
│   │       │   │   ├── JwtConfig.java
│   │       │   │   ├── RedisConfig.java
│   │       │   │   ├── KafkaConfig.java
│   │       │   │   ├── GrpcClientConfig.java
│   │       │   │   ├── SpringAiConfig.java
│   │       │   │   └── ObservabilityConfig.java
│   │       │   ├── domain/
│   │       │   │   ├── TenantId.java               value object
│   │       │   │   ├── UserId.java                 value object
│   │       │   │   └── Money.java                  value object
│   │       │   ├── multitenancy/
│   │       │   │   ├── TenantContext.java           ThreadLocal holder
│   │       │   │   ├── TenantFilter.java            Servlet filter
│   │       │   │   └── TenantHibernateFilter.java
│   │       │   ├── security/
│   │       │   │   ├── JwtAuthFilter.java
│   │       │   │   ├── InternalContextFilter.java
│   │       │   │   └── PhiAccess.java              annotation
│   │       │   ├── audit/
│   │       │   │   ├── AuditEvent.java
│   │       │   │   ├── AuditService.java
│   │       │   │   └── AuditAspect.java             AOP aspect
│   │       │   ├── cache/
│   │       │   │   ├── L1CacheConfig.java
│   │       │   │   └── CacheInvalidationListener.java
│   │       │   ├── featureflags/
│   │       │   │   ├── FeatureFlag.java             enum
│   │       │   │   ├── FeatureFlagService.java
│   │       │   │   └── FeatureFlagEntity.java
│   │       │   ├── events/
│   │       │   │   ├── DomainEvent.java             base class
│   │       │   │   └── DomainEventPublisher.java
│   │       │   ├── exception/
│   │       │   │   ├── RcmException.java
│   │       │   │   ├── TenantIsolationException.java
│   │       │   │   └── GlobalExceptionHandler.java
│   │       │   └── observability/
│   │       │       ├── MetricsConfig.java
│   │       │       └── TraceConfig.java
│   │       └── test/java/com/rcm/common/
│   │           ├── multitenancy/
│   │           │   └── TenantIsolationTest.java
│   │           └── audit/
│   │               └── AuditAspectTest.java
│   │
│   ├── registration/                                [J] Bounded context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/registration/
│   │       │   ├── domain/
│   │       │   │   ├── Patient.java                entity + aggregate root
│   │       │   │   ├── PatientId.java              value object
│   │       │   │   ├── Demographics.java           value object
│   │       │   │   └── InsuranceInfo.java          value object
│   │       │   ├── repository/
│   │       │   │   └── PatientRepository.java
│   │       │   ├── service/
│   │       │   │   └── PatientService.java
│   │       │   ├── api/
│   │       │   │   ├── PatientController.java      REST
│   │       │   │   ├── dto/
│   │       │   │   │   ├── CreatePatientRequest.java
│   │       │   │   │   ├── PatientResponse.java
│   │       │   │   │   └── UpdatePatientRequest.java
│   │       │   │   └── mapper/
│   │       │   │       └── PatientMapper.java      MapStruct
│   │       │   └── events/
│   │       │       └── PatientRegisteredEvent.java
│   │       └── test/java/com/rcm/registration/
│   │           ├── domain/
│   │           │   └── PatientTest.java
│   │           ├── service/
│   │           │   └── PatientServiceTest.java
│   │           └── api/
│   │               └── PatientControllerIntegrationTest.java
│   │
│   ├── eligibility/                                 [J] Bounded context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/eligibility/
│   │       │   ├── domain/
│   │       │   │   ├── EligibilityRequest.java
│   │       │   │   ├── EligibilityResponse.java
│   │       │   │   └── CoverageDetail.java
│   │       │   ├── repository/
│   │       │   │   └── EligibilityResponseRepository.java
│   │       │   ├── service/
│   │       │   │   ├── EligibilityService.java
│   │       │   │   └── EligibilityCache.java       Redis L2
│   │       │   ├── client/
│   │       │   │   └── PayerEligibilityClient.java mock 270/271
│   │       │   └── api/
│   │       │       ├── EligibilityController.java
│   │       │       └── dto/
│   │       │           ├── EligibilityCheckRequest.java
│   │       │           └── EligibilityCheckResponse.java
│   │       └── test/java/com/rcm/eligibility/
│   │           ├── service/
│   │           │   └── EligibilityServiceTest.java
│   │           └── api/
│   │               └── EligibilityControllerIntegrationTest.java
│   │
│   ├── charge-capture/                              [J] Bounded context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/chargecapture/
│   │       │   ├── domain/
│   │       │   │   ├── Encounter.java
│   │       │   │   ├── EncounterId.java
│   │       │   │   ├── ChargeItem.java
│   │       │   │   ├── CptCode.java                value object
│   │       │   │   └── DiagnosisCode.java          value object (ICD-10)
│   │       │   ├── repository/
│   │       │   │   ├── EncounterRepository.java
│   │       │   │   └── CptCodeRepository.java
│   │       │   ├── service/
│   │       │   │   └── ChargeService.java
│   │       │   └── api/
│   │       │       ├── ChargeController.java
│   │       │       └── dto/
│   │       │           ├── CreateEncounterRequest.java
│   │       │           └── EncounterResponse.java
│   │       └── test/java/com/rcm/chargecapture/
│   │           └── service/
│   │               └── ChargeServiceTest.java
│   │
│   ├── claims/                                      [J] Bounded context - most complex
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/claims/
│   │       │   ├── domain/
│   │       │   │   ├── Claim.java                  aggregate root
│   │       │   │   ├── ClaimId.java
│   │       │   │   ├── ClaimLine.java
│   │       │   │   ├── ClaimStatus.java            enum
│   │       │   │   ├── ClaimScrubResult.java
│   │       │   │   ├── Edi837.java                 EDI wrapper
│   │       │   │   └── ClaimSummary.java           Spring AI generated
│   │       │   ├── repository/
│   │       │   │   ├── ClaimRepository.java
│   │       │   │   └── ClaimLineRepository.java
│   │       │   ├── service/
│   │       │   │   ├── ClaimService.java
│   │       │   │   ├── ClaimScrubService.java      calls rcm-rag via gRPC
│   │       │   │   ├── ClaimSubmissionService.java Kafka publisher
│   │       │   │   ├── ClaimSummaryService.java    Spring AI
│   │       │   │   └── Edi837Builder.java          builds EDI string
│   │       │   ├── grpc/
│   │       │   │   └── ClaimScrubGrpcClient.java   Resilience4j wrapped
│   │       │   ├── kafka/
│   │       │   │   └── ClaimEventPublisher.java
│   │       │   ├── cosmosdb/
│   │       │   │   └── ClaimEventStreamClient.java writes to CosmosDB
│   │       │   └── api/
│   │       │       ├── ClaimController.java
│   │       │       └── dto/
│   │       │           ├── CreateClaimRequest.java
│   │       │           ├── ClaimResponse.java
│   │       │           ├── ScrubResultResponse.java
│   │       │           └── SubmitClaimRequest.java
│   │       └── test/java/com/rcm/claims/
│   │           ├── domain/
│   │           │   └── ClaimTest.java
│   │           ├── service/
│   │           │   ├── ClaimServiceTest.java
│   │           │   └── ClaimScrubServiceTest.java
│   │           ├── grpc/
│   │           │   └── ClaimScrubGrpcClientTest.java
│   │           └── api/
│   │               └── ClaimControllerIntegrationTest.java
│   │
│   ├── payments/                                    [J] Bounded context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/payments/
│   │       │   ├── domain/
│   │       │   │   ├── Payment.java
│   │       │   │   ├── PaymentId.java
│   │       │   │   ├── Era.java                    Electronic Remittance Advice (835)
│   │       │   │   ├── EraLine.java
│   │       │   │   └── Edi835Parser.java           parses 835 EDI string
│   │       │   ├── repository/
│   │       │   │   ├── PaymentRepository.java
│   │       │   │   └── EraRepository.java
│   │       │   ├── service/
│   │       │   │   └── PaymentPostingService.java
│   │       │   └── api/
│   │       │       ├── PaymentController.java
│   │       │       └── dto/
│   │       │           ├── PostPaymentRequest.java
│   │       │           └── EraResponse.java
│   │       └── test/java/com/rcm/payments/
│   │           └── service/
│   │               └── PaymentPostingServiceTest.java
│   │
│   ├── denials/                                     [J] Bounded context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/denials/
│   │       │   ├── domain/
│   │       │   │   ├── Denial.java                 aggregate root
│   │       │   │   ├── DenialId.java
│   │       │   │   ├── DenialStatus.java           enum
│   │       │   │   ├── CarcCode.java               value object
│   │       │   │   ├── RarcCode.java               value object
│   │       │   │   ├── AppealDraft.java
│   │       │   │   └── AppealStatus.java           enum
│   │       │   ├── repository/
│   │       │   │   ├── DenialRepository.java
│   │       │   │   └── AppealRepository.java
│   │       │   ├── service/
│   │       │   │   ├── DenialService.java
│   │       │   │   └── AppealService.java
│   │       │   ├── kafka/
│   │       │   │   ├── DenialReceivedConsumer.java reads denial.received topic
│   │       │   │   └── DenialExplainedConsumer.java reads denial.explained topic
│   │       │   └── api/
│   │       │       ├── DenialController.java
│   │       │       └── dto/
│   │       │           ├── DenialResponse.java
│   │       │           ├── AppealDraftResponse.java
│   │       │           └── ApproveAppealRequest.java
│   │       └── test/java/com/rcm/denials/
│   │           ├── domain/
│   │           │   └── DenialTest.java
│   │           └── service/
│   │               └── DenialServiceTest.java
│   │
│   ├── ar/                                          [J] Accounts Receivable context
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/java/com/rcm/ar/
│   │       │   ├── domain/
│   │       │   │   ├── ArBalance.java
│   │       │   │   └── AgingBucket.java            enum: 0-30, 31-60, etc.
│   │       │   ├── repository/
│   │       │   │   └── ArBalanceRepository.java
│   │       │   ├── service/
│   │       │   │   └── ArService.java
│   │       │   └── api/
│   │       │       ├── ArController.java
│   │       │       └── dto/
│   │       │           └── ArAgingReport.java
│   │       └── test/java/com/rcm/ar/
│   │           └── service/
│   │               └── ArServiceTest.java
│   │
│   └── app/                                         [J] Spring Boot application entry point
│       ├── build.gradle
│       └── src/
│           ├── main/
│           │   ├── java/com/rcm/
│           │   │   └── RcmCoreApplication.java
│           │   └── resources/
│           │       ├── application.yml
│           │       ├── application-dev.yml
│           │       ├── application-test.yml
│           │       ├── application-prod.yml
│           │       ├── db/migration/               Flyway SQL migrations
│           │       │   ├── V001__create_extensions.sql
│           │       │   ├── V002__create_tenants.sql
│           │       │   ├── V003__create_patients.sql
│           │       │   ├── V004__create_encounters.sql
│           │       │   ├── V005__create_claims.sql
│           │       │   ├── V006__create_claim_lines.sql
│           │       │   ├── V007__create_payers.sql
│           │       │   ├── V008__create_payments.sql
│           │       │   ├── V009__create_eras.sql
│           │       │   ├── V010__create_denials.sql
│           │       │   ├── V011__create_appeals.sql
│           │       │   ├── V012__create_ar_balances.sql
│           │       │   ├── V013__create_feature_flags.sql
│           │       │   ├── V014__create_rag_schema.sql
│           │       │   ├── V015__create_vector_indexes.sql
│           │       │   └── V016__create_materialized_views.sql
│           │       └── logback-spring.xml
│           └── test/
│               ├── java/com/rcm/
│               │   └── RcmCoreApplicationTest.java
│               └── resources/
│                   └── application-test.yml
│
├── rcm-rag/                                         [P] FastAPI RAG service
│   ├── pyproject.toml
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── ruff.toml
│   ├── mypy.ini
│   ├── .pre-commit-config.yaml
│   │
│   ├── rcm_rag/                                     [P] main package
│   │   ├── __init__.py
│   │   ├── main.py                                  FastAPI app entry point
│   │   ├── config.py                                Settings (pydantic-settings)
│   │   │
│   │   ├── common/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py                              JWT validation dependency
│   │   │   ├── multitenancy.py                      tenant context var
│   │   │   ├── audit.py                             audit event writer
│   │   │   ├── phi_redactor.py                      Presidio wrapper
│   │   │   ├── observability.py                     OTel + structlog setup
│   │   │   ├── feature_flags.py                     flag client
│   │   │   └── exceptions.py
│   │   │
│   │   ├── db/
│   │   │   ├── __init__.py
│   │   │   ├── postgres.py                          SQLAlchemy async engine
│   │   │   ├── redis_client.py
│   │   │   ├── mongo_client.py
│   │   │   └── cosmosdb_client.py
│   │   │
│   │   ├── ingestion/                               LlamaIndex pipeline
│   │   │   ├── __init__.py
│   │   │   ├── document_loader.py
│   │   │   ├── chunker.py                           semantic chunking
│   │   │   ├── embedder.py                          provider-abstracted
│   │   │   ├── pgvector_store.py                    upsert + index rebuild
│   │   │   ├── faiss_cache.py                       FAISS hot cache
│   │   │   └── ingestion_pipeline.py                orchestrates loader→chunk→embed→store
│   │   │
│   │   ├── retrieval/
│   │   │   ├── __init__.py
│   │   │   ├── retriever.py                         hybrid pgvector retriever
│   │   │   ├── semantic_cache.py                    pgvector-based semantic cache
│   │   │   └── reranker.py                          cross-encoder reranking (optional)
│   │   │
│   │   ├── prompts/                                 prompt registry
│   │   │   ├── __init__.py
│   │   │   ├── registry.py                          YAML loader + version resolver
│   │   │   ├── claim-scrubbing-v1.0.0.yaml
│   │   │   ├── denial-explanation-v1.0.0.yaml
│   │   │   ├── appeal-drafting-v1.0.0.yaml
│   │   │   └── medical-necessity-v1.0.0.yaml
│   │   │
│   │   ├── llm/
│   │   │   ├── __init__.py
│   │   │   ├── client.py                            provider-abstracted LLM client
│   │   │   ├── azure_openai_client.py
│   │   │   ├── ollama_client.py
│   │   │   ├── structured_output.py                 Pydantic validation + retry
│   │   │   ├── token_counter.py                     tiktoken wrapper
│   │   │   └── middleware/
│   │   │       ├── budget_middleware.py
│   │   │       ├── rate_limit_middleware.py
│   │   │       └── token_counting_middleware.py
│   │   │
│   │   ├── agent/                                   LangGraph denial resolution agent
│   │   │   ├── __init__.py
│   │   │   ├── graph.py                             LangGraph state machine definition
│   │   │   ├── state.py                             AgentState TypedDict
│   │   │   ├── nodes/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── triage.py
│   │   │   │   ├── lookup_carc.py
│   │   │   │   ├── fetch_payer_policy.py
│   │   │   │   ├── check_medical_necessity.py
│   │   │   │   ├── draft_appeal.py
│   │   │   │   ├── human_review.py                  interrupt node
│   │   │   │   └── finalize.py
│   │   │   ├── tools/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── carc_lookup_tool.py
│   │   │   │   ├── payer_policy_tool.py
│   │   │   │   ├── medical_necessity_tool.py
│   │   │   │   └── appeal_draft_tool.py
│   │   │   └── persistence.py                       durable agent state to Postgres
│   │   │
│   │   ├── flows/
│   │   │   ├── __init__.py
│   │   │   ├── claim_scrubbing.py                   gRPC servicer impl
│   │   │   └── denial_explanation.py                Kafka consumer + agent trigger
│   │   │
│   │   ├── grpc/
│   │   │   ├── __init__.py
│   │   │   └── claim_scrub_servicer.py              implements protobuf service
│   │   │
│   │   ├── kafka/
│   │   │   ├── __init__.py
│   │   │   ├── consumer.py                          denial.received consumer
│   │   │   └── producer.py                          denial.explained producer
│   │   │
│   │   ├── schemas/                                 Pydantic models (structured output)
│   │   │   ├── __init__.py
│   │   │   ├── scrub_result.py
│   │   │   ├── denial_explanation.py
│   │   │   ├── appeal_draft.py
│   │   │   └── agent_state.py
│   │   │
│   │   └── api/                                     FastAPI routes (REST endpoints)
│   │       ├── __init__.py
│   │       ├── router.py
│   │       ├── health.py
│   │       ├── ingestion.py                         ingest documents into RAG corpus
│   │       ├── retrieval.py                         debug retrieval endpoint
│   │       ├── denial.py                            denial explanation + agent status
│   │       └── eval.py                              trigger eval run via API
│   │
│   ├── evals/                                       [P] eval harness
│   │   ├── __init__.py
│   │   ├── runner.py                                main eval runner
│   │   ├── metrics/
│   │   │   ├── __init__.py
│   │   │   ├── retrieval_metrics.py                 recall@k, precision@k, MRR, NDCG
│   │   │   ├── generation_metrics.py                faithfulness, answer_relevance, BLEU, ROUGE
│   │   │   ├── domain_metrics.py                    carc_accuracy, usefulness
│   │   │   └── operational_metrics.py               latency, tokens, cache hit rate
│   │   ├── golden_sets/
│   │   │   ├── claim_scrubbing_golden.json
│   │   │   └── denial_explanation_golden.json
│   │   ├── thresholds.yaml
│   │   └── reports/                                 [*] generated HTML reports
│   │
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── unit/
│   │   │   ├── test_phi_redactor.py
│   │   │   ├── test_chunker.py
│   │   │   ├── test_retriever.py
│   │   │   ├── test_structured_output.py
│   │   │   ├── test_prompt_registry.py
│   │   │   ├── test_token_counter.py
│   │   │   └── test_agent_graph.py
│   │   ├── integration/
│   │   │   ├── test_ingestion_pipeline.py           Testcontainers Postgres
│   │   │   ├── test_claim_scrubbing_grpc.py
│   │   │   ├── test_denial_kafka_flow.py            Testcontainers Kafka
│   │   │   └── test_semantic_cache.py
│   │   └── pact/
│   │       └── test_pact_provider.py                Pact provider verification
│   │
│   └── scripts/
│       ├── ingest_corpus.py                         one-time corpus ingestion
│       └── rebuild_faiss_index.py
│
├── rcm-notify/                                      [N] Node.js notification service
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .eslintrc.json
│   │
│   └── src/
│       ├── index.ts                                 Express app entry point
│       ├── config.ts
│       ├── common/
│       │   ├── auth.ts                              JWT validation middleware
│       │   ├── multitenancy.ts
│       │   ├── audit.ts
│       │   ├── observability.ts                     OTel + pino
│       │   └── errors.ts
│       ├── kafka/
│       │   ├── consumer.ts                          KafkaJS consumer
│       │   └── handlers/
│       │       ├── claimSubmittedHandler.ts
│       │       ├── denialReceivedHandler.ts
│       │       └── denialExplainedHandler.ts
│       ├── channels/
│       │   ├── email.ts                             Nodemailer
│       │   ├── sms.ts                               Twilio stub
│       │   └── webhook.ts                           outbound HTTP webhook delivery
│       ├── templates/
│       │   ├── claim-submitted.hbs
│       │   ├── denial-received.hbs
│       │   └── appeal-ready-for-review.hbs
│       ├── db/
│       │   └── postgres.ts                          pg client (notification_log table)
│       └── api/
│           ├── router.ts
│           └── health.ts
│   │
│   └── tests/
│       ├── unit/
│       │   ├── channels.test.ts
│       │   └── handlers.test.ts
│       └── integration/
│           └── kafka.integration.test.ts
│
├── rcm-bff/                                         [N] Node.js BFF + GraphQL
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .eslintrc.json
│   │
│   └── src/
│       ├── index.ts                                 Apollo Server + Express
│       ├── config.ts
│       ├── common/
│       │   ├── auth.ts
│       │   ├── multitenancy.ts
│       │   ├── observability.ts
│       │   ├── dataloader.ts                        DataLoader factory
│       │   └── errors.ts
│       ├── schema/
│       │   ├── typeDefs/
│       │   │   ├── patient.graphql
│       │   │   ├── claim.graphql
│       │   │   ├── denial.graphql
│       │   │   ├── payment.graphql
│       │   │   ├── ar.graphql
│       │   │   └── agent.graphql
│       │   └── index.ts                             merges all typeDefs
│       ├── resolvers/
│       │   ├── patient.resolver.ts
│       │   ├── claim.resolver.ts
│       │   ├── denial.resolver.ts
│       │   ├── payment.resolver.ts
│       │   ├── ar.resolver.ts
│       │   └── agent.resolver.ts
│       ├── dataSources/
│       │   ├── RcmCoreApi.ts                        REST client → rcm-core
│       │   └── RcmRagApi.ts                         REST client → rcm-rag (status endpoints)
│       ├── db/
│       │   └── postgres.ts                          reporting queries (mat views)
│       └── api/
│           ├── router.ts
│           ├── health.ts
│           └── sse.ts                               SSE endpoint for LLM streaming
│   │
│   └── tests/
│       ├── unit/
│       │   └── resolvers.test.ts
│       ├── integration/
│       │   └── graphql.integration.test.ts
│       └── pact/
│           └── rcm-core.pact.test.ts                Pact consumer test
│
├── rcm-ui/                                          [U] Next.js biller workbench
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts
│   ├── tailwind.config.ts
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .eslintrc.json
│   │
│   ├── app/                                         Next.js App Router
│   │   ├── layout.tsx
│   │   ├── page.tsx                                 redirect to /claims
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── callback/
│   │   │       └── page.tsx
│   │   ├── claims/
│   │   │   ├── page.tsx                             Claims dashboard
│   │   │   └── [claimId]/
│   │   │       └── page.tsx                         Claim detail
│   │   └── denials/
│   │       ├── page.tsx                             Denial queue
│   │       └── [denialId]/
│   │           └── page.tsx                         Denial review + appeal draft (SSE)
│   │
│   ├── components/
│   │   ├── claims/
│   │   │   ├── ClaimsDashboard.tsx
│   │   │   ├── ClaimStatusBadge.tsx
│   │   │   └── ClaimCard.tsx
│   │   ├── denials/
│   │   │   ├── DenialQueue.tsx
│   │   │   ├── DenialReviewPanel.tsx
│   │   │   ├── AppealDraftEditor.tsx               editable, with streaming
│   │   │   └── AgentStepsTimeline.tsx              shows agent reasoning steps
│   │   └── shared/
│   │       ├── LoadingSpinner.tsx
│   │       ├── ErrorBoundary.tsx
│   │       └── TenantHeader.tsx
│   │
│   ├── lib/
│   │   ├── auth.ts                                  NextAuth + Keycloak provider
│   │   ├── graphql-client.ts                        Apollo Client setup
│   │   ├── sse-client.ts                            SSE hook (useSSE)
│   │   └── api.ts                                   typed fetch wrappers
│   │
│   ├── queries/
│   │   ├── claims.graphql
│   │   └── denials.graphql
│   │
│   └── tests/
│       ├── unit/
│       │   └── components/
│       │       └── AppealDraftEditor.test.tsx
│       └── e2e/
│           ├── playwright.config.ts
│           ├── claims-dashboard.spec.ts
│           └── denial-review.spec.ts
│
├── Makefile                                         [I] cross-platform task runner
├── README.md                                        [D] main readme with diagram embeds
├── CONTRIBUTING.md                                  [D]
├── CHANGELOG.md                                     [*] generated by git-cliff
├── .gitignore
├── .gitattributes
├── .editorconfig
├── .pre-commit-config.yaml
└── commitlint.config.js
