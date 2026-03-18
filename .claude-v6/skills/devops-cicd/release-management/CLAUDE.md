# Skill: Release Management

## Scope

Structured release process covering semantic versioning, automated changelog generation from Conventional Commits, GitHub Releases, release branches, hotfix workflows, and release communication. Applies to any project that ships versioned artifacts to users or downstream consumers.

## Related Agent: cicd-engineer (DevOps pack)
## Related Playbook: (none specific — use ci-cd patterns)

## Core Principles

- **Every release is traceable** — git tag → changelog → GitHub Release → artifact; full lineage
- **Semantic versioning** — version numbers communicate intent (breaking/feature/fix)
- **Automate the boring** — changelogs and release notes are generated, not hand-written
- **Release branches for stability** — long-lived support branches for production hotfixes
- **No surprises** — release candidates validated in staging before production promotion
- **Rollback plan mandatory** — every release ships with its rollback procedure

## Semantic Versioning (SemVer)

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
  1   .  2  .  3  -  rc.1
```

| Change | Version Bump | Example |
|--------|-------------|---------|
| Breaking API change | MAJOR | 1.x.x → 2.0.0 |
| New backwards-compatible feature | MINOR | 1.1.x → 1.2.0 |
| Backwards-compatible bug fix | PATCH | 1.1.1 → 1.1.2 |
| Pre-release / release candidate | Suffix | 2.0.0-rc.1 |

**Rules:**
- `0.x.x` — initial development; anything can change; no SemVer guarantees
- `1.0.0` — first stable public API; SemVer guarantees apply
- MAJOR bump resets MINOR and PATCH to 0
- PATCH bump only for bug fixes; adding any new feature = MINOR minimum

## Conventional Commits → Automated Versioning

Conventional Commits enables automated version bumping and changelog generation:

```
type(scope): description

BREAKING CHANGE: <description>  ← triggers MAJOR bump
feat(auth): add OAuth2 support   ← triggers MINOR bump
fix(api): resolve race condition  ← triggers PATCH bump
```

**Type → version bump mapping:**
| Commit type | Version impact |
|-------------|---------------|
| `feat:` | MINOR |
| `fix:` | PATCH |
| `perf:` | PATCH |
| `BREAKING CHANGE:` footer | MAJOR |
| `feat!:` or `fix!:` (!) | MAJOR |
| `docs:`, `chore:`, `style:`, `refactor:`, `test:`, `ci:` | No bump |

## Tooling

### semantic-release (fully automated)

```bash
npm install --save-dev semantic-release \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github

# .releaserc.json
{
  "branches": ["main", {"name": "beta", "prerelease": true}],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", {
      "changelogFile": "CHANGELOG.md"
    }],
    "@semantic-release/npm",
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version} [skip ci]"
    }],
    "@semantic-release/github"
  ]
}
```

### conventional-changelog (changelog only)

```bash
npx conventional-changelog-cli -p angular -i CHANGELOG.md -s

# With first release
npx conventional-changelog-cli -p angular -i CHANGELOG.md -s -r 0
```

### release-please (Google's tool, GitHub-native)

```yaml
# .github/workflows/release-please.yml
name: Release Please
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        with:
          release-type: node
          token: ${{ secrets.GITHUB_TOKEN }}
```

## Release Workflow

### Standard Release (trunk-based)

```
main ──●──●──●──●──●── (continuous delivery)
           │
           └── v1.2.0 tag + GitHub Release
```

```bash
# Automated via semantic-release on push to main
# Manual alternative:

# 1. Ensure main is green
git checkout main && git pull

# 2. Bump version
npm version minor  # or major / patch / prerelease
# → Updates package.json, creates v1.2.0 tag

# 3. Generate changelog
npx conventional-changelog-cli -p angular -i CHANGELOG.md -s

# 4. Commit and push
git add CHANGELOG.md package.json
git commit -m "chore(release): 1.2.0 [skip ci]"
git push origin main --follow-tags

# 5. Create GitHub Release
gh release create v1.2.0 \
  --title "v1.2.0" \
  --generate-notes \
  --latest
```

### Release Branch Workflow (for long-term support)

```
main ──────────────────────────────── (v2.x development)
         │
    release/1.x ──●──●──●──●─────── (v1.x maintenance)
                  │     │
                 v1.1.0  v1.1.1 (hotfix)
```

```bash
# Create release branch from stable tag
git checkout -b release/1.x v1.1.0
git push origin release/1.x

# Hotfix on release branch
git checkout release/1.x
git checkout -b hotfix/1.x/fix-critical-bug
# ... make fix ...
git commit -m "fix(auth): resolve session expiry race condition"
git push origin hotfix/1.x/fix-critical-bug

