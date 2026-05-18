// FILE: docs/diagrams/19-mongodb-audit-schema.md
---
# Data Model: MongoDB Audit Schema

## Overview
This diagram illustrates the structure of the `audit_events` collection in MongoDB. This collection serves as the immutable, HIPAA-compliant system of record for all data access across the RCM platform, answering Who, What, When, and Where for every interaction.

## Diagram
```text
+-----------------------------------------------------------------------------------------+
| MONGODB COLLECTION: audit_events                                                        |
+-----------------------------------------------------------------------------------------+
| DOCUMENT STRUCTURE (BSON)                                                               |
|                                                                                         |
| {                                                                                       |
|   "_id": ObjectId("..."),                                                               |
|   "tenantId": "uuid",                                                                   |
|   "actorId": "uuid",                   // The User, Service, or AI Agent                |
|   "actorType": "user|service|agent",                                                    |
|   "action": "READ|WRITE|DELETE",       // The operation performed                       |
|   "entityType": "Patient|Claim|Denial",// The domain aggregate                         |
|   "entityId": "uuid",                  // Specific record ID touched                    |
|   "timestamp": ISODate("2026-05-19..."),                                                |
|   "ipAddress": "192.168.1.50",                                                          |
|   "requestId": "uuid",                 // Tied to the API boundary                      |
|   "traceId": "string",                 // W3C Trace context (Tempo correlation)         |
|   "outcome": "SUCCESS|FAILURE",                                                          |
|   "llmCallId": "uuid|null",             // Context if AI made the change                 |
|   "agentRunId": "uuid|null"                                                             |
| }                                                                                       |
+-----------------------------------------------------------------------------------------+
| INDEXES & RETENTION                                                                     |
|                                                                                         |
| 1. Compound Index: { tenantId: 1, timestamp: -1 } -> For Security Dashboards            |
| 2. Single Field:   { actorId: 1 }                 -> "What did this user do?"           |
| 3. Single Field:   { entityId: 1 }                -> "Who touched this patient?"        |
| 4. TTL Index:      { timestamp: 1 } (expireAfterSeconds: 220752000) -> 7 Year retention |
+-----------------------------------------------------------------------------------------+
| ACCESS CONTROL                                                                          |
| Role: INSERT-ONLY. The application connects using a MongoDB user that strictly lacks    |
| update or delete privileges, guaranteeing cryptographic-like immutability.              |
+-----------------------------------------------------------------------------------------+
```

## Schema Design Decisions
1. **Immutable Append-Only:** The database user provisioned for the microservices only has `insert` permissions on this collection. By design, no application code can update or delete an audit log, strictly satisfying HIPAA logging constraints.
2. **AI Traceability:** Including `llmCallId` and `agentRunId` ensures that when an action is performed autonomously (e.g., drafting an appeal), security officers can trace exactly which prompt generation and agent state triggered the change.
3. **Cross-System Correlation:** The inclusion of `traceId` maps directly to OpenTelemetry and Tempo. If an anomaly is found in the audit log, an engineer can instantly pull up the corresponding distributed trace.
4. **Automated 7-Year Retention:** By using MongoDB's native TTL (Time-To-Live) index on the `timestamp` field, records older than the HIPAA-mandated 7 years are automatically purged, ensuring compliance without cron jobs or manual scripts.

## Interview Talking Points
- Highlight the **Document DB fit for Auditing**. Audit logs grow at a massive rate. MongoDB easily handles extremely high-throughput, schema-less inserts, keeping the write burden entirely off the primary Postgres transaction database.
- Focus on the `actorType` polymorphism. Because an "actor" can be a human user, an internal microservice, or the LangGraph AI Agent itself, the generic `actorId` + `actorType` pattern allows robust reporting regardless of who (or what) touched the data.
// ===== END OF FILE =====
