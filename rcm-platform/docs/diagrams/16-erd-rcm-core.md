// FILE: docs/diagrams/16-erd-rcm-core.md
---
# Data Model: RCM Core ERD

## Overview
This Entity-Relationship Diagram outlines the `rcm` schema in PostgreSQL. It forms the transactional backbone of the RCM platform, storing multi-tenant operational data using strict constraints and financial accounting best practices.

## Diagram
```text
+-----------------------+       +-------------------------+       +-----------------------+
| tenants               |       | patients                |       | payers                |
|-----------------------|       |-------------------------|       |-----------------------|
| id UUID [PK]          |<-+    | id UUID [PK]            |<-+    | id UUID [PK]          |<-+
| name VARCHAR          |  |    | tenant_id UUID [FK]     |--+    | tenant_id UUID [FK]   |--+
| subdomain VARCHAR     |  |    | mrn VARCHAR(50)         |       | name VARCHAR          |  |
| status VARCHAR        |  |    | first_name VARCHAR      |       | payer_id_ext VARCHAR  |  |
| config JSONB          |  |    | last_name VARCHAR       |       | payer_type VARCHAR    |  |
| created_at TIMESTAMPTZ|  |    | date_of_birth DATE      |       | elig_endpoint VARCHAR |  |
+-----------------------+  |    | ssn_encrypted BYTEA     |       | claim_endpoint VARCHAR|  |
                           |    | gender VARCHAR(10)      |       | config JSONB          |  |
+-----------------------+  |    | address JSONB           |       | created_at TIMESTAMPTZ|  |
| feature_flags         |  |    | phone VARCHAR(20)       |       | updated_at TIMESTAMPTZ|  |
|-----------------------|  |    | email VARCHAR(255)      |       +-----------------------+  |
| id UUID [PK]          |  |    | insurance_info JSONB    |                  ^               |
| tenant_id UUID [FK]   |--+    | created_at TIMESTAMPTZ  |                  |               |
| flag_name VARCHAR(100)|       | updated_at TIMESTAMPTZ  |                  |               |
| enabled BOOLEAN       |       | deleted_at TIMESTAMPTZ  |                  |               |
| metadata JSONB        |       +-------------------------+                  |               |
+-----------------------+                  ^                 +---------------+               |
                                           |                 |                               |
+-----------------------+                  |                 |    +-----------------------+  |
| encounters            |                  |                 |    | eras                  |  |
|-----------------------|                  |                 |    |-----------------------|  |
| id UUID [PK]          |<-+               |                 |    | id UUID [PK]          |<-|--+
| tenant_id UUID [FK]   |--|---------------+                 |    | tenant_id UUID [FK]   |--|--|--+
| patient_id UUID [FK]  |--+                                 |    | payer_id UUID [FK]    |--+  |  |
| rend_prov_npi VARCHAR |  |                                 |    | era_date DATE         |     |  |
| bill_prov_npi VARCHAR |  |                                 |    | total_amt_cents INT   |     |  |
| facility_npi VARCHAR  |  |                                 |    | check_number VARCHAR  |     |  |
| service_date DATE     |  |                                 |    | raw_835_response TEXT |     |  |
| discharge_date DATE   |  |                                 |    | processed_at TIMESTAMP|     |  |
| place_of_service VCHAR|  |                                 |    | created_at TIMESTAMPTZ|     |  |
| encounter_type VARCHAR|  |                                 |    +-----------------------+     |  |
| status VARCHAR(20)    |  |                                 |                                  |  |
+-----------------------+  |                                 |    +-----------------------+     |  |
                           |                                 |    | payments              |     |  |
+-----------------------+  |                                 |    |-----------------------|     |  |
| claims                |  |                                 |    | id UUID [PK]          |     |  |
|-----------------------|  |                                 |    | tenant_id UUID [FK]   |-----+  |
| id UUID [PK]          |<-|---------------------------------|----| claim_id UUID [FK]    |        |
| tenant_id UUID [FK]   |--+                                 |    | era_id UUID [FK]      |--------+
| encounter_id UUID [FK]|--+                                 |    | payment_type VARCHAR  |
| patient_id UUID [FK]  |--+---------------------------------+    | amount_cents INTEGER  |
| payer_id UUID [FK]    |--+---------------------------------+    | payment_date DATE     |
| claim_type VARCHAR(10)|  |                                 |    | check_number VARCHAR  |
| status VARCHAR(30)    |  |    +-----------------------+    |    | eft_trace_num VARCHAR |
| tot_charge_cents INT  |  |    | claim_lines           |    |    +-----------------------+
| allowed_amt_cents INT |  |    |-----------------------|    |
| paid_amount_cents INT |  +--->| id UUID [PK]          |    |    +-----------------------+
| pat_resp_cents INTEGER|       | tenant_id UUID [FK]   |    +--->| denials               |
| scrub_result JSONB    |       | claim_id UUID [FK]    |         |-----------------------|
| edi_837_raw TEXT      |       | line_number INTEGER   |         | id UUID [PK]          |<-+
| claim_summary TEXT    |       | cpt_code VARCHAR(10)  |         | tenant_id UUID [FK]   |  |
| submitted_at TIMESTAMP|       | icd10_codes VARCHAR[] |         | claim_id UUID [FK]    |--+
| adjudicated_at TIMEST |       | modifiers VARCHAR[]   |         | denial_date DATE      |  |
+-----------------------+       | units INTEGER         |         | carc_code VARCHAR(10) |  |
                                | charge_cents INTEGER  |         | rarc_code VARCHAR(10) |  |
+-----------------------+       | allowed_cents INTEGER |         | denial_reason TEXT    |  |
| ar_balances           |       | paid_cents INTEGER    |         | status VARCHAR(30)    |  |
|-----------------------|       | revenue_code VARCHAR  |         | agent_run_id UUID     |  |
| id UUID [PK]          |       | service_date DATE     |         | explanation TEXT      |  |
| tenant_id UUID [FK]   |       +-----------------------+         +-----------------------+  |
| patient_id UUID [FK]  |                                                                    |
| claim_id UUID [FK]    |       +-----------------------+         +-----------------------+  |
| balance_cents INTEGER |       | eligibility_responses |         | appeals               |  |
| aging_bucket VARCHAR  |       |-----------------------|         |-----------------------|  |
| last_follow_up TIMEST |       | id UUID [PK]          |         | id UUID [PK]          |  |
+-----------------------+       | tenant_id UUID [FK]   |         | tenant_id UUID [FK]   |  |
                                | patient_id UUID [FK]  |         | denial_id UUID [FK]   |--+
                                | payer_id UUID [FK]    |         | draft_text TEXT       |
                                | check_date DATE       |         | approved_text TEXT    |
                                | coverage_active BOOL  |         | approved_by UUID      |
                                | deductible_cents INT  |         | approved_at TIMESTAMPT|
                                | copay_cents INTEGER   |         | submitted_at TIMESTAMP|
                                | raw_271_response TEXT |         | outcome VARCHAR(20)   |
                                +-----------------------+         | outcome_date DATE     |
                                                                  | usefulness_score INT  |
                                                                  +-----------------------+
```

