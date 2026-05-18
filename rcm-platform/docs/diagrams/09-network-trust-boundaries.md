// FILE: docs/diagrams/09-network-trust-boundaries.md
---
# Security Architecture: Network Trust Boundaries

## Overview
This diagram illustrates the defense-in-depth network architecture of the RCM platform. It delineates the strict boundary lines between the public internet, the DMZ (public subnets), the application tier, and the highly secured data tier. 

## Diagram
```text
          [INTERNET ZONE]
                 |
                 v
  HTTPS (TLS 1.3) [Port 443]
                 |
+---------------------------------------------------------------------------------------------------+
| VPC BOUNDARY                                                                                      |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | PUBLIC SUBNET (DMZ / Ingress Tier)                                                          |  |
|  |                                                                                             |  |
|  |       [WAF] --> Filters Malicious Traffic (SQLi, XSS)                                       |  |
|  |         |                                                                                   |  |
|  |         v                                                                                   |  |
|  |  +---------------------------+                                                              |  |
|  |  | Application Load Balancer | ** TLS TERMINATION POINT **                                  |  |
|  |  | (ALB)                     | -> Re-encrypts traffic before forwarding                     |  |
|  |  +---------------------------+                                                              |  |
|  +---------------------------------------------------------------------------------------------+  |
|                 |                                                                                 |
|                 v  HTTPS (TLS 1.2/1.3) [Port 443, 8081, 8082, 8084]                               |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | PRIVATE SUBNET A (Application Tier)                                                         |  |
|  | Security Group: Allow Ingress ONLY from ALB Security Group                                  |  |
|  |                                                                                             |  |
|  |  +-----------+   mTLS    +-----------+   mTLS    +-----------+   mTLS    +---------------+  |  |
|  |  | rcm-ui    |<--------->| rcm-bff   |<--------->| rcm-core  |<--------->| rcm-rag       |  |  |
|  |  | [ECS Task]|           | [ECS Task]|           | [ECS Task]|           | [ECS Task]    |  |  |
|  |  +-----------+           +-----------+           +-----------+           +---------------+  |  |
|  |                                                        |                         |          |  |
|  |                                                        |                         |          |  |
|  +---------------------------------------------------------------------------------------------+  |
|                 |                                         |                         |             |
|                 v                                         v                         v             |
|  +---------------------------------------------------------------------------------------------+  |
|  | PRIVATE SUBNET B (Data Tier)                                                                |  |
|  | Security Group: Allow Ingress ONLY from App Tier Security Group                             |  |
|  |                                                                                             |  |
|  |  +-------------------+  +-------------------+  +-------------------+  +------------------+  |  |
|  |  | PostgreSQL (RDS)  |  | Redis ElastiCache |  | MSK (Kafka)       |  | DocumentDB       |  |  |
|  |  | [Port 5432]       |  | [Port 6379]       |  | [Port 9094]       |  | [Port 27017]     |  |  |
|  |  | TLS Enforced      |  | TLS + Auth        |  | TLS + SASL Auth   |  | TLS Enforced     |  |  |
|  |  +-------------------+  +-------------------+  +-------------------+  +------------------+  |  |
|  |                                                                                             |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

## Key Points
- **Strict Network Segmentation:** The public internet only touches the ALB. All compute (ECS) and data (RDS/MSK) reside in private subnets with no public IP addresses.
- **TLS Termination & Re-encryption:** The ALB terminates the external TLS connection (to inspect traffic via WAF) but strictly re-encrypts the traffic before forwarding it to the private subnet ECS tasks.
- **Service Mesh / mTLS:** Traffic between `rcm-ui`, `rcm-bff`, `rcm-core`, and `rcm-rag` is secured using mutual TLS (mTLS) to cryptographically guarantee service identity.
- **Zero Trust Security Groups:** The Data Tier security groups do NOT allow VPC-wide access; they explicitly whitelist ONLY the Application Tier security group ID.

## Interview Talking Points
- When asked about network security, emphasize **"Defense in Depth"**: we rely on network boundaries (Subnets), routing restrictions (No IGW for private), firewall rules (Security Groups), and cryptographic identity (mTLS).
- Highlight that even if the private network was compromised, the internal traffic is entirely encrypted (mTLS and TLS to databases), meaning an attacker cannot sniff PHI packets off the wire.
// ===== END OF FILE =====
