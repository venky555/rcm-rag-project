// FILE: docs/diagrams/07-deployment-prod.md
---
# C4 Deployment Diagram: Production Environment

## Overview
This diagram illustrates the production deployment architecture of the RCM platform across a multi-AZ AWS environment with a hybrid integration to Azure CosmosDB. It details network segmentation, load balancing, container orchestration via ECS Fargate, and managed data stores.

## Diagram
```text
                                         +----------------+
                                         |    Internet    |
                                         +----------------+
                                                 | HTTPS
                                                 v
+-------------------------------------------------------------------------------------------------------------------+
| AWS Region: us-east-1                                                                                             |
|                                                                                                                   |
|  +-------------------------------------------------------------------------------------------------------------+  |
|  | VPC (Virtual Private Cloud)                                                                                 |  |
|  |                                                                                                             |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  |  | Public Subnets (Across 3 AZs)                                                                         |  |  |
|  |  |                                                                                                       |  |  |
|  |  |                    +------------------------------------------------------------------+               |  |  |
|  |  |                    | Application Load Balancer (ALB)                                  |               |  |  |
|  |  |                    | - /*        -> rcm-ui                                            |               |  |  |
|  |  |                    | - /graphql  -> rcm-bff                                           |               |  |  |
|  |  |                    | - /api/*    -> rcm-core                                          |               |  |  |
|  |  |                    | - /rag/*    -> rcm-rag                                           |               |  |  |
|  |  |                    +------------------------------------------------------------------+               |  |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  |                                               |                                                             |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  |  | Private Subnets (Across 3 AZs)             v                                                          |  |  |
|  |  |                                                                                                       |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  |  | ECS Cluster (Fargate Tasks - Auto-Scaling)                                                      |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +--------------+    +--------------+    +--------------+    +--------------+                   |  |  |  |
|  |  |  |  | rcm-ui ECS   |    | rcm-bff ECS  |    | rcm-core ECS |    | rcm-rag ECS  |                   |  |  |  |
|  |  |  |  +--------------+    +--------------+    +--------------+    +--------------+                   |  |  |  |
|  |  |  |                                                              +--------------+                   |  |  |  |
|  |  |  |                                                              | rcm-notify   |                   |  |  |  |
|  |  |  |                                                              | (Kafka only) |                   |  |  |  |
|  |  |  +--------------------------------------------------------------+--------------+                   |  |  |  |
|  |  |                                          |                                                         |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  |  | Managed Data Stores & Messaging       v                                                         |  |  |  |
|  |  |  |                                                                                                 |  |  |  |
|  |  |  |  +--------------------+  +--------------------+  +--------------------+  +-------------------+  |  |  |  |
|  |  |  |  | RDS PostgreSQL 16  |  | ElastiCache        |  | Amazon MSK         |  | DocumentDB        |  |  |  |  |
|  |  |  |  | (Multi-AZ, pgvector|  | (Redis 7 Cluster)  |  | (Kafka 3.7, 3 node)|  | (MongoDB compat.) |  |  |  |  |
|  |  |  |  +--------------------+  +--------------------+  +--------------------+  +-------------------+  |  |  |  |
|  |  |  +-------------------------------------------------------------------------------------------------+  |  |  |
|  |  +-------------------------------------------------------------------------------------------------------+  |  |
|  |                                                                                                             |  |
|  +-------------------------------------------------------------------------------------------------------------+  |
|                                                                                                                   |
|  +--------------------------+     +--------------------------+                                                    |
|  | AWS Secrets Manager      |     | CloudWatch               |                                                    |
|  | [Env Var Injection]      |     | [Logs, Metrics, Alarms]  |                                                    |
|  +--------------------------+     +--------------------------+                                                    |
+-------------------------------------------------------------------------------------------------------------------+
                                                                   |
                                                                   | HTTPS / SDK
                                                                   v
                                                  +--------------------------------+
                                                  | Azure Cloud                    |
                                                  |                                |
                                                  |  +--------------------------+  |
                                                  |  | CosmosDB (NoSQL API)     |  |
                                                  |  | [Multi-region write]     |  |
                                                  |  +--------------------------+  |
                                                  |  | Azure OpenAI             |  |
                                                  |  +--------------------------+  |
                                                  +--------------------------------+
```

## Key Points
- **Security via VPC:** All data stores and backend services reside in isolated private subnets, accessible only through the public-facing Application Load Balancer.
- **Managed Services:** Leverages highly available managed services (RDS, MSK, DocumentDB, ElastiCache) to drastically reduce operational overhead compared to self-hosting databases.
- **Serverless Compute:** ECS Fargate allows the platform to run containers without managing the underlying EC2 instances, supporting instant auto-scaling during traffic spikes.
- **Hybrid Cloud:** Securely integrates AWS infrastructure with Azure's CosmosDB for Change Feed capabilities and Azure OpenAI for enterprise-grade LLM models.
- **Centralized Configuration:** AWS Secrets Manager securely injects sensitive configurations directly into Fargate tasks at startup.

## Interview Talking Points
- Explain the choice of ECS Fargate: It eliminates instance-level management and patching, allows for task-level IAM role isolation, and ensures billing only for exact compute utilized.
- Emphasize the Multi-AZ setup for RDS and Amazon MSK, which guarantees high availability, durability of Kafka messages, and zero-downtime failover capabilities in the event of an availability zone outage.
// ===== END OF FILE =====
