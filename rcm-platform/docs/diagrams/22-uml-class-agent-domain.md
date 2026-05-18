// FILE: docs/diagrams/22-uml-class-agent-domain.md
---
# Domain Model: LangGraph Agent (UML Class Diagram)

## Overview
This UML diagram details the class structure of the Python-based AI Agent. It leverages inheritance and the command-pattern (via abstract Nodes) to structure the LangGraph workflow. It clearly delineates the data state (`AgentState`) from the execution logic (`AgentNode` and `AgentTool`).

## Diagram
```text
  +-----------------------------------+
  | <<Value Object>> (TypedDict)      |
  | AgentState                        |
  |-----------------------------------|
  | - denialId: UUID                  |
  | - tenantId: UUID                  |
  | - carcCode: String                |
  | - rarcCode: String                |
  | - claimContext: String            |
  | - retrievedPolicies: list[String] |
  | - retrievedMedicalNecessity: list |
  | - appealDraft: String             |
  | - humanFeedback: String           |
  | - currentNode: String             |
  | - messages: list[AnyMessage]      |
  | - interrupted: boolean            |
  | - agentRunId: UUID                |
  +-----------------------------------+
                    ^
                    │ reads / mutates
                    │
  +-----------------------------------+             +----------------------------------+
  | <<Abstract Class>>                |             | <<Abstract Class>>               |
  | AgentNode                         | ◇────────── | AgentTool                        |
  |-----------------------------------|             |----------------------------------|
  | + name: String                    |             | + name: String                   |
  |-----------------------------------|             | + description: String            |
  | + execute(state: AgentState):     |             |----------------------------------|
  |                 AgentState        |             | + invoke(input: dict): Any       |
  +-----------------------------------+             +----------------------------------+
        △              △         △                          △              △
        │              │         │                          │              │
        │              │         │                          │              │
  +------------+ +-----------+ +-------------+       +---------------+ +---------------+
  | TriageNode | | Draft     | | Finalize    |       | CarcLookupTool| | PayerPolicy   |
  |            | | AppealNode| | Node        |       |               | | Tool          |
  +------------+ +-----------+ +-------------+       +---------------+ +---------------+
  + classify()   + assemble()  + persist()           + invoke()        + invoke()
                 + call_llm()  + publish()           
                 + validate()

  +-----------------------------------+             +----------------------------------+
  | <<Aggregate Root>>                |             | <<Service>>                      |
  | DenialResolutionGraph             | ──────────▷ | AgentStatePersistence            |
  |-----------------------------------|             |----------------------------------|
  | - nodes: dict[str, AgentNode]     |             |----------------------------------|
  | - edges: list[tuple]              |             | + save(state: AgentState)        |
  |-----------------------------------|             | + load(runId: UUID): AgentState  |
  | + compile(): CompiledGraph        |             +----------------------------------+
  | + stream(state: AgentState)       |
  +-----------------------------------+
```

## Schema Design Decisions
1. **TypedDict State:** The `AgentState` utilizes Python's `TypedDict` rather than a heavy ORM or Pydantic model. LangGraph fundamentally operates on passing a mutable dictionary between node edges, and `TypedDict` provides compile-time safety without runtime overhead.
2. **Command Pattern Nodes:** Every state machine step inherits from the abstract `AgentNode`. This strictly isolates responsibilities. The `DraftAppealNode` only knows how to draft appeals; it cannot alter triage logic.
3. **Tool Aggregation:** `AgentNode`s explicitly aggregate `AgentTool`s. A node doesn't contain the raw logic to search vector databases; it invokes a `PayerPolicyTool` to fetch data, preserving single-responsibility.
4. **State Persistence Injection:** The `DenialResolutionGraph` depends on an external `AgentStatePersistence` service. This keeps database interactions (PostgreSQL) completely out of the AI workflow definitions, ensuring the graph is highly testable.

## Interview Talking Points
- Highlight the **Command Pattern** in the agent architecture. Each LangGraph step is encapsulated in an `AgentNode` that receives and returns the `AgentState`.
- Discuss **TypeDicts in Python** for `AgentState`. Using `TypedDict` ensures all nodes implicitly agree on the keys and types being passed between them. When the graph compiles, it uses these type definitions to validate edge connections.
// ===== END OF FILE =====
