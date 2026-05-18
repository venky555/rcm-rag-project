# Section 3 — Pinned Tech Stack
# STATUS: LOCKED
#
# Every DeepSeek prompt that creates a dependency file (build.gradle,
# pyproject.toml, package.json) must use these exact versions.
# Do not use "latest". Do not upgrade without updating this file first.

---

## rcm-core — Java / Spring Boot

| Dependency | Version | Purpose |
|---|---|---|
| Java | 21 (LTS) | Language version — virtual threads available |
| Spring Boot | 3.3.5 | Framework version |
| Spring Security | 6.3.x (via Boot BOM) | Security |
| Spring Data JPA | 3.3.x (via Boot BOM) | ORM |
| Spring Data Redis | 3.3.x (via Boot BOM) | Redis client |
| Spring Kafka | 3.3.x (via Boot BOM) | Kafka producer/consumer |
| Spring AI | 1.0.0-M3 | In-Java LLM calls (claim summarization) |
| Hibernate | 6.5.x (via Boot BOM) | JPA implementation |
| Flyway | 10.15.x (via Boot BOM) | DB migrations |
| MapStruct | 1.6.2 | DTO mapping |
| Resilience4j | 2.2.0 | Circuit breaker, retry, timeout |
| Caffeine | 3.1.8 | L1 in-process cache |
| grpc-java | 1.65.1 | gRPC client |
| protobuf-java | 4.27.3 | Protocol Buffers |
| net.devh grpc-spring-boot-starter | 3.1.0 | gRPC + Spring integration |
| JJWT | 0.12.6 | JWT parsing |
| Micrometer | 1.13.x (via Boot BOM) | Metrics |
| opentelemetry-spring-boot-starter | 2.6.0 | OTel auto-instrumentation |
| Logback | 1.5.x (via Boot BOM) | Logging |
| logstash-logback-encoder | 8.0 | JSON log output |
| pgcrypto | Postgres extension | Column-level encryption |
| Jackson | 2.17.x (via Boot BOM) | JSON |
| JUnit 5 | 5.10.x (via Boot BOM) | Testing |
| Mockito | 5.12.x (via Boot BOM) | Mocking |
| Testcontainers | 1.20.1 | Integration test infrastructure |
| Pact JVM | 4.6.14 | Contract testing (consumer) |
| Gradle | 8.9 | Build tool |
| Spotless | 6.25.0 | Code formatting |
| Checkstyle | 10.17.0 | Style enforcement |
| Azure SDK for Java (Cosmos) | 4.62.0 | CosmosDB NoSQL API client |
| Azure OpenAI Java client | 1.0.0-beta.11 | (via Spring AI) |
| MongoDB driver (sync) | 5.1.4 | Audit log writes |

**build.gradle (root) key plugins:**
```groovy
plugins {
    id 'org.springframework.boot' version '3.3.5'
    id 'io.spring.dependency-management' version '1.1.6'
    id 'com.diffplug.spotless' version '6.25.0'
    id 'com.google.protobuf' version '0.9.4'
    id 'jacoco'
}
java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }
```

---

## rcm-rag — Python / FastAPI

