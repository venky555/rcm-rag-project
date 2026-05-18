// FILE: docs/diagrams/08-deployment-local.md
---
# C4 Deployment Diagram: Local Environment

## Overview
This diagram details the local developer environment configured via `docker-compose`. All services, data stores, and observability tools run as lightweight Docker containers within a single isolated bridge network, mimicking the production architecture without cloud dependencies.

## Diagram
```text
+-------------------------------------------------------------------------------------------------------------------+
| Host Machine (Developer Laptop)                                                                                   |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  | Docker Engine / docker-compose                                                                              |  |
|  |                                                                                                             |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  |  | Bridge Network: rcm-network                                                                           |  |  |
|  |  |                                                                                                       |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  |  | Application Services                                                                            |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |  | rcm-ui          |  | rcm-bff         |  | rcm-core        |  | rcm-rag         |             |  |  |  |
|  |  |  |  | (port 3000)     |  | (port 8084)     |  | (port 8081)     |  | (port 8082)     |             |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |                                                                 +-----------------+             |  |  |  |
|  |  |  |                                                                 | rcm-notify      |             |  |  |  |
|  |  |  |                                                                 | (port 8083)     |             |  |  |  |
|  |  |  +-----------------------------------------------------------------+-----------------+             |  |  |  |
|  |  |                                                                                                       |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  |  | Data Stores & Messaging                                                                         |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |  | postgres:16     |  | mongo:7         |  | redis:7         |  | azure-cosmos-   |             |  |  |  |
|  |  |  |  | (port 5432)     |  | (port 27017)    |  | (port 6379)     |  | emulator (8081) |             |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +-----------------+  +-----------------+                                                       |  |  |  |
|  |  |  |  | kafka           |  | zookeeper       |                                                       |  |  |  |
|  |  |  |  | (port 9092)     |  | (port 2181)     |                                                       |  |  |  |
|  |  |  +--+-----------------+--+-----------------+-------------------------------------------------------+  |  |  |
|  |  |                                                                                                       |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  |  | Infrastructure, AI, & Observability                                                             |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |  | keycloak        |  | ollama          |  | prometheus      |  | grafana         |             |  |  |  |
|  |  |  |  | (port 8080)     |  | (port 11434)    |  | (port 9090)     |  | (port 3001)     |             |  |  |  |
|  |  |  |  +-----------------+  +-----------------+  +-----------------+  +-----------------+             |  |  |  |
|  |  |  |                                            +-----------------+  +-----------------+             |  |  |  |
|  |  |  |                                            | loki            |  | tempo           |             |  |  |  |
|  |  |  |                                            | (port 3100)     |  | (port 3200)     |             |  |  |  |
|  |  |  +--------------------------------------------+-----------------+--+-----------------+-------------+  |  |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  +-------------------------------------------------------------------------------------------------------------+  |
+-------------------------------------------------------------------------------------------------------------------+
```

## Key Points
- **Parity with Production:** By running local equivalents (e.g., Azure Cosmos Emulator, Ollama), developers can work against an architecture that closely mirrors the production layout.
- **Single Bridge Network:** The `rcm-network` bridge allows simple container-to-container DNS resolution using standard container names (e.g., `postgres:5432`), completely avoiding localhost mapping headaches.
- **Comprehensive Observability:** Developers can trace issues locally using Prometheus, Grafana, Loki, and Tempo exactly as they would in production.

## Interview Talking Points
- Discuss the "shift-left" advantage of providing developers with the full observability stack locally. Bugs in tracing, metrics, or logging configurations are caught and fixed before code ever reaches a staging environment.
- Mention the value of the Azure Cosmos Emulator and Ollama. This setup is essential for developing complex stream-processing or AI features completely offline without incurring high public cloud costs or latency.
// ===== END OF FILE =====
