// FILE: docs/diagrams/02-c4-containers.md
---
# C4 Level 2: Container Diagram

## Overview
This Container diagram zooms into the RCM Platform to reveal its internal microservices, data stores, and infrastructure components. It maps the flow of data across the GraphQL BFF, the Spring Boot transactional core, the Python-based RAG service, and the various specialized databases driving the event-driven architecture.

## Diagram
```text
                      +-------------------+          +-------------------+
                      |  Medical Biller   |          |     RCM Admin     |
                      |     [Person]      |          |     [Person]      |
                      +---------+---------+          +---------+---------+
                                |                              |
                                | HTTP/GraphQL                 | HTTP/GraphQL
                                | (+ SSE)                      |
                                v                              v
+---------------------------------------------------------------------------------------------+
| RCM Platform                                                                                |
|                                                                                             |
|   +-------------------------------------------------------------------------------------+   |
|   | App Services                                                                        |   |
|   |                                                                                     |   |
|   |  +-----------------------------+           +----------------------------------+     |   |
|   |  |           rcm-ui            | REST/HTTP |             rcm-bff              |     |   |
|   |  |        [Next.js 14]         |---------->| [Apollo Server + Express.js 20]  |     |   |
|   |  |      Biller Workbench       | GraphQL   |          GraphQL Gateway         |     |   |
|   |  +-----------------------------+           +----------------------------------+     |   |
|   |                                               |                 |                   |   |
|   |                                     REST/JSON |                 | REST/JSON         |   |
|   |                                               v                 | (polling)         |   |
|   |  +-----------------------------+     gRPC     |                 v                   |   |
|   |  |          rcm-core           |<-------------+   +---------------------------+     |   |
|   |  |    [Spring Boot, Java 21]   |                  |          rcm-rag          |     |   |
|   |  |  RCM Transactional Backbone |----------------->| [FastAPI, Python 3.12]    |     |   |
|   |  +-----------------------------+ gRPC (scrubbing) |  RAG, Embeddings, LLM     |     |   |
|   |      |        |        |                          +---------------------------+     |   |
|   |      |        |        | REST/JSON                      |       |                   |   |
|   |      |        |        | (notify trigger)               |       |                   |   |
|   |      |        |        v                                |       |                   |   |
|   |      |        |   +--------------------------+          |       |                   |   |
|   |      |        |   |        rcm-notify        |          |       |                   |   |
|   |      |        |   | [Express.js, Node 20]    |          |       |                   |   |
|   |      |        |   | Notifications            |          |       |                   |   |
|   |      |        |   +--------------------------+          |       |                   |   |
|   |      |        |                ^                        |       |                   |   |
|   |      |        |                | Kafka (consume)        |       |                   |   |
|   |      |        |                | claim.submitted,       | Kafka (consume/produce)   |   |
|   |      |        | Kafka (produce)| denial.received,       | denial.received /         |   |
|   |      |        | claim.submitted| denial.explained       | denial.explained          |   |
|   |      |        v denial.received|                        v                           |   |
|   |      |   +----------------------------------------------------------------------+   |   |
|   |      |   |                               Kafka                                  |   |   |
|   |      |   |                           [Message Broker]                           |   |   |
|   |      |   +----------------------------------------------------------------------+   |   |
|   +------+--------------------------------------------------------------------------+   |
|                                                                                         |
|   +-------------------------------------------------------------------------------------+   |
|   | Data Stores                                                                         |   |
|   |                                                                                     |   |
|   |  +--------------------+  +-------------------+  +----------------+  +-------------+ |   |
|   |  |   PostgreSQL 16    |  |     MongoDB 7     |  |    CosmosDB    |  |   Redis 7   | |   |
|   |  |   [+ pgvector]     |  |     [Log DB]      |  |    [Stream]    |  |  [L2 Cache] | |   |
|   |  +--------------------+  +-------------------+  +----------------+  +-------------+ |   |
|   |    ^   ^                   ^   ^                  ^   ^               ^   ^         |   |
|   |    |   | asyncpg (rag)     |   | Motor (rag)      |   | Py SDK (rag)  |   | redis-py|   |
|   |    |                       |                      |                   |     (rag)   |   |
|   |  JDBC (core)           Java Driver (core)      Java SDK (core)     Lettuce (core)   |   |
|   +-------------------------------------------------------------------------------------+   |
|                                                                                         |
|   +-------------------------------------------------------------------------------------+   |
|   | Infrastructure & Observability                                                      |   |
|   |                                                                                     |   |
|   |  +--------------------+  +-------------------+  +---------------------------------+ |   |
|   |  |      Keycloak      |  |      Ollama       |  |  Prometheus, Grafana, Loki,   | |   |
|   |  |       [OIDC]       |  |      [Dev]        |  |  Tempo [Observability Stack]  | |   |
|   |  +--------------------+  +-------------------+  +---------------------------------+ |   |
|   |          ^                           ^                                              |   |
|   |          | OIDC/JWKS                 | REST (Dev Only)                              |   |
|   |    (All Services)                 rcm-rag                                           |   |
|   +-------------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------------+
               |                  |                     |                       |
               | REST / HTTPS     | HTTP / JSON         | Spring AI (core)      |
               | (EDI 837/835)    | (270/271, etc.)     | LangChain (rag)       | REST/HL7
               v                  v                     v                       v
        +--------------+   +--------------+      +--------------+        +--------------+
        | Clearinghouse|   | Payer Systems|      | Azure OpenAI |        | EHR System   |
        |   [System]   |   |   [System]   |      |   [System]   |        |   [System]   |
        +--------------+   +--------------+      +--------------+        +--------------+
```

## Key Points
- **Front-End & BFF:** The Next.js UI (`rcm-ui`) communicates exclusively with the GraphQL BFF (`rcm-bff`), which orchestrates calls to backend services, simplifying client logic.
- **Transactional Core:** `rcm-core` (Spring Boot) is the heavy lifter handling state, EDI parsing, and external system integrations. It owns the primary transactional PostgreSQL data.
- **AI Service:** `rcm-rag` (FastAPI) encapsulates all intelligence tasks. It connects to the shared PostgreSQL (for vector search) and communicates with `rcm-core` via fast gRPC for synchronous scrubbing tasks.
- **Event-Driven Asynchrony:** Kafka handles async workflows. `rcm-core` publishes `claim.submitted` and `denial.received`. `rcm-rag` consumes denials, generates explanations, and publishes `denial.explained`. `rcm-notify` reacts to these events.
- **Data Specialization:** Polyglot persistence is used effectively: PostgreSQL for relational and vector data, MongoDB for append-only audit logs, CosmosDB for the claim event stream, and Redis for distributed caching.
- **Security:** Keycloak provides centralized OIDC identity management. All internal services independently validate JWT tokens using Keycloak's JWKS endpoint.

## Interview Talking Points
- Highlight the strategic choice of gRPC between `rcm-core` and `rcm-rag`. Claim scrubbing is a blocking, high-throughput synchronous operation; gRPC ensures minimal serialization overhead compared to REST.
- Explain the event-driven architecture using Kafka. It prevents tight coupling between core transactional processes and asynchronous tasks like generating AI explanations or sending emails.
- Emphasize the segregation of data stores based on read/write patterns. For example, using MongoDB strictly for high-volume, append-only PHI audit logs prevents locking issues in the primary PostgreSQL instance.
// ===== END OF FILE =====
