# Playbook: Dependency Update

## Purpose

Safe, systematic process for updating project dependencies. Ensures security vulnerabilities are addressed, breaking changes are identified before they cause incidents, and updates are validated with tests before merging. Applicable to npm/Node.js, Python/pip, Java/Maven, and Docker base images.

## Inputs

- [ ] `PROJECT_DIR` — root of the project to update
- [ ] `ECOSYSTEM` — npm | pip | maven | docker
- [ ] `UPDATE_TYPE` — security-only | minor | major | all

---

## Phase 1: Audit Current State

```bash
cd ${PROJECT_DIR}

# ---- Node.js / npm ----
# Check for known vulnerabilities
npm audit --json | jq '{
  critical: .metadata.vulnerabilities.critical,
  high: .metadata.vulnerabilities.high,
  moderate: .metadata.vulnerabilities.moderate,
  low: .metadata.vulnerabilities.low
}'

# List outdated packages
npm outdated

# ---- Python / pip ----
pip-audit --format json 2>/dev/null | jq '.dependencies[] | select(.vulns | length > 0) | {name:.name,version:.version,vulns:[.vulns[].id]}'

# Or with safety
pip install safety
safety check --json

# Outdated packages
pip list --outdated

# ---- Java / Maven ----
mvn versions:display-dependency-updates -DprocessAllModules=true | grep '\->'
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=0 -Dformat=JSON

# ---- Docker base images ----
# Check current base image vulnerability count
docker images --format "{{.Repository}}:{{.Tag}}" | grep -v '<none>' | while read image; do
  echo "=== $image ==="
  trivy image --quiet --severity CRITICAL,HIGH --ignore-unfixed "$image" 2>/dev/null | tail -5
done
```

**Gate: Do not proceed if CRITICAL CVEs exist — fix those first.**

---

## Phase 2: Prioritize Updates

Categorize pending updates to focus effort:

| Priority | Criteria | Action |
|----------|---------|--------|
| **P0: Block** | CRITICAL CVE in production dependency | Fix immediately, no tests required to skip |
| **P1: This week** | HIGH CVE or actively exploited vulnerability | Prioritize in current sprint |
| **P2: This sprint** | MODERATE CVE, outdated by 2+ minor versions | Include in regular sprint work |
| **P3: Next sprint** | LOW CVE, minor cosmetic updates | Batch with other P3 items |

```bash
# npm: show only critical and high CVEs with remediation
npm audit --audit-level=high 2>&1 | head -100

# Identify direct dependencies with critical issues (easier to update than transitive)
npm audit --json | jq '.vulnerabilities | to_entries[] | select(.value.severity == "critical" or .value.severity == "high") | {name: .key, severity: .value.severity, fixAvailable: .value.fixAvailable}'
```

---

## Phase 3: Incremental Update Strategy

**Never update everything at once.** Update incrementally to isolate regressions:

```bash
# ---- npm: update security fixes only (safest first) ----
npm audit fix               # Auto-fix non-breaking vulnerabilities
npm audit fix --force       # Force breaking changes (review diff after!)

# Update a single package to understand changes
npm update lodash           # Minor/patch only
npm install lodash@latest   # Latest (may be major version bump)

# ---- npm: batch similar update types ----
# Update all patch versions (generally safe)
npx npm-check-updates -u --target patch
npm install

# Update all minor versions (check changelogs)
npx npm-check-updates -u --target minor
npm install

# Major versions: update one at a time (read migration guide first)
npx npm-check-updates -u lodash express --target latest
npm install

# ---- Python: update incrementally ----
# Update single package
pip install --upgrade requests

# Recompile lockfile with latest compatible versions
pip-compile requirements.in --upgrade-package requests

# Update all packages (conservative: respects version pins)
pip-compile requirements.in --upgrade
pip-sync requirements.txt

# ---- Docker: update base image ----
# In Dockerfile, change:
# FROM node:20.11-alpine3.19
# TO:
# FROM node:20.18-alpine3.21  # Check Docker Hub for latest LTS patch

# Rebuild and scan new base image
docker build -t myapp:updated .
trivy image --exit-code 1 --severity CRITICAL,HIGH --ignore-unfixed myapp:updated
```

---

## Phase 4: Review Breaking Changes

**For any major version bump, check the changelog/migration guide before updating:**

