# Playbook: DR Drill

## Purpose

Periodic validation that disaster recovery procedures actually work — before a real disaster. Drills verify that RTO/RPO targets are achievable, procedures are documented correctly, and the team has practiced execution. An untested DR plan is not a DR plan.

## Inputs

- [ ] `TIER` — 1 (critical) | 2 (important) | 3 (standard)
- [ ] `DRILL_TYPE` — tabletop | partial-restore | full-failover
- [ ] `SCOPE` — which services/components are included in this drill
- [ ] `DR_LEAD` — engineer leading the drill
- [ ] `OBSERVERS` — additional participants

## Cadence

| Tier | Description | Cadence | Drill Type |
|------|-------------|---------|-----------|
| **Tier 1** | Revenue-critical, SLA-bound (payments, auth, core API) | Quarterly | Partial-restore or full-failover |
| **Tier 2** | Important but tolerable downtime 1-4h (reporting, search) | Semi-annual | Partial-restore or tabletop |
| **Tier 3** | Internal tools, non-user-facing services | Annual | Tabletop |

---

## Pre-Drill Checklist

```bash
# 1. Verify current DR documentation is up to date
# Review dr-restore.md — was it updated after the last infrastructure change?

# 2. Confirm backup availability for targeted services
# RDS/Aurora: verify automated backups and PITR window
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,PITR:LatestRestorableTime,Retention:BackupRetentionPeriod}' \
  --output table

# 3. Confirm cross-region replication is in sync (if applicable)
aws rds describe-db-instances \
  --db-instance-identifier prod-db \
  --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'

# 4. Notify stakeholders of drill window
# Subject: [DR DRILL] Planned test on {date} {time} UTC — no user impact expected
# Include: scope, duration estimate, escalation contact if issues arise

# 5. Review RTO/RPO targets for services in scope
echo "Service: payments-api"
echo "RTO Target: 1 hour (time to restore service)"
echo "RPO Target: 15 minutes (max acceptable data loss)"
echo ""
echo "Service: user-api"
echo "RTO Target: 4 hours"
echo "RPO Target: 1 hour"

# 6. Confirm rollback path (drills should be reversible)
```

---

## Drill Types

### Tabletop Drill (Low-Risk, Any Environment)

Walk through the DR scenario without executing changes. Identify gaps in documentation and team knowledge.

**Facilitator script:**
```
Scenario: "It's 3 AM. An AWS region (us-east-1) has gone offline.
Your monitoring shows all ECS services are unreachable.
The last successful backup was 45 minutes ago."

Walk through:
1. Who gets the alert? What does the alert say?
2. Who is the Incident Commander? Where is the runbook?
3. What is step 1? (Don't say "read the runbook" — DO IT NOW in this drill)
4. Where are the backups? How do you access the restore procedure?
5. What is the target recovery region? Is it configured?
6. At what point do you declare success? How do you validate?
7. How do you communicate with users during the outage?
8. What would have made this easier?
```

**Document all gaps found during tabletop.**

---

### Partial Restore Drill (Medium Risk, Staging/Isolated)

Restore a specific component to verify the restore procedure works. Does NOT affect production traffic.

```bash
# Scenario: Restore RDS database from snapshot to a new instance (staging environment)
DRILL_DATE=$(date +%Y%m%d)
RESTORED_INSTANCE="drill-${DRILL_DATE}-restored"

# 1. Record start time (measuring actual RTO)
DRILL_START=$(date +%s)
echo "Drill started: $(date -u)"

# 2. Identify latest restorable snapshot
aws rds describe-db-snapshots \
  --db-instance-identifier prod-db \
  --query 'DBSnapshots[?Status==`available`] | sort_by(@, &SnapshotCreateTime) | [-1].{ID:DBSnapshotIdentifier,Time:SnapshotCreateTime}' \
  --output table

# 3. Restore to isolated instance (not production)
SNAPSHOT_ID="<latest-snapshot-id>"
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ${RESTORED_INSTANCE} \
  --db-snapshot-identifier ${SNAPSHOT_ID} \
  --db-instance-class db.t3.medium \
  --no-publicly-accessible \
  --vpc-security-group-ids ${SECURITY_GROUP_ID}

echo "Restore initiated. Waiting..."
aws rds wait db-instance-available \
  --db-instance-identifier ${RESTORED_INSTANCE}

# 4. Record restore completion time
RESTORE_COMPLETE=$(date +%s)
RESTORE_DURATION=$((RESTORE_COMPLETE - DRILL_START))
echo "Database restore completed in ${RESTORE_DURATION} seconds"

# 5. Validate restored data
RESTORED_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ${RESTORED_INSTANCE} \
  --query 'DBInstances[0].Endpoint.Address' --output text)

psql "postgresql://admin:${DB_PASSWORD}@${RESTORED_ENDPOINT}/production" \
  -c "SELECT count(*) FROM users; SELECT max(created_at) FROM orders;" \
  && echo "✅ Data validation PASSED" \
  || echo "❌ Data validation FAILED"

# 6. Measure data freshness (RPO validation)
psql "postgresql://admin:${DB_PASSWORD}@${RESTORED_ENDPOINT}/production" \
  -c "SELECT now() - max(created_at) AS data_age FROM orders;"

# 7. Clean up drill instance
echo "Cleaning up drill instance..."
aws rds delete-db-instance \
  --db-instance-identifier ${RESTORED_INSTANCE} \
  --skip-final-snapshot

# 8. Calculate and record metrics
DRILL_END=$(date +%s)
TOTAL_DURATION=$((DRILL_END - DRILL_START))
echo "Total drill duration: ${TOTAL_DURATION} seconds (${TOTAL_DURATION}/60 minutes)"
```

