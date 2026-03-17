# CLAUDE.md – Common Workflows

## Scope
This file defines reusable workflows for common development tasks.

---

## Workflow: Feature Development (Full Cycle)

### 1. Planning Phase
- Understand requirements
- If complex: EnterPlanMode
- Define acceptance criteria

### 2. Branch Creation
```bash
git checkout -b feat/feature-name
```

### 3. TDD Development
- Write failing test
- Implement minimum code to pass
- Refactor
- Repeat

### 4. Code Quality Checks
```bash
npm run lint
npm test
npm run test:coverage  # Verify > 80%
```

### 5. Commit
```bash
git add <files>
git commit -m "feat: description

Details...

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 6. Pull Request
- Push branch
- Create PR with template
- Link related issues
- Request reviewers

### 7. Post-Merge Cleanup
```bash
git checkout main
git pull origin main
git branch -d feat/feature-name
```

---

## Workflow: Bug Fix (Production)

### 1. Reproduce Locally
- [AGENT: Bash] Get error logs
- Create failing test case

### 2. Investigation
- [AGENT: Explore] Find related code
- [AGENT: Grep] Search for similar issues

### 3. Fix
- Implement fix
- Verify test now passes
- Check for regression

### 4. Fast-Track Deploy
```bash
git checkout -b fix/critical-bug
# ... fix code ...
git commit -m "fix: critical bug description"
git push origin fix/critical-bug
# Create PR with "URGENT" label
```

### 5. Monitoring
- Deploy to prod
- Monitor error rates
- Check user impact

---

## Workflow: Code Review

### As Reviewer
1. Checkout PR branch locally
2. Run tests: `npm test`
3. Check coverage delta
4. Review code quality:
   - Security issues?
   - Performance concerns?
   - Follows project conventions?
5. Run app locally if UI changes
6. Leave constructive feedback
7. Approve or request changes

### As Author (Addressing Feedback)
1. Read all comments
2. Ask clarifying questions if needed
3. Make requested changes
4. Reply to each comment
5. Re-request review

---

## Workflow: Dependency Update

### 1. Check for Updates
```bash
npm outdated
```

### 2. Security Audit
```bash
npm audit
npm audit fix  # Safe fixes only
```

### 3. Update Strategy
- **Patch versions:** Update immediately
- **Minor versions:** Update weekly
- **Major versions:** Plan and test thoroughly

### 4. Update Process
```bash
git checkout -b chore/update-dependencies
npm update  # Minor/patch only
# Or for major:
npm install package@latest
```

### 5. Validation
- Run full test suite
- [AGENT: Bash] Test in Docker container
- Check for deprecation warnings
- Verify no breaking changes

### 6. Document Changes
```bash
git commit -m "chore: update dependencies

Updated packages:
- express: 4.17.1 -> 4.18.0
- jest: 28.0.0 -> 29.0.0

Breaking changes: None
"
```

---

## Workflow: Database Migration

### 1. Planning
- EnterPlanMode if major schema change
- Design migration (up + down)
- Identify affected queries

### 2. Create Migration
```bash
npm run migration:create -- add-user-roles
```

### 3. Write Migration Code
- UP: Add new schema
- DOWN: Rollback schema
- Include data migration if needed

### 4. Test Locally
```bash
npm run migrate:up
npm run migrate:down
npm run migrate:up  # Verify idempotency
```

### 5. Test with Real Data
- [AGENT: Bash] Backup production DB
- Restore backup to staging
- Run migration on staging
- Verify data integrity

### 6. Deploy Migration
- Deploy code + migration together
- Monitor for errors
- Have rollback plan ready

---

## Workflow: Performance Investigation

### 1. Collect Metrics
- [AGENT: Bash] Get APM data
- Identify slow endpoints
- Check error rates

### 2. Profile Application
```bash
node --inspect server.js
# Use Chrome DevTools
```

### 3. Analysis
- [AGENT: Explore] Find bottleneck code
- Database N+1 queries?
- Memory leaks?
- CPU-intensive operations?

### 4. Optimization
- Add caching where appropriate
- Optimize database queries
- Use async where possible
- Add pagination

### 5. Benchmark
```bash
# Before
npm run benchmark

# After changes
npm run benchmark

