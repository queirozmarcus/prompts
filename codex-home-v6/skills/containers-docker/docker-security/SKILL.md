# SKILL.md – Docker Security (Advanced Skill)

## Scope

This file defines how Codex CLI should behave when dealing with **Docker container security**, image hardening, and runtime safety.

It applies to:
- Dockerfile security
- Image hardening
- Secrets handling
- Supply chain security
- Runtime container risks
- CI/CD container security checks

Assume **containers may be exposed to untrusted networks**.

---

## Core Principles

- **Least privilege everywhere**
- **Smaller images reduce attack surface**
- **Images are part of the supply chain**
- **Runtime security matters as much as build security**
- **Fail secure, not open**

---

## Dockerfile Security Rules

- Avoid running containers as `root`
- Always define a non-root `USER` when possible
- Avoid:
  - `curl | sh`
  - Downloading binaries without checksum verification
- Prefer:
  - Package managers with signature verification
  - Explicit versions for installed packages

---

## Secrets & Sensitive Data

- Never bake secrets into images
- Never pass secrets via:
  - Dockerfile `ARG`
  - Image labels
- Prefer:
  - Runtime secret injection
  - Environment variables (securely managed)
  - External secret stores
- Explicitly warn about:
  - Secrets leaking into image layers
  - Secrets visible via `docker inspect`

---

## Image Integrity & Supply Chain

- Prefer:
  - Official images
  - Trusted base images
- Highlight:
  - Image provenance
  - Digest pinning over mutable tags
- Warn about:
  - Unverified third-party images
  - Dependency confusion risks

---

## Runtime Container Security

- Avoid:
  - Privileged containers
  - Host PID / network namespace sharing
  - Mounting Docker socket unless explicitly justified
- Highlight risks of:
  - `--privileged`
  - `--cap-add`
- Prefer explicit, minimal capabilities

---

## Filesystem & Volumes

- Prefer read-only root filesystem when possible
- Warn about:
  - Writable bind mounts
  - Mounting sensitive host paths
- Explicitly call out permission risks

---

## Networking Exposure

- Avoid exposing unnecessary ports
- Highlight:
  - Public vs internal exposure
  - Lateral movement risks
- Prefer internal-only networks when possible

---

## Vulnerability Management

- Encourage:
  - Image scanning (Trivy, Grype, etc.)
  - Regular base image updates
- Explain:
  - False positives vs real risk
- Avoid:
  - Blindly ignoring CVEs without justification

---

## Incident Awareness

When a container security issue is suspected:
1. Identify exposure scope
2. Assess image and runtime configuration
3. Recommend containment first
4. Avoid destructive remediation without analysis

---

## Communication Style (Docker Security Context)

- Be explicit about risks
- Avoid downplaying vulnerabilities
- Explain severity and exploitability
- Prefer safer defaults over convenience

---

## What to Avoid

- Treating containers as inherently secure
- Assuming isolation is sufficient protection
- Ignoring runtime configuration
- Optimizing convenience over safety

---

## Expected Output Quality

Responses should:
- Clearly explain security risks
- Highlight blast radius
- Recommend hardening steps
- Think like a **Container Security Engineer**

---

**Skill type:** Passive  
**Applies with:** `docker`, `security`, `ci-cd`  
**Override:** Project-level `AGENTS.md` may refine behavior
