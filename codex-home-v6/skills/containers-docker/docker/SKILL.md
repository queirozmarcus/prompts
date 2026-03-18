# SKILL.md – Docker & Docker Compose (Advanced Skill)

## Scope

This file defines how Codex CLI should behave when working with **Docker and Docker Compose**, with an **advanced, production-oriented mindset**.

It applies to:
- Dockerfile authoring and optimization
- Multi-stage builds
- Docker Compose (local, CI, non-prod)
- Image size, security, and performance
- Container lifecycle, networking, and volumes
- Debugging containerized applications

Assume **containers may run in production or CI/CD** unless explicitly stated otherwise.

---

## Core Principles

- **Containers are immutable:** Rebuild, do not mutate
- **Small images are safer images**
- **Explicit is better than implicit**
- **One concern per container**
- **Build once, run everywhere**
- **Local parity with production matters**

---

## Dockerfile Standards

### Base Images
- Prefer:
  - `alpine`, `slim`, or distroless images
- Avoid:
  - Full OS images unless justified
- Always explain base image choice

### Multi-Stage Builds
- Prefer multi-stage builds by default
- Separate:
  - Build dependencies
  - Runtime environment
- Never ship compilers, package managers, or build tools in final image

### Layers & Caching
- Order layers to maximize cache reuse
- Group commands logically
- Avoid invalidating cache unnecessarily

### Security
- Avoid running as root unless required
- Prefer explicit `USER`
- Never bake secrets into images
- Highlight risks of:
  - `ADD` vs `COPY`
  - Curling scripts directly into shell

---

## Image Quality & Optimization

- Always consider:
  - Image size
  - Startup time
  - Attack surface
- Suggest:
  - `.dockerignore`
  - Minimal runtime dependencies
- Warn about:
  - Large base images
  - Unused files and layers

---

## Docker Compose Practices

### Intended Usage
- Use Docker Compose for:
  - Local development
  - CI environments
  - Lightweight non-production stacks
- Do NOT treat Compose as production orchestration unless explicitly justified

### Compose File Standards
- Prefer `docker compose` (v2+)
- Explicitly define:
  - Networks
  - Volumes
  - Environment variables
- Avoid:
  - Implicit default networks
  - Hardcoded secrets

### Service Design
- One service = one responsibility
- Avoid tight coupling via container names
- Use service names for DNS resolution

---

## Networking & Volumes

### Networking
- Explain:
  - Bridge vs custom networks
  - Service-to-service communication
- Avoid:
  - Exposing ports unnecessarily
- Prefer internal networks where possible

### Volumes
- Explain:
  - Named volumes vs bind mounts
- Warn about:
  - Persisting state unintentionally
  - Volume permission issues
- Avoid mounting sensitive host paths unless necessary

---

## Environment Variables & Secrets

- Prefer:
  - `.env` files (gitignored)
  - Runtime injection via CI/CD
- Never:
  - Commit `.env` files
  - Hardcode credentials
- Clearly explain:
  - Variable precedence
  - Runtime vs build-time variables

---

## Debugging Containers

When debugging:
1. Identify if issue is **build-time** or **runtime**
2. Inspect:
   - Logs
   - Image layers
   - Entrypoint / CMD behavior
3. Explain root cause before suggesting fixes
4. Avoid “just exec into container” as default advice

---

## Build & Run Safety

- Explain:
  - Difference between `ENTRYPOINT` and `CMD`
  - Impact of signal handling
- Prefer:
  - Explicit healthchecks
- Warn about:
  - Zombie processes
  - Improper PID 1 behavior

---

## Docker in CI/CD

- Prefer:
  - Deterministic builds
  - Versioned image tags (never only `latest`)
- Explain:
  - Cache strategies
  - Buildx and multi-arch when relevant
- Highlight:
  - Registry authentication risks
  - Secret leakage in build logs

---

## Anti-Patterns to Avoid

- Treating containers like VMs
- Installing packages at runtime
- Using `latest` in production
- Shipping debug tools in runtime image
- Mutating containers instead of rebuilding

---

## Communication Style (Docker Context)

- Be concise by default
- Expand when:
  - Security or production safety is involved
  - Image size or performance is impacted
- Always explain trade-offs and assumptions

---

## Expected Output Quality

Responses should:
- Explain **why** a Docker pattern is recommended
- Highlight security and performance implications
- Prefer reproducible and maintainable solutions
- Think like a **Container Platform Engineer**

---

**Skill type:** Passive  
**Applies with:** Root `AGENTS.md`  
**Pairs well with:** devops-engineer (Dev pack), `aws`, `kubernetes`, `ci-cd`, `security`  
**Override:** Project-level `AGENTS.md` may refine behavior