| Dependency | Version | Purpose |
|---|---|---|
| Python | 3.12.x | Language version |
| FastAPI | 0.115.0 | Web framework |
| Uvicorn | 0.30.6 | ASGI server |
| Pydantic | 2.8.2 | Data validation + structured output |
| pydantic-settings | 2.4.0 | Config from env |
| SQLAlchemy | 2.0.35 | ORM (async) |
| asyncpg | 0.29.0 | Async Postgres driver |
| psycopg2-binary | 2.9.9 | Sync Postgres driver (Flyway compat) |
| pgvector | 0.3.2 | pgvector Python client |
| LlamaIndex | 0.11.2 | Ingestion pipeline |
| llama-index-vector-stores-postgres | 0.2.2 | pgvector store for LlamaIndex |
| LangChain | 0.3.1 | Orchestration |
| LangGraph | 0.2.16 | Agent state machine |
| langchain-openai | 0.2.1 | Azure OpenAI client |
| langchain-community | 0.3.1 | Community integrations |
| faiss-cpu | 1.8.0 | FAISS in-memory index |
| sentence-transformers | 3.1.1 | Self-hosted embedding model |
| presidio-analyzer | 2.2.354 | PHI detection |
| presidio-anonymizer | 2.2.354 | PHI redaction |
| aiokafka | 0.11.0 | Async Kafka client |
| motor | 3.5.1 | Async MongoDB client |
| azure-cosmos | 4.7.0 | CosmosDB NoSQL client |
| redis[asyncio] | 5.0.8 | Async Redis client |
| grpcio | 1.66.1 | gRPC server |
| grpcio-tools | 1.66.1 | Proto code generation |
| opentelemetry-sdk | 1.27.0 | OTel SDK |
| opentelemetry-instrumentation-fastapi | 0.48b0 | Auto-instrumentation |
| prometheus-client | 0.21.0 | Metrics |
| structlog | 24.4.0 | Structured logging |
| tiktoken | 0.7.0 | Token counting |
| ragas | 0.1.21 | RAG eval (faithfulness etc.) |
| evaluate | 0.4.3 | HuggingFace eval (BLEU, ROUGE, BERTScore) |
| cachetools | 5.5.0 | L1 in-process cache |
| tenacity | 9.0.0 | Retry logic |
| python-jose | 3.3.0 | JWT validation |
| pytest | 8.3.3 | Testing |
| pytest-asyncio | 0.24.0 | Async test support |
| pytest-cov | 5.0.0 | Coverage |
| testcontainers | 4.8.1 | Integration test infra |
| pact-python | 2.2.1 | Contract testing (provider) |
| ruff | 0.6.5 | Linting + formatting |
| mypy | 1.11.2 | Type checking |
| httpx | 0.27.2 | Async HTTP client |

**pyproject.toml structure:**
```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "rcm-rag"
version = "0.1.0"
requires-python = ">=3.12"
# dependencies listed with exact versions above

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.mypy]
python_version = "3.12"
strict = true
```

---

## rcm-notify — Node.js / Express

| Dependency | Version | Purpose |
|---|---|---|
| Node.js | 20.x LTS | Runtime |
| TypeScript | 5.5.4 | Language |
| Express | 4.19.2 | Web framework |
| KafkaJS | 2.2.4 | Kafka client |
| Nodemailer | 6.9.14 | Email delivery |
| Handlebars | 4.7.8 | Email templates |
| pg | 8.12.0 | Postgres client (notification_log) |
| @opentelemetry/sdk-node | 0.53.0 | OTel SDK |
| @opentelemetry/auto-instrumentations-node | 0.49.1 | Auto-instrumentation |
| prom-client | 15.1.3 | Prometheus metrics |
| pino | 9.4.0 | Structured logging |
| pino-pretty | 11.2.2 | Dev log formatting |
| jose | 5.6.3 | JWT validation |
| zod | 3.23.8 | Input validation |
| ts-node | 10.9.2 | TypeScript execution |
| tsx | 4.19.1 | Fast TypeScript runner |
| vitest | 2.0.5 | Testing framework |
| testcontainers | 10.10.4 | Integration test infra |
| eslint | 9.9.1 | Linting |
| prettier | 3.3.3 | Formatting |

---

## rcm-bff — Node.js / Apollo / GraphQL

