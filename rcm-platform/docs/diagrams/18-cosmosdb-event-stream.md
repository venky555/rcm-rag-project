// FILE: docs/diagrams/18-cosmosdb-event-stream.md
---
# Data Model: CosmosDB Event Stream

## Overview
This diagram defines the NoSQL structure used within Azure CosmosDB. The `claim_events` container acts as an append-only event store, tracking the granular lifecycle of every claim. It drives the analytical views and enables perfect historical auditing.

## Diagram
```text
+-----------------------------------------------------------------------------------------+
| COSMOS DB CONTAINER: claim_events                                                       |
| API: NoSQL (Core)                                                                       |
+-----------------------------------------------------------------------------------------+
| PARTITION KEY: /claimId                                                                 |
| Enables massively parallel scaling. All events for a single claim land on the same      |
| physical partition, allowing ultra-fast chronologial retrieval of a claim's timeline.   |
+-----------------------------------------------------------------------------------------+
| DOCUMENT STRUCTURE (JSON)                                                               |
|                                                                                         |
| {                                                                                       |
|   "id": "uuid",                       // Unique event identifier                        |
|   "claimId": "uuid",                  // [Partition Key] Target claim                   |
|   "tenantId": "uuid",                 // Tenant boundary                                |
|   "eventType": "submitted_to_clearinghouse", // Enumerable event types                  |
|   "timestamp": "2026-05-19T10:00:00Z",// ISO8601 strict format                          |
|   "payload": {                        // Flexible schema per eventType                  |
|     "clearinghouse": "Waystar",                                                         |
|     "batchId": "B-99812",                                                               |
|     "transmissionTime": 45                                                              |
|   },                                                                                    |
|   "metadata": {                       // Traceability                                   |
|     "userId": "uuid",                                                                   |
|     "serviceVersion": "rcm-core@v1.4.2"                                                 |
|   },                                                                                    |
|   "_ttl": 63072000                    // 2-Year Auto-deletion (seconds)                 |
| }                                                                                       |
+-----------------------------------------------------------------------------------------+
| INDEXING POLICY                                                                         |
| Included Paths: /eventType/?, /tenantId/?, /timestamp/?                                 |
| Excluded Paths: /payload/* (Saves RU/s by not indexing dynamic payload keys)            |
+-----------------------------------------------------------------------------------------+
| CHANGE FEED                                                                             |
| Enabled. Consumed asynchronously by Azure Functions / analytics processors to update    |
| materialized views in Postgres.                                                         |
+-----------------------------------------------------------------------------------------+
```

## Schema Design Decisions
1. **Partition Strategy:** Using `/claimId` as the partition key ensures that all state changes for a single claim are co-located. This allows a Biller UI to query `WHERE claimId = X ORDER BY timestamp` using exactly 1 logical partition, costing minimal Request Units (RUs).
2. **Schema Flexibility:** The `payload` block is free-form JSON. An `eligibility_checked` event has wildly different properties than an `appeal_drafted` event. A NoSQL document store perfectly accommodates this polymorphism without massive, sparse relational tables.
3. **Optimized Indexing:** By actively excluding `/payload/*` from the CosmosDB automatic indexing policy, the platform saves significant write latency and RU costs, as these fields are strictly for display and not used in `WHERE` clauses.
4. **Automated Data Lifecycle:** The `_ttl` attribute is set to 2 years. CosmosDB will automatically delete expired documents in the background without consuming provisioned RUs, ensuring the event stream doesn't grow infinitely and cost millions.

## Interview Talking Points
- Emphasize the use of the **CosmosDB Change Feed**. It acts like a Kafka topic bolted onto a database. As events are written to CosmosDB, the Change Feed reliably broadcasts them to downstream analytics processors without requiring two-phase commits.
- Discuss why CosmosDB was chosen over Postgres for this specific workload. While Postgres is great for the current state (relational), appending 50+ lifecycle events per claim rapidly bloats relational tables. A hyper-scalable document DB is the industry standard for append-only event sourcing.
// ===== END OF FILE =====
