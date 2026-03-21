# Playbook: Incident Response

## Severity Matrix

| Severity | Definition | Example | Response SLA | Update Cadence |
|----------|-----------|---------|-------------|----------------|
| **SEV1** | Complete outage / data loss / security breach | All API requests failing, DB down, credentials exposed | IC assigned < 5 min | Every 15 min |
| **SEV2** | Partial outage / major feature broken / >10% error rate | Checkout broken, 20% 5xx errors, half users affected | Response < 15 min | Every 30 min |
| **SEV3** | Degraded performance / minor feature broken | P99 latency 3x normal, non-critical feature down | Response < 1 hour | Every 2 hours |
| **SEV4** | Minor / cosmetic / single user | Single user can't login, UI glitch, minor data inconsistency | Next business day | Daily |

## Incident Roles

- **Incident Commander (IC):** Owns the incident end-to-end; coordinates roles; final decision authority
- **Tech Lead:** Drives technical investigation and mitigation; executes changes
- **Comms Lead:** Drafts status updates; interfaces with stakeholders; updates status page
- **Scribe:** Documents timeline in real-time; captures all actions, hypotheses, and outcomes

## War Room Setup

**Open a War Room immediately for SEV1/SEV2:**

```
1. Create incident channel:
   Slack: /incident create SEV1 "API completely down"
   → Creates: #incident-YYYYMMDD-sev1-api-down

2. Assign roles (first 5 minutes):
   IC: <name> — announces in channel
   Tech Lead: <name>
   Comms Lead: <name>
   Scribe: <name> (or use a bot)

3. Open video call (for SEV1 — voice coordination is faster):
   Zoom: https://zoom.us/j/incident-room  (dedicated always-on room)
   OR: /zoom in the Slack channel

4. Open live timeline document:
   Confluence: [Incident] YYYYMMDD SEV1 — brief description
   Share link in incident channel immediately

5. Pin to channel:
   - Timeline document link
   - Dashboard link (Grafana / CloudWatch)
   - Runbook link
   - Status page link

6. Status page update (within 15 min of SEV1 declaration):
   https://status.example.com → Create incident → "Investigating"
```

**War Room etiquette:**
- IC controls the floor; others wait to speak or use Slack thread
- All decisions and findings posted to Slack (not just spoken on call)
- Scribe captures everything in the timeline document in real-time
- Observers mute themselves and listen; do not interrupt unless critical

## First 15 Minutes (The Golden Window)

```bash
# 1. Confirm the incident (is this real?)
# Check the alert source: Is it a false positive? Isolated or widespread?

# 2. Correlate with recent deploys
git log --oneline -10 origin/main                    # What deployed recently?
kubectl rollout history deployment/ -n production     # K8s deploy history

# 3. Quick health check
kubectl get pods -n production | grep -v Running | grep -v Completed
kubectl get events -n production --sort-by='.lastTimestamp' | tail -20
kubectl top pods -n production --sort-by=memory | head -15

# 4. Check AWS service health (rule out AWS incident)
# https://health.aws.amazon.com/health/status
aws health describe-events --filter eventStatusCodes=open

# 5. Declare severity and open incident channel
# Slack: /incident SEV2 "API error rate 25%"
# → Creates #incident-20260225-sev2-api-errors channel
```

## Signal Gathering Commands

**Kubernetes signals:**
```bash
# Error rate and pod health
kubectl get pods -n production -o wide | grep -E "(CrashLoopBackOff|OOMKilled|Error|Pending)"
kubectl describe pod <failing-pod> -n production | tail -30
kubectl logs <failing-pod> -n production --tail=100 --previous

# Recent events (warnings and errors)
kubectl get events -n production --field-selector type=Warning --sort-by='.lastTimestamp' | tail -30

# Resource pressure
kubectl top nodes
kubectl top pods -n production --sort-by=cpu | head -10
```