| Dependency | Version | Purpose |
|---|---|---|
| Node.js | 20.x LTS | Runtime |
| TypeScript | 5.5.4 | Language |
| Express | 4.19.2 | HTTP server |
| @apollo/server | 4.11.0 | GraphQL server |
| graphql | 16.9.0 | GraphQL runtime |
| @graphql-tools/merge | 9.0.5 | Merge type defs |
| dataloader | 2.2.2 | N+1 batching |
| axios | 1.7.7 | REST calls to rcm-core |
| pg | 8.12.0 | Postgres (materialized views) |
| graphql-ws | 5.16.0 | WS transport (optional) |
| @opentelemetry/sdk-node | 0.53.0 | OTel |
| @opentelemetry/auto-instrumentations-node | 0.49.1 | Auto-instrumentation |
| prom-client | 15.1.3 | Metrics |
| pino | 9.4.0 | Logging |
| jose | 5.6.3 | JWT |
| zod | 3.23.8 | Validation |
| @pact-foundation/pact | 13.1.4 | Pact consumer test |
| vitest | 2.0.5 | Testing |
| testcontainers | 10.10.4 | Integration test infra |
| eslint | 9.9.1 | Linting |
| prettier | 3.3.3 | Formatting |

---

## rcm-ui — Next.js

| Dependency | Version | Purpose |
|---|---|---|
| Node.js | 20.x LTS | Runtime |
| Next.js | 14.2.10 | Framework (App Router) |
| React | 18.3.1 | UI library |
| TypeScript | 5.5.4 | Language |
| Tailwind CSS | 3.4.10 | Styling |
| @apollo/client | 3.11.4 | GraphQL client |
| graphql | 16.9.0 | GraphQL runtime |
| next-auth | 4.24.7 | Auth (Keycloak OIDC) |
| @tanstack/react-query | 5.56.2 | Server state management |
| zod | 3.23.8 | Form validation |
| @playwright/test | 1.47.2 | E2E testing |
| vitest | 2.0.5 | Unit testing |
| @testing-library/react | 16.0.1 | Component testing |
| eslint-config-next | 14.2.10 | ESLint config |
| prettier | 3.3.3 | Formatting |

---

## Infrastructure versions (docker-compose)

| Service | Image | Version |
|---|---|---|
| PostgreSQL | postgres | 16.4-alpine |
| pgvector | ankane/pgvector | v0.7.4 (or pg16 image with ext) |
| MongoDB | mongo | 7.0.14 |
| Redis | redis | 7.2.5-alpine |
| Apache Kafka | confluentinc/cp-kafka | 7.7.1 |
| Zookeeper | confluentinc/cp-zookeeper | 7.7.1 |
| Keycloak | quay.io/keycloak/keycloak | 25.0.6 |
| Azure Cosmos Emulator | mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator | latest |
| Prometheus | prom/prometheus | v2.54.1 |
| Grafana | grafana/grafana | 11.2.0 |
| Loki | grafana/loki | 3.1.1 |
| Tempo | grafana/tempo | 2.5.0 |
| Mimir | grafana/mimir | 2.13.0 |
| Ollama | ollama/ollama | 0.3.10 |

---

## Shared tooling

| Tool | Version | Purpose |
|---|---|---|
| Docker Desktop | 4.34.x | Container runtime |
| Docker Compose | 2.29.x | Local orchestration |
| Git | 2.46.x | Version control |
| pre-commit | 3.8.0 | Git hooks |
| gitleaks | 8.18.4 | Secrets scanning |
| git-cliff | 2.4.0 | Changelog generation |
| commitlint | 19.4.1 | Commit message linting |
| Terraform | 1.9.5 | IaC (stubs only) |
| protoc | 27.3 | Protocol Buffer compiler |
| buf | 1.39.0 | Protobuf linting + breaking change detection |

---

## Proto toolchain note

The `proto/rcm/v1/claim_scrubbing.proto` file is compiled as part of both
the rcm-core Gradle build (via `com.google.protobuf` plugin) and the
rcm-rag build (via `grpcio-tools`).

Generated files (`*_pb2.py`, `*_pb2_grpc.py`, `ClaimScrubbingGrpc.java`)
are git-ignored and regenerated on each build.
`buf lint` and `buf breaking` run in CI to enforce proto style and
detect breaking changes.