# PR into release/1.x, then cherry-pick to main
gh pr create --base release/1.x --title "fix: session expiry race condition"
# After merge:
git checkout main
git cherry-pick <commit-sha>
```

## GitHub Actions: Automated Release Pipeline

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  packages: write
  id-token: write

jobs:
  # 1. Validation gate
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - run: npm ci
      - run: npm test
      - run: npm run lint

  # 2. Build release artifact
  build:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/
          retention-days: 30

  # 3. Release (semantic-release handles versioning)
  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
        with:
          fetch-depth: 0        # Full history for semantic-release
          persist-credentials: false
      - uses: actions/download-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## GitHub Release Structure

```markdown
## What's Changed

### Breaking Changes
- `api/users` endpoint now requires `Authorization` header (#123)

### New Features
- Add OAuth2 authentication flow (#118)
- Add pagination to `/api/users` (#115)

### Bug Fixes
- Fix session expiry race condition (#122)
- Resolve memory leak in worker thread (#120)

### Dependencies
- Bump `express` from 4.18.0 to 4.18.2

## Upgrade Guide

For users upgrading from v1.x:
1. Update `Authorization: Bearer <token>` header on all API calls
2. Update pagination: `?page=1&limit=20` replaces `?offset=0`

## SHA256 Checksums
```
<hash> dist/app-linux-amd64
<hash> dist/app-darwin-arm64
```

**Full Changelog:** https://github.com/org/repo/compare/v1.1.0...v1.2.0
```

## Hotfix Workflow

```bash
# Scenario: Critical bug in v1.2.0 in production

# 1. Create hotfix branch from the problematic tag
git checkout -b hotfix/1.2.1 v1.2.0

# 2. Apply minimal fix
git commit -m "fix(payments): prevent duplicate charge on timeout retry

CRITICAL: Customers were charged twice when payment provider
timed out. Added idempotency key to prevent duplicate charges.

Fixes #456"

# 3. Test and tag
git tag v1.2.1
git push origin hotfix/1.2.1 --follow-tags

# 4. Create expedited release
gh release create v1.2.1 \
  --title "v1.2.1 — Critical: Fix duplicate charge on timeout" \
  --notes "CRITICAL hotfix: fixes duplicate charge issue (#456)" \
  --latest

# 5. Backport to main
git checkout main
git cherry-pick <hotfix-sha>
git push origin main

# 6. Delete hotfix branch
git push origin --delete hotfix/1.2.1
```

## Release Checklist

**Pre-release:**
- [ ] All tests pass on main/release branch
- [ ] `CHANGELOG.md` is accurate and complete
- [ ] Version bumped in all relevant files (`package.json`, `VERSION`, `pyproject.toml`)
- [ ] Migration guide written for breaking changes
- [ ] Staging deployment validated (smoke tests pass)
- [ ] Rollback procedure documented

**Release:**
- [ ] Git tag created (`git tag -s v1.2.0 -m "Release v1.2.0"`)
- [ ] GitHub Release published with release notes
- [ ] Artifact(s) attached and SHA256 checksums included
- [ ] Container image tagged and pushed (`:1.2.0`, `:1.2`, `:latest`)
- [ ] Production deployment triggered

**Post-release:**
- [ ] Monitor error rates and latency for 30 minutes
- [ ] Announce in relevant Slack channels / release notes
- [ ] Update internal documentation if behavior changed
- [ ] Close related issues with `Closed by v1.2.0`

## CHANGELOG Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-02-15

### Added
- OAuth2 authentication support (#118)
- Pagination for /api/users (#115)

### Fixed
- Session expiry race condition (#122)

### Changed
- API rate limit increased from 100 to 1000 req/min (#119)

### Breaking Changes
- `/api/users` now requires `Authorization` header (#123)
  - **Migration:** Add `Authorization: Bearer <token>` to all requests

## [1.1.0] - 2026-01-20
...

[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
```

## Common Mistakes / Anti-Patterns

- **Manual changelogs** — inconsistent and often missing entries; automate from commits
- **Bumping all semver components** — only bump what's needed (patch fix → patch only)
- **No release candidate** — major versions should go through RC in staging first
- **Tag on feature branch** — always tag on the stable branch (main or release/x.y)
- **Force-pushing tags** — breaking for anyone who already fetched; never force-push release tags
- **`latest` tag only** — always publish immutable version tags; `latest` alone prevents rollback

## Communication Style

When this skill is active:
- Specify which SemVer component to bump and why
- Generate complete CHANGELOG entries from commit messages
- Include full GitHub Actions YAML for release automation
- Flag breaking changes explicitly and provide migration guides
- Distinguish between `semantic-release` (fully automated) and manual tag/release flows

## Expected Output Quality

- Complete `.releaserc.json` or `release-please` config
- GitHub Actions workflow for automated release pipeline
- Changelog entry in conventional format with upgrade notes for breaking changes
- Git commands for manual hotfix workflow with cherry-pick to main

---
**Skill type:** Passive
**Applies with:** git, github-actions, ci-cd, workflows
**Pairs well with:** cicd-engineer (DevOps pack), architect (Dev pack)