**AWS signals:**
```bash
# ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --query 'TargetGroups[?TargetGroupName==`production-api`].TargetGroupArn' \
    --output text)

# ECS service status
aws ecs describe-services \
  --cluster production \
  --services api-service \
  --query 'services[0].{Status:status,Running:runningCount,Pending:pendingCount,Desired:desiredCount}'

# RDS status
aws rds describe-db-instances \
  --db-instance-identifier prod-db \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Connections:Endpoint}'

# CloudWatch Logs Insights — errors last 30 min
aws logs start-query \
  --log-group-name /aws/ecs/api-service \
  --start-time $(date -d '30 minutes ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50'
```

**Prometheus queries for signals:**
```promql
# Current error rate
sum(rate(http_requests_total{status=~"5..",namespace="production"}[5m])) / sum(rate(http_requests_total{namespace="production"}[5m]))

# P99 latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace="production"}[5m])) by (le, service))

# Pod restart rate
increase(kube_pod_container_status_restarts_total{namespace="production"}[15m])
```

## Decision Tree: Common Scenarios

**Scenario A: Service completely down (0% success rate)**
```
→ Check ALB target health — are targets healthy?
  → No: Check pod readiness probes
    → Pods not ready: Check logs for startup errors → rollback if deploy-related
    → Pods ready but failing health check: Check app /health endpoint manually
  → Yes: Check ALB access logs for error type
    → 504 Gateway Timeout: pods are timing out → check DB connections, downstream services
    → 502 Bad Gateway: pods are refusing connections → check port config, app startup
```

**Scenario B: High error rate (10-50%)**
```
→ Correlate with recent deploy?
  → Yes: Rollback immediately (stabilize, understand later)
  → No: Check DB connection pool exhaustion
    → Yes: Scale down traffic, increase pool size, kill idle connections
    → No: Check external dependency (third-party API, S3, etc.)
      → External: Circuit break the dependency, return degraded response
      → Internal: Check resource exhaustion (CPU, memory, disk)
```

**Scenario C: High latency (requests slow, not failing)**
```
→ Check DB query performance (slow queries, connection pool saturation)
→ Check downstream service latency (Istio metrics or X-Ray traces)
→ Check CPU throttling (container_cpu_cfs_throttled_ratio)
→ Check network: DNS resolution time, external API latency
→ Scale up replicas if resource-bound
```

**Scenario D: Cost spike alert**
```
→ Check Cost Explorer for spike source (which service)
→ Check CloudWatch for runaway Lambda invocations or unusual EC2 activity
→ Check for data transfer anomalies (large S3 downloads, cross-region traffic)
→ Consider: Is this a DDoS or scraper generating legitimate costs?
```

## Stabilization Techniques

**Fastest: Roll back recent deploy**
```bash
# Kubernetes
kubectl rollout undo deployment/myapp -n production
kubectl rollout status deployment/myapp -n production --timeout=5m

# ArgoCD
argocd app rollback myapp-production <HISTORY_ID>
```

**Scale out (resource exhaustion)**
```bash
kubectl scale deployment/myapp --replicas=6 -n production
# Or update HPA minimum:
kubectl patch hpa myapp -n production -p '{"spec":{"minReplicas":6}}'
```

**Kill switch (feature flag)**
```bash
# Disable feature via AWS AppConfig, env var, or config change
# Triggers redeployment with feature disabled
```

**DB: Kill runaway queries**
```sql
-- PostgreSQL: find and kill long-running queries
SELECT pid, duration, query FROM pg_stat_activity
WHERE state = 'active' AND duration > interval '60 seconds'
ORDER BY duration DESC;

SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE state = 'active' AND duration > interval '5 minutes';
```

**Circuit breaker: Rate limit**
```bash
# Apply rate limiting annotation to ALB or NGINX ingress
# AWS WAF: Apply rate rule to ALB
aws wafv2 create-rule-group ...  # Add rate limit rule
```

## Communication Templates

**Initial notification (< 5 min after declaring SEV):**
```
🚨 [SEV{N}] {Service} is experiencing {symptom}
⏰ Started: {HH:MM} UTC
📊 Impact: {X% of users / Y requests/sec affected}
🔍 Status: Investigating
👤 IC: {name}
🔄 Next update: {HH:MM} UTC ({N} minutes)
```

