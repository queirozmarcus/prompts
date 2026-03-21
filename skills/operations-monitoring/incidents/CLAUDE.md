# Skill: Incidents

## Scope

Gestão de incidentes de produção: detecção, resposta, estabilização, comunicação e análise pós-incidente. Cobre estrutura de severidade, lifecycle de resposta com SLAs por severidade, gathering de sinais com comandos reais, técnicas de estabilização, comunicação estruturada e blameless post-mortems.

## Core Principles

- **Stabilize first, understand second** — restore service before root cause analysis
- **Communicate early and often** — silence during an incident erodes trust
- **One Incident Commander** — clear ownership prevents chaos; everyone else executes
- **Blameless culture** — systems fail, people respond; post-mortems find causes, not culprits
- **Time-boxed decisions** — if unsure after 10 minutes, escalate; don't stay stuck
- **Document as you go** — take notes in the war room channel in real time

## Severity Matrix

| SEV | Definition | Example | Response SLA | Update Cadence |
|-----|------------|---------|-------------|----------------|
| SEV1 | Complete outage or data loss; all users impacted | Payment service down, DB corruption | Page immediately; respond < 5 min | Every 15 min |
| SEV2 | Major degradation; significant % users impacted | API latency > 10s, 50% error rate | Page on-call; respond < 15 min | Every 30 min |
| SEV3 | Partial degradation; feature broken, workaround exists | Single endpoint 500ing, non-critical job failing | Notify on-call; respond < 1hr | Every 2 hrs |
| SEV4 | Minor issue; cosmetic or very low impact | Slow dashboard, stale cache | Create ticket; resolve < 1 week | Next business day |

**Escalation triggers:**
- No progress after 30 min on SEV1/2 -> escalate to senior engineer / manager
- Unknown blast radius -> treat as SEV1 until proven otherwise
- Data integrity concern -> auto-escalate to SEV1

## Incident Lifecycle

```
Alert fires / Report received
        |
   [0:00] Acknowledge & Assess severity
        |
   [0:05] Declare incident; assign IC (Incident Commander)
        |
   [0:05] Open war room (Slack #incident-YYYY-MM-DD-description)
        |
   [0:10] Initial stakeholder notification
        |
   [0:15] Signal gathering & hypothesis formation
        |
   [0:30] First stabilization attempt
        |
   Stabilized? --> Yes --> Monitor 15 min, then resolve
        |
        No  --> New hypothesis; escalate if > 30 min
        |
   [Resolved] Post-incident timeline captured
        |
   [24-48hr] Post-incident review scheduled
        |
   [1 week] Post-mortem published with action items
```

## Immediate Response (First 15 Minutes)

**Minute 0-5: Orient**
```bash
# What's the blast radius?
# Who is affected? (users, services, regions)
# Since when? (correlate with recent deployments)

# Check recent deployments
kubectl rollout history deployment -n production
git log --oneline -10  # recent commits

# Check cluster health
kubectl get nodes
kubectl get pods -n production | grep -v Running
```

**Minute 5-10: Communicate**
- Post in #incidents: "SEV[X] declared: [brief description]. IC: @name. War room: #incident-channel"
- Update status page (even "Investigating" is better than silence)
- Page additional responders if SEV1/2

**Minute 10-15: Gather signals**
- Check dashboards (Grafana: error rate, latency, throughput)
- Check recent alerts fired
- Check deployment history for correlation
- Identify the simplest rollback available

## Signal Gathering

**Kubernetes:**
```bash
# Pod status and recent restarts
kubectl get pods -n production -o wide
kubectl get pods -n production --sort-by='.status.containerStatuses[0].restartCount'

# Recent events (errors, scheduling failures)
kubectl get events -n production --sort-by='.lastTimestamp' | tail -30

# Pod logs (last 100 lines, with timestamps)
kubectl logs -n production deployment/api --tail=100 --timestamps

# Previous container logs (after crash)
kubectl logs -n production pod/api-xxx -c api --previous

# Resource pressure
kubectl top nodes
kubectl top pods -n production --sort-by=memory

# Describe unhealthy pod
kubectl describe pod -n production <pod-name>

# Check HPA status
kubectl get hpa -n production
```

**AWS:**
```bash
# EKS node issues
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=my-cluster" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]'

# ALB target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...

# RDS metrics (last 1 hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=my-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average

# Recent CloudTrail events (who changed what)
aws cloudtrail lookup-events \
  --start-time $(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
  --lookup-attributes AttributeKey=EventName,AttributeValue=UpdateService
```

**Application:**
```bash
# Check error patterns in logs (Loki via logcli)
logcli query '{app="api", namespace="production"} |= "error"' --limit=100 --since=1h

# CloudWatch Logs Insights
aws logs start-query \
  --log-group-name /aws/eks/production/api \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50'
```

## Stabilization Techniques

**Rollback (fastest path when deployment caused incident):**
```bash
# Kubernetes rollback
kubectl rollout undo deployment/api -n production
kubectl rollout status deployment/api -n production

# Check what you're rolling back to
kubectl rollout history deployment/api -n production
kubectl rollout undo deployment/api -n production --to-revision=3
```

