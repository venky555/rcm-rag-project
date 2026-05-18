// FILE: docs/diagrams/11-multi-tenancy.md
---
# Security Architecture: Multi-Tenancy Data Isolation

## Overview
This diagram explains how the RCM platform ensures strict data isolation between different healthcare providers (tenants) within a shared database schema. It shows how the `tenant_id` automatically flows from the JWT down to the lowest database query levels without relying on developers to manually append `WHERE` clauses.

## Diagram
```text
+---------------------------------------------------------------------------------------------+
| 1. INGRESS: JWT Bearer Token                                                                |
|    Header:  {"alg": "RS256"}                                                                |
|    Payload: {"sub": "user_123", "role": "biller", "tenant_id": "T-999"}                     |
+---------------------------------------------------------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------------+
| 2. MIDDLEWARE / INTERCEPTOR                                                                 |
|    - Validates JWT signature via Keycloak JWKS                                              |
|    - Extracts "tenant_id" = "T-999"                                                         |
|    - Stores in ThreadLocal (Java), ContextVar (Python), or AsyncLocalStorage (Node)         |
+---------------------------------------------------------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------------+
| 3. ORM / DATA LAYER INTERCEPTION                                                            |
|                                                                                             |
|   rcm-core (Java/Hibernate)             rcm-rag (Python/SQLAlchemy)                         |
|   -------------------------             ---------------------------                         |
|   @Filter(name="tenantFilter")          @event.listens_for(Query, "before_compile")         |
|   session.enableFilter("tenantFilter")  query = query.filter(tenant_id == ctx_tenant_id)    |
|          .setParameter("id", "T-999")                                                       |
+---------------------------------------------------------------------------------------------+
                                     |
                                     v
===============================================================================================
                       SPLIT SCREEN: WHAT CODE SEES vs WHAT DB SEES
===============================================================================================

[ WHAT THE DEVELOPER WRITES ]                     [ WHAT THE DATABASE EXECUTES ]

// Fetch all claims for patient                   SELECT * FROM claims 
List<Claim> claims =                              WHERE patient_id = 'P-123'
    claimRepository.findByPatientId("P-123");     AND tenant_id = 'T-999';   <-- INJECTED

// Fetch specific denial                          SELECT * FROM denials
Denial denial =                                   WHERE denial_id = 'D-456'
    denialRepository.findById("D-456");           AND tenant_id = 'T-999';   <-- INJECTED

===============================================================================================
                                     |
                                     v
+---------------------------------------------------------------------------------------------+
| 4. OTHER DATA STORES                                                                        |
|                                                                                             |
|   Redis:         Prefixes keys -> GET "T-999:eligibility:P-123"                             |
|   Kafka:         Injects header -> Headers: { "tenantId": "T-999" }                         |
|   CosmosDB:      Uses as Partition Key -> ReadItemAsync(id, new PartitionKey("T-999"))      |
|   MongoDB:       Indexed field -> db.audit.find({ tenant_id: "T-999" })                     |
+---------------------------------------------------------------------------------------------+
```

## Key Points
- **Shared Schema, Isolated Data:** The platform uses a pooled multi-tenancy model (shared database, shared schema) where every table has a `tenant_id` column.
- **Implicit Filtering:** Developers do not write `WHERE tenant_id = ?`. It is injected automatically at the ORM layer (Hibernate/SQLAlchemy) to prevent accidental cross-tenant data leaks due to human error.
- **Ubiquitous Context:** The tenant context flows natively into all supporting infrastructure, acting as the partition key for CosmosDB and the namespace prefix for Redis caches.
- **Trustless Propagation:** Internal services don't blindly trust each other; `tenant_id` is passed via securely signed JWTs or validated Kafka headers.

## Interview Talking Points
- This is a masterclass in preventing catastrophic data leaks. If a developer forgets to check the tenant, the ORM intercepts the query and adds the constraint anyway.
- Emphasize the architectural elegance: Context variables (`ThreadLocal`/`AsyncLocalStorage`) bridge the gap between the HTTP request tier and the data access tier without polluting every method signature with a `tenantId` parameter.
// ===== END OF FILE =====