**Progress update (every 15-30 min):**
```
📊 Incident Update [{HH:MM} UTC]
Status: {Investigating / Stabilizing / Monitoring}
Current metrics: Error rate {X}%, P99 {Y}ms
Actions taken: {list of actions}
Current hypothesis: {what we think is causing this}
Next steps: {specific next action}
Next update: {HH:MM} UTC
```

**Resolution:**
```
✅ RESOLVED [{HH:MM} UTC]
Service: {service name}
Duration: {X hours Y minutes}
Root cause: {brief summary}
Fix applied: {what resolved it}
Monitoring: Normal for {X} minutes
Post-mortem: Scheduled for {date} | Owner: {name}
```

## Post-Incident Review

**Timeline template:**
```markdown
# Post-Incident Review: [Service] [Date]

## Summary
- **Severity:** SEV{N}
- **Duration:** {start} to {end} ({total minutes})
- **Impact:** {quantified: # users, # requests, revenue estimate}
- **Root cause:** {one-sentence summary}

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | Alert fired: {alert name} |
| HH:MM | IC {name} joined |
| HH:MM | Rollback initiated |
| HH:MM | Service restored |

## Contributing Factors
1. {What made this incident possible}
2. {What made it worse}
3. {What slowed detection/resolution}

## What Went Well
- {Things that worked during the response}

## Action Items
| Action | Owner | Due Date | Priority |
|--------|-------|----------|---------|
| Add readiness probe timeout | @eng | +7 days | P1 |
| Add alert for connection pool saturation | @sre | +14 days | P1 |
```

## Blameless RCA: 5 Whys

```
Problem: Service returned 503 errors for 45 minutes

Why 1: ALB targets were failing health checks
Why 2: The application wasn't responding on /health endpoint
Why 3: The database connection pool was exhausted (max 100 connections used)
Why 4: A new query introduced in v2.3.1 didn't close connections properly
Why 5: There was no connection leak detection in code review or staging tests

Root cause: Connection leak in new query + insufficient connection pool monitoring
```

## Blameless Postmortem Template

```markdown
# Postmortem: [Service] [Brief Description]
**Date:** YYYY-MM-DD
**Severity:** SEV{N}
**Duration:** {X} hours {Y} minutes
**IC:** {name}
**Postmortem Owner:** {name}
**Review Meeting:** {date and link}

---

## Impact
- **Users affected:** {number or %}
- **Requests failed:** {count or %}
- **Revenue impact:** ${estimate} (if applicable)
- **Data loss:** Yes / No (if Yes, describe)

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | Alert fired: {alert name} |
| HH:MM | IC {name} joined; SEV declared |
| HH:MM | {action taken} |
| HH:MM | {hypothesis formed} |
| HH:MM | Mitigation applied: {what} |
| HH:MM | Service restored to normal |
| HH:MM | Incident resolved; monitoring continues |

## Root Cause
{One clear paragraph explaining the technical root cause.
Not a list of contributing factors — the single root cause.}

## Contributing Factors
1. {Factor 1: e.g., No alerting on connection pool saturation}
2. {Factor 2: e.g., No connection leak test in staging}
3. {Factor 3: e.g., Health check did not test database connectivity}

## What Went Well
- {e.g., Rollback completed in under 5 minutes}
- {e.g., On-call responded within 3 minutes of alert}
- {e.g., Clear incident channel communication}

## What Could Have Gone Better
- {e.g., Took 20 minutes to identify the correct service was down}
- {e.g., Status page was updated 30 minutes after incident declared}

## Action Items
| # | Action | Owner | Priority | Due Date |
|---|--------|-------|---------|----------|
| 1 | Add alert for pg_stat_activity connection count > 80% | {name} | P1 | +7 days |
| 2 | Add connection pool metrics to service dashboard | {name} | P1 | +7 days |
| 3 | Add DB connectivity check to readiness probe | {name} | P1 | +14 days |
| 4 | Review connection pool settings for all services | {name} | P2 | +30 days |

## Detection Gap
{Was there an alert for this? If not, what alert would have caught it earlier?
What is the earliest point this could have been detected?}

## Prevention
{What single change would most prevent this class of incident from recurring?}
```

---
**Used by:** sre-engineer (DevOps pack)
**Related playbooks:** rollback-strategy.md, network-troubleshooting.md, k8s-deploy-safe.md
