// FILE: docs/diagrams/13-agent-architecture.md
---
# AI Architecture: LangGraph Denial Resolution Agent

## Overview
This diagram illustrates the state machine architecture of the AI agent responsible for resolving medical claim denials. Built using LangGraph, it outlines the exact sequence of nodes, conditional routing logic, tool usage, and the critical Human-in-the-Loop (HITL) interrupt that suspends the agent until a Medical Biller approves the drafted appeal.

## Diagram
```text
                       [ TRIGGER: denial.received ]
                                  |
                                  v
+-----------------------------------------------------------------------------------+
| LangGraph State Machine (DenialResolutionGraph)                                   |
|                                                                                   |
|                              +--------+                                           |
|                              | START  |                                           |
|                              +--------+                                           |
|                                  |                                                |
|                                  v                                                |
|                            +-----------+                                          |
|                            | 1. triage |--------------------------+               |
|                            +-----------+                          |               |
|                                  | [simple / complex]             | [escalate]    |
|                                  v                                |               |
|  +----------------+        +---------------+                      |               |
|  | CarcLookupTool |<------>| 2. lookup_carc|                      |               |
|  +----------------+        +---------------+                      |               |
|                                  |                                |               |
|                                  v                                |               |
|  +-----------------+     +----------------------+                 |               |
|  | PayerPolicyTool |<--->| 3. fetch_payer_policy|                 |               |
|  +-----------------+     +----------------------+                 |               |
|                                  |                                |               |
|                                  v                                |               |
|  +----------------------+ +---------------------------+           |               |
|  | MedicalNecessityTool |<| 4. check_medical_necessity|           |               |
|  +----------------------+ +---------------------------+           |               |
|                                  |                                |               |
|                                  v                                |               |
|                            +----------------+ <---------------+   |               |
|  +-----------------+       | 5. draft_appeal|                 |   |               |
|  | AppealDraftTool |<----->|                |                 |   |               |
|  +-----------------+       +----------------+                 |   |               |
|                                  | [always]                   |   |               |
|                                  v                            |   |               |
|                      =========================                |   |               |
|                      ||   6. human_review   || [reject]       |   |               |
|                      ||  (INTERRUPT NODE)   ||----------------+   |               |
|                      =========================                    |               |
|                                  | [approve]                      |               |
|                                  v                                |               |
|                            +-------------+                        |               |
|                            | 7. finalize |<-----------------------+               |
|                            +-------------+                                        |
|                                  |                                                |
|                                  v                                                |
|                              +-------+                                            |
|                              |  END  |                                            |
|                              +-------+                                            |
+-----------------------------------------------------------------------------------+
                                  |
                                  v
                     [ PUBLISH: denial.explained ]
```

## Key Points
- **State Machine Paradigm:** Execution flow is deterministic and graph-based. The `AgentState` object passes continuously through the nodes, accumulating fetched context before generating the final appeal.
- **Tools as Code:** Nodes 2, 3, 4, and 5 utilize specialized python tools. Tools like `PayerPolicyTool` perform semantic vector searches via `pgvector`, retrieving exact guidelines to ground the LLM.
- **Conditional Routing:** The `triage` node explicitly acts as a guardrail. If it identifies a highly sensitive or totally unworkable denial, it routes directly to `finalize` (escalation), saving expensive LLM processing cycles.
- **Human-in-the-Loop (HITL):** Node 6 (`human_review`) uses LangGraph's native interrupt capability to halt the state machine, persist the state to PostgreSQL, and safely wait (hours or days) for UI input.

## Interview Talking Points
- Highlight the **resiliency of LangGraph's state persistence**. Because the state is saved to Postgres at every node, if the `rcm-rag` container crashes during step 4, it automatically resumes exactly where it left off upon restart.
- Discuss the **rejection loop**. If a biller rejects the draft at step 6 and provides feedback ("mention the patient's age"), the graph conditionally routes back to step 5 to re-draft, providing the LLM with the new human feedback context.
// ===== END OF FILE =====
