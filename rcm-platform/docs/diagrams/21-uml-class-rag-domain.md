// FILE: docs/diagrams/21-uml-class-rag-domain.md
---
# Domain Model: RAG Pipeline (UML Class Diagram)

## Overview
This diagram maps the domain model for the Python-based `rcm-rag` service. It focuses on the Retrieval-Augmented Generation (RAG) entities: how documents are broken into chunks and embeddings, and how prompts are structured and evaluated.

## Diagram
```text
  +-----------------------------------+             +----------------------------------+
  | <<Entity>>                        |             | <<Entity>>                       |
  | RagDocument                       |◆──────────* | RagChunk                         |
  |-----------------------------------|             |----------------------------------|
  | - id: UUID                        |             | - id: UUID                       |
  | - tenantId: UUID                  |             | - documentId: UUID               |
  | - sourceType: String              |             | - chunkIndex: int                |
  | - sourceName: String              |             | - content: String                |
  | - payerId: UUID                   |             | - tokenCount: int                |
  | - effectiveDate: Date             |             | - metadata: JSON                 |
  | - content: String                 |             +----------------------------------+
  | - metadata: JSON                  |                              ◆
  |-----------------------------------|                              │
  | + chunk(SemanticChunker)          |                              │ (1)
  +-----------------------------------+                              │
                                                    +----------------------------------+
  +-----------------------------------+             | <<Value Object>>                 |
  | <<Entity>>                        |             | RagEmbedding                     |
  | PromptVersion                     |             |----------------------------------|
  |-----------------------------------|             | - id: UUID                       |
  | - id: String                      |             | - chunkId: UUID                  |
  | - version: String                 |             | - embedding: list[float]         |
  | - model: String                   |             | - modelVersion: String           |
  | - template: String                |             +----------------------------------+
  | - outputSchema: String            |
  | - evalScores: EvalScores          |             +----------------------------------+
  |-----------------------------------|             | <<Value Object>>                 |
  | + format(context: dict): String   |             | EvalScores                       |
  +-----------------------------------+             |----------------------------------|
                    ◆                               | - faithfulness: float            |
                    │                               | - answerRelevance: float         |
                    └────────────────────────────── | - recallAt5: float               |
                                                    | - bleu4: float                   |
  +-----------------------------------+             | - rougeL: float                  |
  | <<Value Object>>                  |             | - cosineSimilarity: float        |
  | RetrievalQuery                    |             | - carcAccuracy: float            |
  |-----------------------------------|             | - usefulnessP50: float           |
  | - tenantId: UUID                  |             +----------------------------------+
  | - queryText: String               |
  | - queryEmbedding: list[float]     |             +----------------------------------+
  | - filters: dict                   |             | <<Entity>>                       |
  | - topK: int                       |             | CachedLlmResponse                |
  |-----------------------------------|             |----------------------------------|
  | + hash(): String                  |             | - queryHash: String              |
  +-----------------------------------+             | - promptVersionId: String        |
                    │                               | - chunkIds: list[UUID]           |
        generates   │                               | - queryEmbedding: list[float]    |
                    v                               | - responseText: String           |
  +-----------------------------------+             | - hitCount: int                  |
  | <<Value Object>>                  |             |----------------------------------|
  | RetrievalResult                   |             | + recordHit()                    |
  |-----------------------------------|             +----------------------------------+
  | - chunks: list[RagChunk]          |
  | - scores: list[float]             |
  | - retrievalLatencyMs: int         |
  +-----------------------------------+
```

## Schema Design Decisions
1. **Separation of Concerns (Chunk vs Embedding):** A single `RagChunk` explicitly owns a `RagEmbedding`. This composition prevents model drift—if the platform upgrades to a new embedding model, new `RagEmbedding` objects are created without losing the original text chunks.
2. **Semantic Hashing:** The `RetrievalQuery` Value Object encapsulates the `.hash()` function. This is critical for the `CachedLlmResponse` to map incoming, lexically varying text to semantically identical cached answers.
3. **Prompt Encapsulation:** `PromptVersion` abstracts the raw prompt string behind a `.format()` behavior, ensuring contexts (like patient data) are properly injected before leaving the domain.
4. **Immutable Evals:** `EvalScores` is modeled as a strict Value Object. When a prompt is run against the evaluation harness, it produces a fixed score snapshot tied exactly to that `PromptVersion`.

## Interview Talking Points
- Point out how **RAG translates perfectly to DDD**. Just like transactional business models, AI pipelines have domain entities with strict invariants. The `RagDocument` is the Aggregate Root here; if it is deleted, all its Chunks and Embeddings must cascade out.
- Discuss the immutability of `RetrievalResult`. It acts as an event payload passed downstream, guaranteeing that the exact chunks retrieved for a generation attempt are preserved for auditability.
// ===== END OF FILE =====
