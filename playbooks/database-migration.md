# Playbook: Database Migration

## Purpose

Safe execution of database schema migrations in production. Prevents data loss, minimizes downtime, and ensures every migration has a tested rollback path. Applicable to PostgreSQL on RDS/Aurora, DynamoDB structural changes, and any schema evolution in production systems.

## Inputs

- [ ] `MIGRATION_FILE` — migration script(s) to execute
- [ ] `DB_IDENTIFIER` — RDS instance or Aurora cluster identifier
- [ ] `DB_NAME` — target database name
- [ ] `MIGRATION_TOOL` — Flyway / Liquibase / Alembic / custom SQL
- [ ] `ENVIRONMENT` — staging | production

---

## Phase 0: Pre-Migration Assessment

**Classify the migration — determines the strategy:**

| Type | Examples | Risk | Strategy |
|------|---------|------|---------|
| **Additive** | ADD COLUMN (nullable), CREATE TABLE, CREATE INDEX CONCURRENTLY | Low | Direct migration |
| **Destructive** | DROP COLUMN, DROP TABLE, TRUNCATE | High | Expand/contract; verify code no longer references column |
| **Blocking** | ALTER TYPE, ADD NOT NULL without default, CREATE INDEX (non-concurrent) | Medium-High | Off-peak window or online schema change |
| **Data transformation** | UPDATE all rows, backfill new column | Medium | Batched update + dual-write pattern |

```bash
# 1. Confirm PITR is enabled and get restore window
aws rds describe-db-instances \
  --db-instance-identifier ${DB_IDENTIFIER} \
  --query 'DBInstances[0].{
    PITR: BackupRetentionPeriod,
    EarliestRestore: EarliestRestorableTime,
    LatestRestore: LatestRestorableTime,
    Status: DBInstanceStatus,
    MultiAZ: MultiAZ
  }'

# 2. Check current connection count (low = safer time to migrate)
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=${DB_IDENTIFIER} \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Average --output table

# 3. Estimate lock duration (run in staging first)
# For ALTER TABLE: check table row count and estimate duration
psql ${DB_NAME} -c "SELECT relname, n_live_tup FROM pg_stat_user_tables WHERE relname = 'target_table';"
```

---

## Phase 1: Pre-Migration Snapshot

```bash
# Create pre-migration snapshot (mandatory before any production migration)
SNAPSHOT_ID="pre-migration-$(date +%Y%m%d-%H%M%S)"

aws rds create-db-snapshot \
  --db-instance-identifier ${DB_IDENTIFIER} \
  --db-snapshot-identifier ${SNAPSHOT_ID}

# Wait for snapshot to complete
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier ${SNAPSHOT_ID}

echo "Snapshot created: ${SNAPSHOT_ID}"
echo "Restore command if needed:"
echo "  aws rds restore-db-instance-from-db-snapshot --db-instance-identifier ${DB_IDENTIFIER}-restored --db-snapshot-identifier ${SNAPSHOT_ID}"
```

---

## Phase 2: Staging Validation (MANDATORY)

```bash
# Run migration in staging first — with production-scale data if possible
STAGING_DB_IDENTIFIER="${DB_IDENTIFIER}-staging"

# Time the migration in staging
START_TIME=$(date +%s%3N)
# Run migration tool:
# Flyway:    flyway -url=jdbc:postgresql://${STAGING_HOST}/${DB_NAME} -locations=filesystem:./migrations migrate
# Alembic:   alembic upgrade head
# Liquibase: liquibase update

END_TIME=$(date +%s%3N)
echo "Migration took $((END_TIME - START_TIME))ms in staging"

# Validate: row counts, key records, application smoke tests
psql ${DB_NAME} -c "
SELECT
  (SELECT count(*) FROM users) AS users_count,
  (SELECT count(*) FROM orders) AS orders_count;
"
```

**If staging migration takes > 30 seconds on a large table:**
- Use `CREATE INDEX CONCURRENTLY` instead of `CREATE INDEX`
- Use gh-ost or pt-online-schema-change for `ALTER TABLE`
- Use expand/contract pattern for column renames

---

## Phase 3: Zero-Downtime Strategies

### Additive Migration (new nullable column or table)

```sql
-- Safe: no lock contention
ALTER TABLE orders ADD COLUMN discount_amount numeric(10,2);

-- Create index WITHOUT locking the table
CREATE INDEX CONCURRENTLY idx_orders_discount ON orders(discount_amount)
  WHERE discount_amount IS NOT NULL;
```

### Expand/Contract (column rename or type change)