## Schema Design Decisions
1. **Multi-Tenancy at the Foundation:** Every table explicitly includes `tenant_id UUID NOT NULL FK` alongside its primary key, allowing global Hibernate filtering and preventing catastrophic data leaks.
2. **Integer Math for Financials:** Financial fields (`tot_charge_cents`, `allowed_amt_cents`) are strictly stored as `INTEGER` representing cents to avoid floating-point rounding errors native to `DECIMAL/NUMERIC` types across different language runtimes.
3. **Pgcrypto for PHI:** Sensitive fields like `ssn_encrypted BYTEA` use native Postgres `pgcrypto` for column-level encryption, adding an extra layer of defense even if a database dump is compromised.
4. **Soft Deletes for Auditability:** `deleted_at TIMESTAMPTZ` allows soft-deleting patient and claim records. This preserves referential integrity for historical financial reporting while hiding records from active application views.

## Interview Talking Points
- Emphasize the **Integer Cents** pattern. It's a hallmark of experienced financial engineering. Mention that Stripe uses this exact same pattern to avoid IEEE 754 precision issues.
- Discuss how `claim_lines` normalizes the CPT and ICD-10 arrays. Storing ICD-10s as `VARCHAR(10)[]` (Postgres Arrays) provides the perfect balance: it allows indexable searches without requiring a massive, complex join table for what is essentially a bounded list of 1-12 codes per line.
// ===== END OF FILE =====
