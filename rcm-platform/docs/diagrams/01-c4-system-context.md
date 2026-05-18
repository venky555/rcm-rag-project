// FILE: docs/diagrams/01-c4-system-context.md
---
# C4 Level 1: System Context Diagram

## Overview
This System Context diagram illustrates the Revenue Cycle Management (RCM) Platform from a high-level perspective. It maps out how the core platform interacts with human users (Medical Billers, RCM Admins), external healthcare systems (EHR, Clearinghouse, Payers), and cloud-based AI providers (Azure OpenAI) to automate and manage the end-to-end claim lifecycle.

## Diagram
```text
                  +-------------------+                +-------------------+
                  |                   |                |                   |
                  |  Medical Biller   |                |     RCM Admin     |
                  |     [Person]      |                |     [Person]      |
                  |                   |                |                   |
                  +---------+---------+                +---------+---------+
                            |                                    |
                            | Views claims, manages denials,     | Configures payers,
                            | approves appeals [HTTPS/UI]        | reviews reports [HTTPS/UI]
                            |                                    |
                            v                                    v
+-----------------------------------------------------------------------------------------+
|                                                                                         |
|                                                                                         |
|                                 Revenue Cycle Management                                |
|                                      (RCM) Platform                                     |
|                                     [Software System]                                   |
|                                                                                         |
|    Production-grade platform that automates claim scrubbing, denial management,         |
|    and AI-assisted workflows. Integrates with EHR, Clearinghouses, and Payers.          |
|                                                                                         |
|                                                                                         |
+----+-------------+--------------------+---------------------+---------------------+-----+
     |             |                    |                     |                     |
     | 837 / 835   | 270 / 271          | Patient Data        | Embeddings / LLM    | OIDC
     | EDI         | Eligibility        | [REST/HL7]          | [REST/HTTPS]        | [HTTPS]
     v             v                    v                     v                     v
+----+----+   +----+----+          +----+----+           +----+----+           +----+----+
|         |   |         |          |         |           |         |           |         |
| Clearing|   |  Payer  |          |   EHR   |           |  Azure  |           | Identity|
|  house  |   | Systems |          | System  |           | OpenAI  |           | Provider|
| [System]|   |[System] |          | [System]|           | [System]|           | [System]|
|         |   |         |          |         |           |         |           |         |
+---------+   +---------+          +---------+           +---------+           +---------+
```

## Key Points
- **Central System:** The RCM Platform acts as the central hub connecting front-end users to back-end healthcare and AI systems.
- **Human Actors:** Medical Billers and RCM Admins interact with the system via a secure, web-based UI over HTTPS.
- **Clearinghouse & Payers:** The platform exchanges standardized EDI formats (837 claims, 835 ERAs, 270/271 eligibility) to process financial transactions.
- **EHR System:** Serves as the source of truth for patient demographics and clinical documentation, accessed via REST or HL7.
- **Azure OpenAI:** Provides the external intelligence layer for semantic search, embeddings, and generative tasks over REST/HTTPS.
- **Identity Provider:** Centralizes authentication and authorization using OIDC protocols for all internal and external access.

## Interview Talking Points
- The architecture cleanly decouples the RCM transactional core from external dependencies, ensuring resilience if the clearinghouse or EHR goes down.
- By abstracting the AI provider (Azure OpenAI) behind the platform boundary, we can easily swap LLM vendors or use local models without affecting the UI or external systems.
- Emphasize how integrating OIDC at the system boundary ensures compliance with HIPAA requirements for secure authentication.
// ===== END OF FILE =====