```sql
-- Step 1: ADD new column (deploy with code that writes to BOTH columns)
ALTER TABLE users ADD COLUMN email_verified_at timestamptz;

-- Step 2: Backfill in batches (run during off-peak)
DO $$
DECLARE batch_size INT := 5000; last_id BIGINT := 0; updated INT;
BEGIN
  LOOP
    UPDATE users SET email_verified_at = created_at
    WHERE id IN (
      SELECT id FROM users
      WHERE id > last_id AND email_verified_at IS NULL
      ORDER BY id LIMIT batch_size
    )
    RETURNING id INTO last_id;
    GET DIAGNOSTICS updated = ROW_COUNT;
    COMMIT;
    EXIT WHEN updated = 0;
    PERFORM pg_sleep(0.05);
  END LOOP;
END $$;

-- Step 3: Deploy code that reads new column only
-- Step 4: DROP old column (next release cycle — confirm code no longer reads it)
ALTER TABLE users DROP COLUMN email_verified;
```

### NOT NULL column addition (blocking → non-blocking)

```sql
-- WRONG (locks entire table during backfill):
ALTER TABLE orders ADD COLUMN status text NOT NULL DEFAULT 'pending';

-- RIGHT: three-step approach
-- Step 1: Add nullable with default
ALTER TABLE orders ADD COLUMN status text DEFAULT 'pending';

-- Step 2: Backfill (in batches, as above)

-- Step 3: Set NOT NULL (fast path in PG 11+: validates without full table lock)
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;
```

---

## Phase 4: Production Execution

```bash
# Pre-flight checklist
echo "=== Pre-Migration Checklist ==="
echo "[ ] Staging migration succeeded: YES/NO"
echo "[ ] Staging migration duration: ____ ms"
echo "[ ] Pre-migration snapshot ID: ${SNAPSHOT_ID}"
echo "[ ] PITR confirmed enabled: YES/NO"
echo "[ ] Down migration script exists and tested: YES/NO"
echo "[ ] Application team notified: YES/NO"
echo "[ ] Monitoring dashboard open: YES/NO"
echo "[ ] Off-peak window selected: YES/NO"
echo ""
read -p "All checks passed? (yes to continue): " confirm
[ "$confirm" != "yes" ] && echo "Aborting." && exit 1

# Execute migration
echo "Starting migration at $(date -u)"
# <run migration tool command here>

echo "Migration completed at $(date -u)"
```

---

## Phase 5: Post-Migration Validation

```sql
-- 1. Row count sanity check (compare with pre-migration snapshot count)
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE relname IN ('users', 'orders', 'payments')
ORDER BY relname;

-- 2. Verify new schema elements exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'orders' AND column_name = 'discount_amount';

-- 3. Check for long-running queries (migration shouldn't leave locks)
SELECT pid, state, query_start, state_change, query
FROM pg_stat_activity
WHERE state != 'idle' AND datname = current_database()
  AND now() - query_start > interval '30 seconds';

-- 4. Check replication lag (for read replicas)
SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn,
  (sent_lsn - replay_lsn) AS replication_lag_bytes
FROM pg_stat_replication;
```

```bash
# 5. Application smoke test
curl -sf https://api.example.com/health || echo "HEALTH CHECK FAILED"

# 6. Check error rate in Prometheus/CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=${ALB_ARN_SUFFIX} \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Sum --output table
```

---

## Phase 6: Rollback Procedure

```bash
# Option A: Down migration (preferred — app and DB stay in sync)
# Flyway: flyway undo
# Alembic: alembic downgrade -1
# Liquibase: liquibase rollback --tag=pre-migration

# Option B: PITR (nuclear option — use if data corruption occurred)
RESTORE_TIME="2026-02-15T03:45:00Z"  # 5 minutes before migration started
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ${DB_IDENTIFIER} \
  --target-db-instance-identifier ${DB_IDENTIFIER}-restored \
  --restore-time ${RESTORE_TIME}

# After PITR restore — point application to restored instance
# Update connection string in Secrets Manager / SSM

# Option C: Snapshot restore (if PITR unavailable)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ${DB_IDENTIFIER}-restored \
  --db-snapshot-identifier ${SNAPSHOT_ID}
```

**PITR vs Snapshot decision:**
- PITR: use when you need to restore to a specific moment in time (e.g., before an accidental DELETE)
- Snapshot: use when PITR is not available or you want a faster restore of a known-good state

---

## Post-Migration Report

```
=== Database Migration Report ===
Date: $(date -u)
Environment: ${ENVIRONMENT}
DB Instance: ${DB_IDENTIFIER}

Migration: <describe what was migrated>
Duration: <staging time> (staging), <production time> (production)
Rows affected: <count>

Pre-migration snapshot: ${SNAPSHOT_ID}
Down migration: <exists / not applicable>

Validation:
  Row count check:    [ PASS / FAIL ]
  Schema check:       [ PASS / FAIL ]
  Application health: [ PASS / FAIL ]
  Error rate:         [ NORMAL / ELEVATED ]
  Replication lag:    [ NORMAL / ELEVATED ]

Overall: [ SUCCESSFUL / ROLLED BACK ]
```

---
**Used by:** database-engineer (Data pack)
**Related playbooks:** dr-restore.md, rollback-strategy.md