**Traffic Shifting:**
```bash
# Reduce traffic to failing pods (patch replicas to 0 for specific deployment)
kubectl scale deployment/api-v2 -n production --replicas=0

# Weighted routing via Ingress annotation (nginx)
kubectl annotate ingress api -n production \
  nginx.ingress.kubernetes.io/canary-weight="0"
```

**Circuit Breaking:**
- Increase timeouts temporarily to shed load
- Enable maintenance mode / static response page
- Reduce rate limits to protect downstream dependencies
- Isolate the affected component (remove from load balancer)

**Database:**
```bash
# Kill long-running queries (PostgreSQL)
kubectl exec -n production deployment/postgres -- \
  psql -U admin -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE duration > interval '30 seconds';"

# Read replica failover (RDS)
aws rds failover-db-cluster --db-cluster-identifier my-cluster
```

## Communication Templates

**Initial Stakeholder Notification:**
```
[SEV2 INCIDENT] Payment API Degradation

Status: Investigating
Impact: ~30% of payment transactions failing with 500 errors
Start time: 2026-02-25 14:32 UTC
Affected: Payment service in us-east-1 production

Current actions: Team is investigating; rollback being evaluated
Next update: 15:00 UTC or sooner if resolved

IC: @engineer-name | War room: #incident-2026-02-25-payments
```

**Resolution Notification:**
```
[RESOLVED] Payment API Degradation

Resolved at: 2026-02-25 15:10 UTC
Duration: 38 minutes
Root cause (preliminary): Memory leak in v1.4.2 causing OOM restarts under load
Fix applied: Rolled back to v1.4.1; all instances healthy

Impact: ~1,200 failed transactions during window (retry logic recovered 900)
Post-mortem: Scheduled for 2026-02-27; action items to follow
```

## War Room Coordination

**Roles:**
- **Incident Commander (IC):** owns the incident; makes calls; delegates tasks
- **Tech Lead:** digs into root cause; proposes fixes
- **Comms Lead:** handles status page, stakeholder updates, Slack summaries
- **Scribe:** documents timeline, decisions, commands run in real time

**IC Checklist:**
- [ ] Severity declared and war room open
- [ ] Roles assigned
- [ ] Initial notification sent
- [ ] Runbook identified (if applicable)
- [ ] Rollback option evaluated
- [ ] Update cadence set (timer)
- [ ] Resolution communicated
- [ ] Post-mortem scheduled

## Root Cause Analysis

**5 Whys Example:**
```
Symptom: Payment API returning 500 errors
Why 1: Application pods crashing (OOMKilled)
Why 2: Memory usage growing unboundedly over time
Why 3: Connection pool not releasing DB connections on error
Why 4: Error handling path missing connection.release() call
Why 5: No integration test covering error path with DB connection

Root cause: Missing connection release in error handler
Contributing factor: No memory usage alert before reaching OOM
```

**Timeline Reconstruction:**
- Pull deployment history, config changes, and alert firing times
- Correlate with metrics (when did error rate start climbing?)
- Identify trigger event vs contributing conditions

## Post-Incident Review

**Blameless Post-Mortem Structure:**
```markdown
## Incident Summary
- Date, duration, severity, impact (users affected, transactions lost)

## Timeline
- [HH:MM] Event description (who observed what, what action was taken)

## Root Cause
- Direct cause
- Contributing factors (monitoring gaps, process gaps, system design)

## Impact
- Quantified user impact
- Business impact (if known)

## What Went Well
- Detection was fast (alert fired within 2 min)
- Rollback completed in < 5 min

## What Went Wrong / Could Be Improved
- No memory alert before OOM
- Took 20 min to identify rollback as option

## Action Items
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| Add memory usage alert at 85% | @sre | 2026-03-01 | High |
| Add integration test for DB error path | @backend | 2026-03-07 | High |
| Document rollback procedure in runbook | @sre | 2026-03-01 | Medium |
```

## Common Mistakes / Anti-Patterns

- Spending 30 minutes investigating instead of rolling back first
- Multiple people making changes simultaneously without coordination
- Not updating the status page ("investigating" is better than nothing)
- Fixing without documenting what was changed (leaves environment in unknown state)
- Post-mortem that identifies a person as the root cause (blame)
- Action items with no owner or deadline (they never get done)
- Declaring incident resolved before monitoring for 10+ minutes
- Not saving terminal output/commands run during incident (needed for post-mortem)

## Communication Style

When this skill is active:
- Prioritize stabilization commands before analysis
- Provide copy-paste ready kubectl/aws commands
- Suggest the simplest rollback first, then deeper investigation
- Keep communication templates concise and structured

## Expected Output Quality

- Specific commands for the suspected failure mode
- Ordered response steps (stabilize -> investigate -> communicate)
- Runbook skeleton or checklist for common failure modes
- Post-mortem template ready to fill in

---
**Skill type:** Passive
**Applies with:** observability, networking, aws, kubernetes
**Pairs well with:** sre-engineer (DevOps pack)
