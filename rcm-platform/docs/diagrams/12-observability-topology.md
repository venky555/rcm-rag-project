// FILE: docs/diagrams/12-observability-topology.md
---
# Security & Operational Architecture: Observability Topology

## Overview
This diagram outlines the "Three Pillars of Observability" (Logs, Metrics, and Traces) across the RCM microservices. It highlights how telemetry is collected, shipped to central storage, and unified in Grafana, with a specific focus on distributed tracing across asynchronous Kafka boundaries.

## Diagram
```text
+-----------------------------------------------------------------------------------------------------+
| MICROSERVICES TIER                                                                                  |
|                                                                                                     |
|  +----------------+  +----------------+  +----------------+  +----------------+  +---------------+  |
|  | rcm-ui         |  | rcm-bff        |  | rcm-core       |  | rcm-rag        |  | rcm-notify    |  |
|  | (Browser/Next) |  | (Node.js)      |  | (Spring Boot)  |  | (FastAPI)      |  | (Node.js)     |  |
|  +----------------+  +----------------+  +----------------+  +----------------+  +---------------+  |
|         |                   |                    |                   |                   |          |
|  [pino] | [prom] [OTel]     | [Logback/Micro/OT] | [structlog/prom/OT] [pino/prom/OTel]  |          |
+---------+-------------------+--------------------+-------------------+-------------------+----------+
          |                   |                    |                   |                   |
          v                   v                    v                   v                   v
+-------------------+ +-------------------------------------------------------------------------------+
|     TELEMETRY     | |  W3C Trace Context Propagation                                                |
|     COLLECTION    | |  - HTTP Headers: `traceparent`, `tracestate`                                  |
|                   | |  - gRPC Metadata: injected by client, extracted by server                     |
|  +-------------+  | |  - Kafka Headers: injected by producer, extracted by consumer                 |
|  | Promtail    |  | +-------------------------------------------------------------------------------+
|  | (Logs)      |  |
|  +-------------+  |
|                   |
|  +-------------+  |
|  | Prometheus  |  |
|  | (Metrics)   |  |
|  +-------------+  |
|                   |
|  +-------------+  |
|  | OTel        |  |
|  | Collector   |  |
|  | (Traces)    |  |
|  +-------------+  |
+-------------------+
          |
          v
+-----------------------------------------------------------------------------------------------------+
| STORAGE TIER                                                                                        |
|                                                                                                     |
|  +---------------------------+    +--------------------------+    +------------------------------+  |
|  | LOKI                      |    | MIMIR                    |    | TEMPO                        |  |
|  | (Log Storage)             |    | (Long-term Metrics)      |    | (Distributed Tracing)        |  |
|  | Index: {service, tenant}  |    | Remote write from Prom   |    | Stores spans by Trace ID     |  |
|  +---------------------------+    +--------------------------+    +------------------------------+  |
+-----------------------------------------------------------------------------------------------------+
                                                   |
                                                   v
                                 +-----------------------------------+
                                 | GRAFANA                           |
                                 | (Unified Visualization Dashboard) |
                                 +-----------------------------------+
```

## Key Points
- **Standardized Libraries:** Each service uses its language's best-in-class libraries (pino, Logback, structlog) but formats all output as structured JSON to ensure it is easily parsed by Loki.
- **Trace Context Propagation:** The key to distributed tracing is the `traceparent` header. When `rcm-core` publishes a Kafka message, the OpenTelemetry SDK automatically injects the `traceparent` into the Kafka message header. When `rcm-rag` consumes it, it extracts that header, allowing Tempo to stitch the asynchronous hops into a single visual waterfall graph.
- **Decoupled Telemetry:** Services do not write directly to storage databases. They emit to local agents or scrape endpoints (Promtail, Prometheus, OTel Collector), completely decoupling application performance from monitoring infrastructure latency.
- **Unified Correlation:** In Grafana, an engineer can look at a spike in a Metric, click it to see the correlated structured Log, and click the attached `trace_id` to instantly jump to the Tempo distributed Trace.

## Interview Talking Points
- The handling of **Kafka Headers for W3C Trace Context** is a massive green flag in senior interviews. It proves you understand that traces don't magically jump across message brokers; they require explicit header injection/extraction.
- Mention that this architecture prevents "log spam." Because we have distributed tracing via Tempo, we don't need to log "Entering method X" or "Leaving method Y" — the spans handle timing and flow automatically.
// ===== END OF FILE =====