```bash
# npm: check changelog for a package
npm show express@5.0.0 description  # Check if major version exists
# Visit: https://github.com/expressjs/express/releases

# Check if breaking changes affect your code
# Run grep to find usage patterns
grep -r "require('express')" src/ --include="*.js" | head -20

# Python: check migration guide
pip show fastapi  # Shows homepage URL
# Visit changelog: https://github.com/tiangolo/fastapi/releases

# Docker: check base image release notes
# node:20 -> node:22 is a major Node.js upgrade — check Node.js release notes
```

**Breaking change risk categories:**
- API/function signature changes → grep for usage + update call sites
- Removed features → grep for deprecated patterns
- Behavior changes → run full test suite and integration tests
- Configuration changes → check .conf, .rc, YAML config files

---

## Phase 5: Test Gates

All update PRs must pass these gates before merge:

```bash
# Gate 1: No new critical/high CVEs introduced
npm audit --audit-level=high
# OR
pip-audit --fail-on-vuln

# Gate 2: Tests pass (unit + integration)
npm test
# OR
pytest --tb=short -q

# Gate 3: Test coverage maintained (not degraded)
npm run test:coverage
# Ensure coverage % didn't drop significantly

# Gate 4: Lint passes (updated packages may introduce new lint warnings)
npm run lint
# OR
ruff check . && mypy src/

# Gate 5: Staging smoke test (for backend services)
# Deploy to staging and run smoke test suite
curl -sf https://api-staging.example.com/health

# Gate 6: Build succeeds (for Docker/bundled apps)
npm run build
docker build -t myapp:updated . --no-cache
```

---

## Phase 6: GitHub Actions Automation

```yaml
# .github/workflows/dependency-update.yml
name: Dependency Audit

on:
  schedule:
    - cron: '0 8 * * 1'  # Every Monday at 8 AM UTC
  workflow_dispatch:

permissions:
  contents: read
  security-events: write

jobs:
  audit-npm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Audit dependencies
        run: npm audit --audit-level=high
      - name: Upload audit report
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: npm-audit-${{ github.run_id }}
          path: npm-audit.json

  audit-docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      - name: Scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
          ignore-unfixed: 'true'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif
```

**Dependabot for automated PR creation:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "08:00"
      timezone: UTC
    groups:
      # Group minor/patch updates together (one PR)
      minor-and-patch:
        update-types:
          - minor
          - patch
    ignore:
      # Major version bumps need manual review
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
    labels: [dependencies, security]
    reviewers: [security-team]

  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
    groups:
      dependencies:
        patterns: ["*"]

  - package-ecosystem: docker
    directory: /
    schedule:
      interval: weekly

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

---

## Quick Reference: Rollback

```bash
# If a dependency update causes issues in staging/production:

# npm: rollback to previous lockfile
git checkout package-lock.json
npm ci

# pip: rollback to previous requirements
git checkout requirements.txt
pip-sync requirements.txt

# Docker: rollback to previous base image tag
# In Dockerfile, revert FROM line to previous tag
# Rebuild image

# git: create revert PR
git revert <commit-sha>
gh pr create --title "revert: dependency update causing {issue}" --base main
```

---

## Update Report Template

```markdown
## Dependency Update Report — {date}

**Project:** {project}
**Ecosystem:** npm / pip / docker

### Security Findings (Pre-Update)
| Package | CVE | Severity | Status |
|---------|-----|---------|--------|
| express | CVE-2024-XXXX | HIGH | Fixed in 4.19.0 |

### Updates Applied
| Package | From | To | Type | Breaking? |
|---------|------|----|------|----------|
| express | 4.18.0 | 4.19.0 | PATCH | No |
| lodash | 4.17.19 | 4.17.21 | PATCH | No |

### Gates
- [ ] npm audit --audit-level=high: PASS
- [ ] Tests (npm test): PASS — coverage 84%
- [ ] Build (npm run build): PASS
- [ ] Staging smoke test: PASS

### Remaining Issues (not fixed in this PR)
- CVE-2024-YYYY in `dep-x` — no fix available; tracking in JIRA-123
```

---
**Used by:** ci-agent, personal-engineering-agent
**Related playbooks:** security-audit.md
**Related skills:** nodejs, python, github-actions