---

### Full Failover Drill (High Risk, Requires Maintenance Window)

**Only for Tier 1 services, with explicit stakeholder approval, during a maintenance window.**

```bash
# Scenario: Simulate primary region failure; fail over to secondary region

# --- PRE-FAILOVER ---
echo "=== FAILOVER DRILL START ==="
DRILL_START=$(date +%s)

# 1. Record current state
aws rds describe-db-instances \
  --db-instance-identifier prod-db \
  --query 'DBInstances[0].{Status:DBInstanceStatus,MultiAZ:MultiAZ,Endpoint:Endpoint.Address}'

# 2. Announce maintenance window (done before drill)
# Users should be informed: "Scheduled maintenance: {window}"

# --- FAILOVER EXECUTION ---
# RDS Multi-AZ failover (promotes standby)
aws rds reboot-db-instance \
  --db-instance-identifier prod-db \
  --force-failover

# Monitor failover
aws rds wait db-instance-available \
  --db-instance-identifier prod-db

FAILOVER_TIME=$(($(date +%s) - DRILL_START))
echo "RDS failover completed in ${FAILOVER_TIME} seconds"

# Aurora Global Database failover (cross-region)
# aws rds failover-global-cluster \
#   --global-cluster-identifier prod-global \
#   --target-db-cluster-identifier prod-db-secondary

# --- VALIDATE AFTER FAILOVER ---
# Verify endpoint still resolves (DNS updated)
dig +short prod-db.cluster-xxx.us-east-1.rds.amazonaws.com

# Verify application can connect
curl -sf https://api.example.com/health

# Verify write operations work
psql ${DB_CONNECTION} -c "INSERT INTO health_checks (ts) VALUES (now()) RETURNING id;"

# --- RECORD RTO ---
SERVICE_UP=$(($(date +%s) - DRILL_START))
echo "Service restored in: ${SERVICE_UP} seconds"
echo "RTO Target: 3600 seconds (1 hour)"
echo "RTO Actual: ${SERVICE_UP} seconds"
[ ${SERVICE_UP} -le 3600 ] && echo "✅ RTO TARGET MET" || echo "❌ RTO TARGET MISSED"
```

---

## Post-Drill Validation

```bash
# Validate RTO: Did we restore within the target?
echo "Target RTO: ${TARGET_RTO_SECONDS} seconds"
echo "Actual RTO: ${ACTUAL_RTO_SECONDS} seconds"

# Validate RPO: How much data was lost?
echo "Target RPO: ${TARGET_RPO_MINUTES} minutes"
echo "Actual data age at restore: ${ACTUAL_DATA_AGE_MINUTES} minutes"

# Validate procedure: Did the runbook match reality?
echo "Steps that worked as documented: <list>"
echo "Steps that failed or were outdated: <list>"
echo "Steps that were missing from documentation: <list>"
```

---

## Post-Drill Report

```markdown
# DR Drill Report — {Service} — {Date}

## Summary
- **Drill Type:** Partial Restore / Full Failover / Tabletop
- **Tier:** 1 / 2 / 3
- **Date:** {date}
- **DR Lead:** {name}
- **Duration:** {total minutes}

## RTO/RPO Results
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| RTO (restore time) | {X} min | {Y} min | ✅ MET / ❌ MISSED |
| RPO (data age) | {X} min | {Y} min | ✅ MET / ❌ MISSED |

## What Worked
- {List things that worked as expected}

## Issues Found
| Issue | Severity | Owner | Due Date |
|-------|---------|-------|----------|
| {description} | HIGH/MEDIUM/LOW | {name} | {date} |

## Action Items
- [ ] Update dr-restore.md step 4 — endpoint changed
- [ ] Add monitoring alert for replication lag > 5 min
- [ ] Document secondary region account ID in runbook

## Procedure Updates Required
- [ ] {List specific runbook updates needed}

## Next Drill
- **Date:** {next drill date}
- **Scope:** {what to test next time}
```

---

## Scheduling

```bash
# Add to team calendar / JIRA / Confluence
echo "DR Drill Schedule:"
echo ""
echo "Tier 1 (Quarterly):"
echo "  Q1: {month} — payments-api + auth-service"
echo "  Q2: {month} — core-api + database"
echo "  Q3: {month} — payments-api + auth-service"
echo "  Q4: {month} — full regional failover simulation"
echo ""
echo "Tier 2 (Semi-annual):"
echo "  H1: {month} — reporting-service"
echo "  H2: {month} — search-service"
echo ""
echo "Tier 3 (Annual):"
echo "  {month} — internal tools (tabletop)"
```

---
**Used by:** sre-engineer (DevOps pack), architect (Dev pack)
**Related playbooks:** dr-restore.md, incident-response.md, rollback-strategy.md
