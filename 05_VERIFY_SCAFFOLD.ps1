# ============================================================
# SAVE THIS AS: verify-scaffold.ps1
# Run after scaffold.ps1 to confirm all canonical files exist.
# ============================================================

param([string]$RootDir = "rcm-platform")

$ErrorActionPreference = "Continue"
$missing = @()
$found   = 0

function Check-File {
    param([string]$Path)
    $fullPath = Join-Path $RootDir $Path
    if (Test-Path $fullPath) {
        $script:found++
    } else {
        $script:missing += $Path
    }
}

# Canonical file list — must match 02_CANONICAL_FILE_TREE.md exactly
$canonicalFiles = @(
    # Root
    "Makefile", "README.md", "CONTRIBUTING.md", ".gitignore",
    ".gitattributes", ".editorconfig", ".pre-commit-config.yaml",
    "commitlint.config.js",
    # GitHub
    ".github/workflows/rcm-core-ci.yml",
    ".github/workflows/rcm-rag-ci.yml",
    ".github/workflows/rcm-notify-ci.yml",
    ".github/workflows/rcm-bff-ci.yml",
    ".github/workflows/rcm-ui-ci.yml",
    ".github/workflows/contract-tests.yml",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/CODEOWNERS",
    # Infrastructure
    "infrastructure/docker-compose.yml",
    "infrastructure/.env.example",
    "infrastructure/terraform/main.tf",
    "infrastructure/observability/prometheus/prometheus.yml",
    "infrastructure/observability/grafana/provisioning/datasources/datasources.yml",
    "infrastructure/kafka/topics.yml",
    "infrastructure/seed-data/carc-codes.sql",
    # Proto
    "proto/rcm/v1/claim_scrubbing.proto",
    # rcm-core key files
    "rcm-core/build.gradle",
    "rcm-core/settings.gradle",
    "rcm-core/Dockerfile",
    "rcm-core/app/src/main/java/com/rcm/RcmCoreApplication.java",
    "rcm-core/app/src/main/resources/application.yml",
    "rcm-core/app/src/main/resources/db/migration/V001__create_extensions.sql",
    "rcm-core/app/src/main/resources/db/migration/V016__create_materialized_views.sql",
    "rcm-core/common/src/main/java/com/rcm/common/audit/AuditAspect.java",
    "rcm-core/common/src/main/java/com/rcm/common/multitenancy/TenantContext.java",
    "rcm-core/claims/src/main/java/com/rcm/claims/grpc/ClaimScrubGrpcClient.java",
    "rcm-core/claims/src/main/java/com/rcm/claims/kafka/ClaimEventPublisher.java",
    "rcm-core/claims/src/main/java/com/rcm/claims/cosmosdb/ClaimEventStreamClient.java",
    "rcm-core/denials/src/main/java/com/rcm/denials/kafka/DenialReceivedConsumer.java",
    # rcm-rag key files
    "rcm-rag/pyproject.toml",
    "rcm-rag/Dockerfile",
    "rcm-rag/rcm_rag/main.py",
    "rcm-rag/rcm_rag/agent/graph.py",
    "rcm-rag/rcm_rag/agent/nodes/human_review.py",
    "rcm-rag/rcm_rag/common/phi_redactor.py",
    "rcm-rag/rcm_rag/prompts/registry.py",
    "rcm-rag/rcm_rag/llm/client.py",
    "rcm-rag/rcm_rag/grpc/claim_scrub_servicer.py",
    "rcm-rag/evals/runner.py",
    "rcm-rag/evals/thresholds.yaml",
    # rcm-notify key files
    "rcm-notify/package.json",
    "rcm-notify/Dockerfile",
    "rcm-notify/src/index.ts",
    "rcm-notify/src/kafka/consumer.ts",
    # rcm-bff key files
    "rcm-bff/package.json",
    "rcm-bff/Dockerfile",
    "rcm-bff/src/index.ts",
    "rcm-bff/src/schema/typeDefs/claim.graphql",
    "rcm-bff/src/api/sse.ts",
    # rcm-ui key files
    "rcm-ui/package.json",
    "rcm-ui/Dockerfile",
    "rcm-ui/app/claims/page.tsx",
    "rcm-ui/app/denials/[denialId]/page.tsx",
    "rcm-ui/components/denials/AppealDraftEditor.tsx"
)

Write-Host "`nVerifying scaffold against canonical file tree..." -ForegroundColor Cyan

foreach ($file in $canonicalFiles) { Check-File $file }

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  Found   : $found / $($canonicalFiles.Count)" -ForegroundColor Green

if ($missing.Count -eq 0) {
    Write-Host "  Missing : 0 — scaffold is complete!" -ForegroundColor Green
    Write-Host "`nReady to start DeepSeek prompts. Begin with PROMPT-001." -ForegroundColor Cyan
} else {
    Write-Host "  Missing : $($missing.Count)" -ForegroundColor Red
    Write-Host "`nMissing files:" -ForegroundColor Red
    foreach ($f in $missing) { Write-Host "  - $f" -ForegroundColor Red }
    Write-Host "`nRe-run scaffold.ps1 or create missing files manually." -ForegroundColor Yellow
}
