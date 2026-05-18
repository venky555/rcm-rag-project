// FILE: docs/diagrams/05-c4-components-rcm-bff.md
---
# C4 Level 3: Component Diagram - rcm-bff

## Overview
This Component diagram maps the internal structure of the `rcm-bff` (Backend-for-Frontend) service. Built on Node.js 20 and Apollo Server 4, this service aggregates data from multiple backend services, handles N+1 query optimization via DataLoaders, provides real-time streaming via SSE, and serves as the single secure entry point for the `rcm-ui`.

## Diagram
```text
                  GraphQL / HTTP                                    HTTP GET (SSE)
       ------------------------------------->             ----------------------------------->
                         |                                                 |
                         v                                                 v
+-------------------------------------------------------------------------------------------------------------------+
|                                          rcm-bff [Node.js 20, Express]                                            |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  | Middleware & Common                                                                                         |  |
|  | - JWT Validation (Keycloak JWKS), Tenant Context, OTel Auto-instrumentation, pino logging, prom-client      |  |
|  +-------------------------------------------------------------------------------------------------------------+  |
|             |                                                                                   |                 |
|             v                                                                                   v                 |
|  +----------------------------------------------------+                      +---------------------------------+  |
|  | Apollo Server 4                                    |                      | Express SSE Endpoint            |  |
|  |                                                    |                      |                                 |  |
|  |  +----------------------------------------------+  |                      |  [ GET /sse/denial/:id ]        |  |
|  |  | GraphQL Schema (merged from 6 .graphql files)|  |                      |                                 |  |
|  |  +----------------------------------------------+  |                      |  - Streams denial explanation   |  |
|  |                          |                         |                      |    progress to UI               |  |
|  |                          v                         |                      |                                 |  |
|  |  +----------------------------------------------+  |                      +---------------------------------+  |
|  |  | Resolvers                                    |  |                                     |                     |
|  |  | - Patient, Claim, Denial, Payment, AR, Agent |  |                                     |                     |
|  |  +----------------------------------------------+  |                                     |                     |
|  |                          |                         |                                     |                     |
|  |                          v                         |                                     |                     |
|  |  +----------------------------------------------+  |                                     |                     |
|  |  | DataLoader (Batching & Caching)              |  |                                     |                     |
|  |  | - PatientLoader, ClaimLoader, DenialLoader   |  |                                     |                     |
|  |  +----------------------------------------------+  |                                     |                     |
|  +----------------------------------------------------+                                     |                     |
|             |                                   |                                           |                     |
|             v                                   |                                           |                     |
|  +-----------------------------------+          |                                           |                     |
|  | DataSources (Axios REST Clients)  |          |                                           |                     |
|  | - RcmCoreApi (rcm-core)           |          |                                           |                     |
|  | - RcmRagApi (rcm-rag)             |<---------+-------------------------------------------+                     |
|  +-----------------------------------+          |                                                                 |
|             |                  |                |                                                                 |
|  +-----------------------+     |                |                                                                 |
|  | Postgres Client       |     |                |                                                                 |
|  | - Reporting / MViews  |     |                |                                                                 |
|  +-----------------------+     |                |                                                                 |
|             |                  |                |                                                                 |
+-------------+------------------+----------------+-----------------------------------------------------------------+
              |                  |                |
              | PostgreSQL       | REST/JSON      | REST/JSON
              | (Read-Only)      | (Axios)        | (status/polling)
              v                  v                v
      +--------------+    +--------------+ +--------------+
      |  PostgreSQL  |    |   rcm-core   | |   rcm-rag    |
      | [Mat. Views] |    |  [REST API]  | | [Status API] |
      +--------------+    +--------------+ +--------------+
```

## Key Points
- **GraphQL Aggregation:** Reduces over-fetching for the UI by aggregating patient, claim, and denial data using Apollo Server.
- **N+1 Prevention:** Uses DataLoaders to batch and cache duplicate relational requests during a single GraphQL execution tick.
- **Server-Sent Events (SSE):** Enables real-time streaming of LangGraph's denial explanation tokens directly to the UI without the heavy overhead of WebSockets.
- **Read-Only Database Access:** For specific heavy reporting dashboards, the BFF directly queries materialized views in PostgreSQL rather than bottlenecking the core transactional API.

## Interview Talking Points
- Emphasize how `DataLoader` drastically reduces load on `rcm-core` by grouping multiple resolver fetches into a single batched REST call.
- Explain the strategic choice of SSE over WebSockets for LLM streaming—SSE is strictly unidirectional, easier to scale through ALB, and perfectly suited for streaming text generation from AI models.
- Discuss how the BFF abstracts the fragmented nature of the backend (REST, gRPC, polling) and presents a single, unified GraphQL graph to the front-end engineers.
// ===== END OF FILE =====
