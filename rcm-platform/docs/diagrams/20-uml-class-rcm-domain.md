// FILE: docs/diagrams/20-uml-class-rcm-domain.md
---
# Domain Model: RCM Core (UML Class Diagram)

## Overview
This UML Class Diagram models the core Revenue Cycle Management (RCM) domain using Domain-Driven Design (DDD) principles. It highlights the strict boundaries around Aggregate Roots, the encapsulation of behavior, and the heavy reliance on immutable Value Objects for complex types.

## Diagram
```text
  +-----------------------------------+             +----------------------------------+
  | <<Aggregate Root>>                |             | <<Value Object>>                 |
  | Patient                           |◆─────────── | Demographics                     |
  |-----------------------------------|             |----------------------------------|
  | - id: PatientId                   |             | - firstName: String              |
  | - tenantId: TenantId              |             | - lastName: String               |
  | - mrn: String                     |             | - dateOfBirth: Date              |
  | - demographics: Demographics      |             | - gender: String                 |
  | - insuranceInfo: InsuranceInfo    |             | - address: JSON                  |
  |-----------------------------------|             | - phone: String                  |
  | + register()                      |             | - email: String                  |
  | + updateDemographics(Demographics)|             +----------------------------------+
  | + addInsurance(InsuranceInfo)     |
  +-----------------------------------+             +----------------------------------+
                    ◆                               | <<Value Object>>                 |
                    │                               | InsuranceInfo                    |
                    └────────────────────────────── |----------------------------------|
                                                    | - payerId: UUID                  |
  +-----------------------------------+             | - memberId: String               |
  | <<Entity>>                        |             | - groupNumber: String            |
  | Encounter                         |◆──┐         | - coverageType: String           |
  |-----------------------------------|   │         +----------------------------------+
  | - id: UUID                        |   │
  | - patientId: UUID                 |   │         +----------------------------------+
  | - renderingProviderNpi: String    |   │         | <<Value Object>>                 |
  | - billingProviderNpi: String      |   └──────── | ChargeItem                       |
  | - serviceDate: Date               |             |----------------------------------|
  | - placeOfService: String          |             | - cptCode: CptCode               |
  | - status: String                  |             | - diagnosisCodes: DiagnosisCode[]|
  |-----------------------------------|             | - modifiers: String[]            |
  | + addChargeItem(ChargeItem)       |             | - units: int                     |
  | + submit()                        |             | - chargeAmount: Money            |
  +-----------------------------------+             +----------------------------------+

  +-----------------------------------+             +----------------------------------+
  | <<Aggregate Root>>                |             | <<Entity>>                       |
  | Claim                             |◆──────────* | ClaimLine                        |
  |-----------------------------------|             |----------------------------------|
  | - id: ClaimId                     |             | - lineNumber: int                |
  | - tenantId: TenantId              |             | - cptCode: String                |
  | - encounterId: UUID               |             | - icd10Codes: String[]           |
  | - patientId: UUID                 |             | - modifiers: String[]            |
  | - payerId: UUID                   |             | - units: int                     |
  | - status: ClaimStatus             |             | - chargeAmount: Money            |
  | - lines: List<ClaimLine>          |             | - allowedAmount: Money           |
  | - totalCharge: Money              |             | - paidAmount: Money              |
  | - scrubResult: ClaimScrubResult   |             +----------------------------------+
  | - summary: ClaimSummary           |
  |-----------------------------------|             +----------------------------------+
  | + scrub()                         |             | <<Value Object>>                 |
  | + submit()                        |◆─────────── | ClaimScrubResult                 |
  | + markPaid(Money)                 |             |----------------------------------|
  | + deny(CarcCode, RarcCode)        |             | - passed: boolean                |
  | + appeal()                        |             | - issues: List<ScrubIssue>       |
  +-----------------------------------+             | - scrubbedAt: Instant            |
                    ◇                               +----------------------------------+
                    │
                    │ (1)                           +----------------------------------+
                    │                               | <<Value Object>>                 |
  +-----------------------------------+             | Money                            |
  | <<Aggregate Root>>                |             |----------------------------------|
  | Denial                            |◆─────────── | - amountCents: int                 |
  |-----------------------------------|             | - currency: String               |
  | - id: DenialId                    |             |----------------------------------|
  | - claimId: ClaimId                |             | + add(Money): Money              |
  | - carcCode: CarcCode              |             | + subtract(Money): Money         |
  | - rarcCode: RarcCode              |             | + multiply(int): Money           |
  | - status: DenialStatus            |             +----------------------------------+
  | - appealDraft: AppealDraft        |
  | - agentRunId: UUID                |             +----------------------------------+
  |-----------------------------------|             | <<Value Object>>                 |
  | + triage()                        |◆─────────── | AppealDraft                      |
  | + startAgentAnalysis()            |             |----------------------------------|
  | + draftAppeal(String)             |             | - draftText: String              |
  | + approveAppeal(String, UUID)     |             | - approvedText: String           |
  | + submit()                        |             | - approvedBy: UUID               |
  +-----------------------------------+             | - approvedAt: Instant            |
                                                    +----------------------------------+
```

## Schema Design Decisions
1. **Aggregate Root Boundaries:** The `Claim` acts as an Aggregate Root over `ClaimLine`. This guarantees that operations (like calculating the `totalCharge`) always run through the `Claim` object, maintaining consistency across the internal boundaries.
2. **Value Object Immutability:** Types like `Money` and `Demographics` are designated as Value Objects. They have no identity of their own and are fully immutable, heavily reducing side-effects when changing financial math.
3. **Behavior Encapsulation:** Entities contain rich behavior (methods like `.submit()` or `.deny()`) instead of acting as simple anemic data wrappers (getters/setters). State changes are forced through strictly defined verbs.
4. **Composition over Association:** A `Patient` physically contains their `Demographics` (Composition ◆). If the `Patient` is deleted, the `Demographics` disappears. A `Claim` points to an `Encounter` but does not own it (Aggregation ◇).

## Interview Talking Points
- When asked about **Domain-Driven Design**, emphasize the importance of the **Aggregate Root**. An external service wanting to add a line to a claim MUST call `claim.addLine(...)`, not `lineRepository.save(...)`. This prevents invalid states (like lines without claims).
- Highlight the **Money Value Object**. Because it encapsulates `amountCents` and `currency` together with methods like `add()`, it makes cross-currency and floating-point rounding bugs mathematically impossible across the RCM domain.
// ===== END OF FILE =====