# Compare results
```

### 6. Monitor Post-Deploy
- Track response times
- Monitor resource usage
- Verify improvement

---

## Workflow: Security Incident Response

### 1. Immediate Action
- Identify scope of breach
- Contain: disable affected endpoints if needed
- Preserve logs for investigation

### 2. Investigation
- [AGENT: Grep] Search for attack patterns in logs
- [AGENT: Explore] Find vulnerable code
- Determine root cause

### 3. Remediation
- Patch vulnerability
- Rotate compromised secrets
- Force password resets if needed

### 4. Fast-Track Deploy
```bash
git checkout -b fix/security-patch
# ... fix code ...
git commit -m "fix(security): patch vulnerability CVE-XXXX"
# Deploy immediately
```

### 5. Post-Incident
- Write incident report
- Update security practices
- Add automated checks to prevent recurrence

---

---

## Workflow: Feature Flag Deployment

### 1. Define Flag
- Choose flag system (LaunchDarkly, AWS AppConfig, SSM Parameter Store, Unleash)
- Define flag name, type (boolean/percentage/user segment), default value
- Document: what the flag controls, rollout plan, cleanup date

### 2. Implement Behind Flag
```javascript
// Check flag before executing new behavior
if (await flagService.isEnabled('new-checkout-flow', userId)) {
  return newCheckoutFlow(cart);
}
return legacyCheckoutFlow(cart);
```

### 3. Deploy with Flag OFF
```bash
# Deploy code with flag disabled globally
# New code ships to production but doesn't execute
aws ssm put-parameter \
  --name "/production/features/new-checkout-flow" \
  --value "false" --overwrite
```

### 4. Verify Deployment (flag still OFF)
- Run smoke tests confirming existing behavior unchanged
- Check error rate and latency metrics baseline

### 5. Gradual Rollout
```bash
# Enable for internal users first (0% → 5% → 25% → 50% → 100%)
# Update flag to target specific users or percentage
aws ssm put-parameter \
  --name "/production/features/new-checkout-flow" \
  --value "true" --overwrite  # After validating at each stage
```

### 6. Monitor at Each Stage
- Track error rate for new vs old path
- Compare conversion metrics if A/B testing
- Watch latency percentiles
- Hold at each stage for minimum 30 minutes

### 7. Full Rollout or Rollback
- **Promote:** Enable for 100%, schedule code cleanup (remove flag in next sprint)
- **Rollback:** Disable flag immediately (no deploy needed — fastest rollback possible)

### 8. Flag Cleanup (Critical)
- Remove flag check from code after full rollout (avoid flag debt)
- Archive flag in flag system
- PR: remove dead code branch

---

## Workflow: Canary Deployment

### 1. Define Success Criteria
Before starting, define:
- Error rate threshold (e.g., < 0.1% = healthy)
- P99 latency threshold (e.g., < 500ms = healthy)
- Minimum observation window (e.g., 15 minutes at each stage)
- Automatic rollback trigger

### 2. Deploy Canary Version
```bash
# Kubernetes: deploy with separate label
kubectl set image deployment/myapp-canary app=myapp:v2.0.0 -n production
kubectl scale deployment/myapp-canary --replicas=1 -n production  # ~5% if main has 20 replicas
```

### 3. Configure Traffic Split
```yaml
# Istio VirtualService: 5% to canary
http:
  - route:
      - destination:
          host: myapp
          subset: stable
        weight: 95
      - destination:
          host: myapp
          subset: canary
        weight: 5
```

### 4. Monitor Canary Metrics
```promql
# Compare error rate: canary vs stable
rate(http_requests_total{status=~"5..",version="canary"}[5m])
  / rate(http_requests_total{version="canary"}[5m])
vs
rate(http_requests_total{status=~"5..",version="stable"}[5m])
  / rate(http_requests_total{version="stable"}[5m])

# Compare P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{version="canary"}[5m]))
```

### 5. Progressive Promotion or Rollback
```bash
# If healthy after 15+ minutes at 5%:
# Increase to 25% → wait → 50% → wait → 100%

# If metrics exceed threshold at any stage:
# Immediate rollback to 0% canary traffic
kubectl patch vs myapp -n production --type='json' \
  -p='[{"op":"replace","path":"/spec/http/0/route/0/weight","value":100},
       {"op":"replace","path":"/spec/http/0/route/1/weight","value":0}]'
```

### 6. Full Promotion
```bash
# After stable at 100% for 30+ minutes:
# Update stable deployment with new image, scale down canary
kubectl set image deployment/myapp-stable app=myapp:v2.0.0 -n production
kubectl scale deployment/myapp-canary --replicas=0 -n production
```

---

## Core Principles

- **Workflows are reusable procedures** — follow them consistently to reduce mistakes
- **Each workflow has a clear start and end** — no ambiguous "done when it feels done"
- **Test before merge, always** — no workflow skips quality gates
- **Automate what repeats** — if a workflow runs >3 times, it should be a slash command or playbook

## Communication Style

- Present workflows as numbered steps with clear commands
- Show exact bash/CLI commands, not descriptions
- Flag manual vs automated steps explicitly

## Expected Output Quality

Responses should:
- Follow the workflow step by step, in order
- Provide exact commands ready to copy-paste
- Flag risks at each step (data loss, downtime, breaking changes)
- Reference relevant slash commands when available (e.g., `/dev-feature`, `/qa-generate`)

---

**Skill type:** Passive (Workflow Library)
**Related agents:** `architect` (Dev pack), `cicd-engineer` (DevOps pack), `gitops-engineer` (DevOps pack)
**Applies with:** git, github-actions, ci-cd, kubernetes, argocd, istio
**Usage:** Reference specific workflow when starting a task
