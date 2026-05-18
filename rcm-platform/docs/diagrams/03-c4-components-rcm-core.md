// FILE: docs/diagrams/03-c4-components-rcm-core.md
---
# C4 Level 3: Component Diagram - rcm-core

## Overview
This Component diagram details the internal structure of the `rcm-core` service, a Spring Boot application. It illustrates the bounded contexts representing the various RCM domains, the shared common module for cross-cutting concerns, and the external connections to data stores, AI services, and message brokers.

## Diagram
```text
+-------------------------------------------------------------------------------------------------------------------+
|                                          rcm-core [Spring Boot, Java 21]                                          |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  | common module                                                                                               |  |
|  | [SecurityConfig, JwtAuthFilter, TenantContext, AuditAspect, MetricsConfig, DomainEventPublisher]            |  |
|  +-------------------------------------------------------------------------------------------------------------+  |
|      ^                       ^                       ^                       ^                       ^            |
|      | - - - - - - - - - - - | - - - - - - - - - - - | - - - - - - - - - - - | - - - - - - - - - - - |            |
|      |                       |                       |                       |                       |            |
|  +---+----------------+  +---+----------------+  +---+----------------+  +---+----------------+  +---+---------+  |
|  | registration       |  | eligibility        |  | charge-capture     |  | payments           |  | ar          |  |
|  | - PatientController|  | - EligibilityCtrl  |  | - ChargeController |  | - PaymentController|  | - ArCtrl    |  |
|  | - PatientService   |  | - EligibilitySvc   |  | - ChargeService    |  | - PaymentPostingSvc|  | - ArService |  |
|  | - PatientRepo      |  | - PayerEligClient  |  | - Encounter (Agg)  |  | - Edi835Parser     |  | - ArBalance |  |
|  +--------------------+  +--------------------+  +--------------------+  +--------------------+  +-------------+  |
|                                                                                                                   |
|  +----------------------------------------------------+  +-----------------------------------------------------+  |
|  | claims                                             |  | denials                                             |  |
|  | - ClaimController        - ClaimSummaryService     |  | - DenialController      - DenialService             |  |
|  | - ClaimService           - CosmosDB Event Writer   |  | - AppealService         - Denial (aggregate)        |  |
|  | - ClaimScrubService      - ClaimScrubGrpcClient    |  | - DenialRecvConsumer    - AppealDraft               |  |
|  | - ClaimSubmissionService - Edi837Builder           |  | - DenialExpldConsumer                               |  |
|  +----------------------------------------------------+  +-----------------------------------------------------+  |
|         |           |             |            |               |                 |                 |              |
+---------+-----------+-------------+------------+---------------+-----------------+-----------------+--------------+
          |           |             |            |               |                 |                 |
   Kafka  |     gRPC  |  Spring AI  |   Lettuce  |  Java SDKs    |     Kafka       |      JDBC       |
(produce) |           |   (REST)    |  (Redis)   | (Mongo/Cosmos)|   (consume)     |   (Postgres)    |
          v           v             v            v               v                 v                 v
     +-------+    +-------+    +-------+    +-------+       +----------+       +-------+         +-------+
     | Kafka |    |rcm-rag|    | Azure |    | Redis |       | MongoDB /|       | Kafka |         | Post- |
     | Broker|    |       |    | OpenAI|    |       |       | CosmosDB |       | Broker|         | greSQL|
     +-------+    +-------+    +-------+    +-------+       +----------+       +-------+         +-------+
```

## Key Points
- **Domain-Driven Design:** The service is strictly organized by bounded contexts (claims, denials, eligibility) preventing massive, tightly coupled spaghetti code.
- **Common Module:** Security (Keycloak JWT validation), audit aspects, and multi-tenancy logic are encapsulated here to keep domain code clean and focused.
- **Data Persistence:** The transactional backbone uses PostgreSQL (via JDBC), while specialized needs use Redis (caching), CosmosDB (event streams), and MongoDB (append-only audit logs).
- **Asynchronous Processing:** Claim submissions and denial ingestion are handled via Kafka to decouple external payer response times from the core system's responsiveness.
- **gRPC Integration:** The `claims` module leverages a Resilience4j-wrapped gRPC client (`ClaimScrubGrpcClient`) for ultra-low latency, synchronous interactions with the `rcm-rag` Python service.

## Interview Talking Points
- The architecture implements the **Modular Monolith** pattern perfectly; strict package boundaries inside `rcm-core` allow domains like "denials" to easily be extracted into standalone microservices in the future if they need independent scaling.
- Highlight the resilience built into the gRPC calls. By wrapping `ClaimScrubGrpcClient` in Resilience4j (circuit breakers and retries), `rcm-core` prevents cascading failures if `rcm-rag` is temporarily overwhelmed by embedding generation.
- Discuss how `TenantContext` in the common module automatically applies Hibernate filters to guarantee data isolation across different healthcare providers (tenants) without explicit filtering in every repository query.
// ===== END OF FILE =====
