// FILE: docs/diagrams/15-prompt-registry.md
---
# AI Architecture: Prompt Registry & Evaluation Loop

## Overview
This diagram illustrates the Prompt Registry and its associated Continuous Integration (CI) Evaluation Loop. By treating prompts as version-controlled code stored in YAML files, the platform ensures reproducibility, safety, and quantitative quality control over all generative AI interactions.

## Diagram
```text
+---------------------------------------------------------------------------------------------+
| 1. Developer / Prompt Engineer                                                              |
| Edits prompt template in Git repository                                                     |
|                                                                                             |
|   +--------------------------------------------------------------------------------------+  |
|   | rcm-rag/prompts/appeal_draft_v1.2.0.yaml                                             |  |
|   | ----------------------------------------                                             |  |
|   | id: "appeal_draft"                                                                   |  |
|   | version: "1.2.0"                                                                     |  |
|   | model: "gpt-4o"                                                                      |  |
|   | template: "You are a medical biller. Write an appeal for {denial_reason}..."         |  |
|   | output_schema: "AppealResponse" (Pydantic Model)                                     |  |
|   | metadata:                                                                            |  |
|   |   purpose: "Drafts level 1 appeals"                                                  |  |
|   |   eval_scores: { faithfulness: 0.98, carc_accuracy: 0.95, rouge_l: 0.88 ... }        |  |
|   +--------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------+
                                     |
    (Code Commit / Pull Request)     |
                                     v
+---------------------------------------------------------------------------------------------+
| 2. CI/CD Pipeline (GitHub Actions) -> The Eval Harness                                      |
|                                                                                             |
|   Runs automated tests using `EvalRunner` against a golden dataset of 500 denials.          |
|                                                                                             |
|   +-------------------+  [Compare]   +---------------------------------------+              |
|   | thresholds.yaml   | <----------> | New Eval Scores                       |              |
|   | faithfulness >0.95|              | faithfulness: 0.98 (PASS)             |              |
|   | carc_accuracy>0.90|              | carc_accuracy: 0.95 (PASS)            |              |
|   +-------------------+              +---------------------------------------+              |
|                                                                                             |
|   -> If PASS: Writes new scores into YAML metadata, allows merge to main.                   |
|   -> If FAIL: Blocks Pull Request.                                                          |
+---------------------------------------------------------------------------------------------+
                                     |
       (Deployment to Prod)          |
                                     v
+---------------------------------------------------------------------------------------------+
| 3. Application Runtime (rcm-rag Service)                                                    |
|                                                                                             |
|   +--------------------------------------------------------------------------------------+  |
|   | PromptRegistry Class                                                                 |  |
|   | - Loads all YAMLs into memory at startup                                             |  |
|   | - Exposes method: `get_prompt(id="appeal_draft", version="latest")`                  |  |
|   | - Resolves semver to return v1.2.0                                                   |  |
|   +--------------------------------------------------------------------------------------+  |
|                                     |                                                       |
|                                     v                                                       |
|   +--------------------------------------------------------------------------------------+  |
|   | LangChain Prompt Assembly                                                            |  |
|   | - Merges YAML template string with context variables (PHI redacted context)          |  |
|   | - Binds strict `output_schema` via Pydantic to the LLM call                          |  |
|   | - Executes API Call to Azure OpenAI                                                  |  |
|   +--------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------+
```

## Key Points
- **Prompts as Code:** Extracting prompts from Python code into isolated YAML files allows non-engineers (clinical experts) to tune prompt behavior without touching application logic.
- **Semantic Versioning (semver):** Prompts are versioned explicitly. The `PromptRegistry` can return `"latest"` for standard execution or a specific pinned version (e.g., `"1.1.0"`) for A/B testing or rollback.
- **Structured Output:** The YAML explicitly maps to a Pydantic `output_schema`. The application runtime enforces this schema on the LLM output, ensuring the pipeline never breaks due to unexpected string formats.
- **Quantitative Evaluation:** The CI Eval Harness automatically calculates RAG metrics (faithfulness, hallucination rates, cosine similarity to golden answers).

## Interview Talking Points
- Highlight the **CI gate based on thresholds**. Emphasize that "prompt engineering is software engineering." We do not allow prompt changes into production without mathematically proving they do not regress `carc_accuracy` or `faithfulness`.
- Discuss the value of saving **`eval_scores` directly in the YAML metadata**. This provides an immutable historical record of exactly how a prompt version performed on the golden dataset at the exact moment it was merged, making audits and debugging significantly easier.
// ===== END OF FILE =====
