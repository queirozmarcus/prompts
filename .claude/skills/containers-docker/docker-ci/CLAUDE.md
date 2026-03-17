# CLAUDE.md – Docker in CI/CD (Advanced Skill)

## Scope

This file defines how Claude Code should behave when using **Docker within CI/CD pipelines**.

It applies to:
- Image build pipelines
- CI Docker caching strategies
- Multi-arch builds
- Registry interactions
- Secure image publishing

Assume **automated pipelines and shared runners**.

---

## Core Principles

- **Builds must be deterministic**
- **Pipelines are production systems**
- **Security failures should fail the pipeline**
- **Speed matters, but correctness matters more**

---

## Docker Build in CI

- Prefer:
  - `docker buildx`
  - Explicit build contexts
- Avoid:
  - Implicit `latest` tags
  - Unpinned base images
- Encourage:
  - Reproducible builds
  - Build arguments only when unavoidable

---

## Caching Strategy

- Explain:
  - Layer caching behavior
  - Cache invalidation risks
- Prefer:
  - Registry-based cache
  - BuildKit cache exports
- Warn about:
  - Cache poisoning
  - Stale dependency layers

---

## Image Tagging Strategy

- Require:
  - Immutable tags (commit SHA, version)
- Discourage:
  - Using only `latest`
- Explain:
  - Promotion via re-tagging
  - Traceability from image to commit

---

## Registry & Authentication

- Prefer:
  - Short-lived credentials
  - OIDC-based authentication
- Warn about:
  - Secrets leaking into logs
  - Long-lived registry tokens
- Explain permission scopes clearly

---

## Multi-Architecture Builds

- Explain:
  - amd64 vs arm64 implications
  - Cross-compilation costs
- Avoid multi-arch unless there is a real need
- Highlight build time impact

---

## Security in CI

- Encourage:
  - Image scanning as pipeline step
  - Failing builds on critical vulnerabilities
- Explain trade-offs:
  - Speed vs security
- Avoid skipping security checks for convenience

---

## Pipeline Failure Handling

When Docker steps fail:
1. Identify if issue is **build**, **push**, or **runtime**
2. Explain failure cause
3. Propose minimal, safe fixes
4. Avoid retrying blindly

---

## Communication Style (Docker CI Context)

- Be concise and structured
- Explain CI-specific risks
- Prefer actionable guidance

---

## What to Avoid

- Building images differently per environment
- Using mutable tags across environments
- Publishing images without traceability
- Hiding Docker errors with retries

---

## Expected Output Quality

Responses should:
- Emphasize reproducibility and safety
- Explain CI/CD trade-offs
- Encourage clean, auditable pipelines
- Think like a **CI/CD Platform Engineer**

---

**Skill type:** Passive  
**Applies with:** `docker`, `ci-cd`, `github-actions`, `security`  
**Override:** Project-level `CLAUDE.md` may refine behavior
