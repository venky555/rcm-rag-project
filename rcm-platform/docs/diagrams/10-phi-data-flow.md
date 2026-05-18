// FILE: docs/diagrams/10-phi-data-flow.md
---
# Security Architecture: PHI Data Flow

## Overview
This is the "HIPAA Hero" diagram. It traces the complete lifecycle of Protected Health Information (PHI) through the system, highlighting exactly where encryption, redaction, rehydration, and audit logging occur to maintain strict compliance.

## Diagram
```text
   [Medical Biller]
         |
         | (1) Submits Patient Demographics / Encounter
         | [ENCRYPTED IN TRANSIT - TLS 1.3]
         v
+------------------+
| rcm-bff          | (2) Validates JWT, logs API request -> [MASKED IN LOGS]
+------------------+     (PHI stripped from log output via pino-redact)
         |
         | (3) Forwards to Core [ENCRYPTED IN TRANSIT - mTLS]
         v
+------------------+ (4) Audits access -> [AUDIT LOGGED] in MongoDB
| rcm-core         | (5) Persists to DB -> [ENCRYPTED AT REST]
| [Spring Boot]    |     (pgcrypto column-level encryption for SSN/DOB)
+------------------+
         |
         | (6) Initiates Claim Scrubbing (gRPC) [ENCRYPTED IN TRANSIT]
         v
+------------------+ (7) Prepares LLM Prompt
| rcm-rag          | (8) Presidio analyzes text -> [REDACTED]
| [Python]         |     "Patient John Doe (DOB: 01/01/80)" becomes "Patient [NAME_1] (DOB: [DATE_1])"
+------------------+     Saves mapping to secure local Redis [ENCRYPTED AT REST]
         |
         | (9) Calls LLM [ENCRYPTED IN TRANSIT]
         v
+------------------+ ** ZERO PHI REACHES AZURE OPENAI **
| Azure OpenAI     | -> Generates response based purely on clinical/billing context
+------------------+
         |
         | (10) Returns generated response
         v
+------------------+ (11) Reads mapping from Redis
| rcm-rag          | (12) Replaces tokens with real PHI -> [REHYDRATED]
| [Python]         |      "Patient [NAME_1]" restored to "John Doe"
+------------------+
         |
         | (13) Returns scrubbed claim / explanation (gRPC) [ENCRYPTED IN TRANSIT]
         v
+------------------+ (14) Publishes event to Kafka (e.g., denial.explained)
| rcm-core         |      [ENCRYPTED IN TRANSIT] & [ENCRYPTED PAYLOAD]
+------------------+
         |
         v
+------------------+ (15) Consumes Kafka event
| rcm-notify       | (16) Anonymizes data for Email/SMS (e.g., "A claim for J.D. was updated")
| [Node.js]        | (17) Logs action -> [AUDIT LOGGED]
+------------------+
```

## Key Points
- **Encryption Everywhere:** PHI is encrypted in transit across every single network hop (TLS/mTLS) and encrypted at rest (column-level in RDS, encrypted Redis caches).
- **PHI Redaction for AI:** The `rcm-rag` service completely strips PHI before any data leaves the VPC to hit Azure OpenAI. It maintains an internal, short-lived mapping dictionary to rehydrate the text when the LLM responds.
- **Masking:** Application loggers explicitly mask identified PHI fields (like SSN, names, addresses) so developers viewing Datadog or Loki never see sensitive data.
- **Audit Logging:** Any interaction with a patient record in `rcm-core` triggers an asynchronous write to the MongoDB audit log, detailing *Who*, *What*, *When*, and *Where*.

## Interview Talking Points
- This diagram proves HIPAA compliance is treated as an architectural primitive, not an afterthought. The redaction/rehydration pattern guarantees we can use cutting-edge LLMs without signing complex BAAs for third-party model training.
- Highlight the distinction between "Masked in Logs" (which is permanent loss of data in logging systems for safety) and "Redacted/Rehydrated" (which is temporary substitution to safely use an external processor).
// ===== END OF FILE =====
