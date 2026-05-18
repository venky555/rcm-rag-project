// FILE: docs/diagrams/06-c4-components-rcm-notify.md
---
# C4 Level 3: Component Diagram - rcm-notify

## Overview
This Component diagram illustrates the internal workings of the `rcm-notify` service. Designed as a lightweight, event-driven Node.js application, it consumes Kafka events from the core and RAG systems, renders localized templates via Handlebars, and dispatches messages across multiple channels (Email, SMS, Webhooks).

## Diagram
```text
               HTTP/REST                                 Kafka Events (claim/denial topics)
       ------------------------->               --------------------------------------------------->
                   |                                                     |
                   v                                                     v
+-------------------------------------------------------------------------------------------------------------------+
|                                        rcm-notify [Node.js 20, Express]                                           |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  | Middleware & Observability                                                                                  |  |
|  | - OTel Auto-instrumentation, pino logging, prom-client, JWT Validation (for REST calls)                     |  |
|  +-------------------------------------------------------------------------------------------------------------+  |
|                   |                                                    |                                          |
|  +--------------------------+  +-------------------------------------------------------------------------------+  |
|  | api                      |  | Event Ingestion                                                               |  |
|  | - Express HTTP Server    |  |  +-----------------------+  +------------------------+  +------------------+  |  |
|  | - /health, /api/notify   |  |  | ClaimSubmittedHandler |  | DenialReceivedHandler  |  | DenialExplained- |  |  |
|  +--------------------------+  |  +-----------------------+  +------------------------+  | Handler          |  |  |
|                                |                                                         +------------------+  |  |
|                                |                                   ^                                           |  |
|                                |                                   |                                           |  |
|                                |                           +------------------+                                |  |
|                                |                           | KafkaJS Consumer |                                |  |
|                                |                           +------------------+                                |  |
|                                +-------------------------------------------------------------------------------+  |
|                                                                    |                                              |
|                                                                    v                                              |
|                                +-------------------------------------------------------------------------------+  |
|                                | Template Engine                                                               |  |
|                                |                                                                               |  |
|                                |  +-------------------------------------------------------------------------+  |  |
|                                |  | Handlebars Templates                                                    |  |  |
|                                |  | [claim-submitted.hbs, denial-received.hbs, appeal-ready-for-review.hbs] |  |  |
|                                |  +-------------------------------------------------------------------------+  |  |
|                                +-------------------------------------------------------------------------------+  |
|                                                                    |                                              |
|                                                                    v                                              |
|                                +-------------------------------------------------------------------------------+  |
|                                | Dispatch & Logging                                                            |  |
|                                |                                                                               |  |
|                                |  +-----------------------+  +-----------------------+  +-------------------+  |  |
|                                |  | EmailChannel          |  | SmsChannel            |  | WebhookChannel    |  |  |
|                                |  | (Nodemailer)          |  | (Twilio stub)         |  | (Outbound HTTP)   |  |  |
|                                |  +-----------------------+  +-----------------------+  +-------------------+  |  |
|                                |             |                          |                         |            |  |
|                                |             +--------------------------+-------------------------+            |  |
|                                |                                        |                                      |  |
|                                |                                        v                                      |  |
|                                |                             +-----------------------+                         |  |
|                                |                             | Postgres Client       |                         |  |
|                                |                             | (notification_log)    |                         |  |
|                                |                             +-----------------------+                         |  |
|                                +-------------------------------------------------------------------------------+  |
|                                                                         |                                         |
+-------------------------------------------------------------------------+-----------------------------------------+
                                                                          |
                                                                          | PostgreSQL (Write)
                                                                          v
                                                                  +--------------+
                                                                  |  PostgreSQL  |
                                                                  +--------------+
```

## Key Points
- **Kafka-Driven Architecture:** Relies almost entirely on asynchronous events via KafkaJS, shielding end-users from the latency inherent in sending external emails or SMS messages.
- **Multi-Channel Dispatch:** Extensible design easily routes notifications to different providers (Nodemailer, Twilio, Webhooks) based on the recipient's preference or the tenant's configuration.
- **Handlebars Templating:** Separates message formatting and localization from the core codebase.
- **Audit Logging:** Every dispatched notification is recorded in a PostgreSQL `notification_log` table to ensure auditability.

## Interview Talking Points
- Discuss the separation of concerns: `rcm-core` and `rcm-rag` services do not need to know how to send emails; they simply broadcast domain events to Kafka. `rcm-notify` solely handles the communication layer.
- Highlight the importance of the `notification_log` in PostgreSQL. In healthcare, proving that a provider was notified of an appeal deadline is critical for compliance and troubleshooting missed communications.
// ===== END OF FILE =====
