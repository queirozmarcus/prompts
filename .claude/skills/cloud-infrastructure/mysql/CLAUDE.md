# Skill: MySQL

## Scope

MySQL 8.x and MariaDB development and operations — query optimization, schema migrations, replication, RDS MySQL specifics, connection pooling (ProxySQL/RDS Proxy), and zero-downtime schema changes. Applies when working with MySQL or MariaDB on AWS RDS, self-managed instances, or local development environments.

**Related Agent:** `mysql-agent.md`
**Related Playbook:** `database-migration.md`, `dr-restore.md`

**When to use MySQL vs PostgreSQL:**
- **MySQL:** Existing MySQL/MariaDB systems, Laravel/PHP stacks, RDS MySQL already provisioned, teams with deep MySQL expertise
- **PostgreSQL:** New projects (richer feature set, better standards compliance, superior JSON/full-text, better concurrency)
- **Never migrate** an existing healthy MySQL system to PostgreSQL just for the sake of it — operational cost rarely justifies the risk

## Core Principles

- **utf8mb4 always** — never `utf8` (MySQL's `utf8` is actually 3-byte, breaks emojis and many Unicode chars)
- **InnoDB always** — MyISAM lacks ACID, foreign keys, and row-level locking; never use it for new tables
- **EXPLAIN before indexing** — verify the query plan before adding indexes; measure improvement after
- **GTID replication** — use GTID-based replication for easier failover and replica management
- **Nullable columns for migrations** — adding NOT NULL without DEFAULT locks large tables; always add nullable first
- **Charset and collation consistency** — mismatched collations cause implicit conversions and index misses

## MySQL vs PostgreSQL Key Differences

| Feature | MySQL 8.x | PostgreSQL |
|---------|-----------|------------|
| Upsert | `INSERT ... ON DUPLICATE KEY UPDATE` | `INSERT ... ON CONFLICT DO UPDATE` |
| Auto-increment | `AUTO_INCREMENT` | `SERIAL` / `GENERATED ALWAYS AS IDENTITY` |
| Limit/Offset | `LIMIT 10 OFFSET 20` | same |
| String concat | `CONCAT(a, b)` | `a \|\| b` or `CONCAT(a, b)` |
| Boolean | `TINYINT(1)` or `BOOLEAN` (alias) | native `BOOLEAN` |
| JSON | `JSON` column (binary storage) | `JSON` / `JSONB` (JSONB is indexed) |
| Window functions | Supported since 8.0 | Supported (wider feature set) |
| CTEs | Supported since 8.0 (non-recursive: 5.7 workaround) | Supported (including writable CTEs) |
| Full-text | `FULLTEXT` index (InnoDB) | `tsvector` / GIN indexes |
| Case sensitivity | Collation-dependent (default case-insensitive) | Case-sensitive by default |
| Schema | `DATABASE` ≈ schema (no true schema namespacing) | True schemas within a database |

## Schema Design

**Character sets and collations (most important MySQL gotcha):**
```sql
-- Always set at table creation
CREATE TABLE users (
  id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email     VARCHAR(255) NOT NULL,
  name      VARCHAR(255),
  bio       TEXT,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- Verify charset of existing tables
SELECT table_name, table_collation
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY table_name;

-- Convert existing table (locking operation — plan carefully for large tables)
ALTER TABLE users
  CONVERT TO CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

**Data type recommendations:**
- `BIGINT UNSIGNED` for IDs (not INT — you'll hit 2.1B limit eventually)
- `DATETIME(6)` for timestamps with microsecond precision; avoid `TIMESTAMP` (limited range: 1970–2038)
- `DECIMAL(precision, scale)` for money — never `FLOAT` or `DOUBLE` (floating-point errors)
- `VARCHAR(255)` for most strings; `TEXT`/`MEDIUMTEXT` for unbounded content
- `JSON` for semi-structured data (MySQL 8.0+); extract frequently queried keys into columns + virtual columns

**Upsert pattern:**
```sql
-- MySQL upsert
INSERT INTO product_inventory (product_id, stock, updated_at)
VALUES (42, 100, NOW())
ON DUPLICATE KEY UPDATE
  stock = VALUES(stock),
  updated_at = VALUES(updated_at);

-- Multi-row upsert
INSERT INTO page_views (page, date, views)
VALUES
  ('home', '2026-02-26', 1),
  ('about', '2026-02-26', 1)
ON DUPLICATE KEY UPDATE
  views = views + VALUES(views);
```

## Index Strategies

**Composite index column order rule — most selective + most frequently filtered first:**
```sql
-- Query: WHERE customer_id = ? AND status = ? AND created_at > ?
-- Good: customer_id first (high selectivity), then status, then created_at for range
CREATE INDEX idx_orders_customer_status_date
  ON orders (customer_id, status, created_at);

-- Range column must be LAST in composite index for optimal use
-- If you have: WHERE status = 'pending' AND created_at BETWEEN ? AND ?
-- Index: (status, created_at) — range column last
CREATE INDEX idx_orders_status_date ON orders (status, created_at);
```

**Covering indexes (avoid table lookups entirely):**
```sql
-- Query fetches only these columns — include them all in the index
-- EXPLAIN will show "Using index" in Extra column
CREATE INDEX idx_orders_covering
  ON orders (customer_id, status, created_at, total_amount);
```

**Prefix indexes for TEXT/BLOB (required — cannot index full TEXT):**
```sql
-- Index first N characters only
CREATE INDEX idx_articles_title ON articles (title(100));

-- Determine optimal prefix length
SELECT
  COUNT(DISTINCT LEFT(title, 10)) / COUNT(*) AS sel_10,
  COUNT(DISTINCT LEFT(title, 50)) / COUNT(*) AS sel_50,
  COUNT(DISTINCT LEFT(title, 100)) / COUNT(*) AS sel_100,
  COUNT(DISTINCT title) / COUNT(*) AS sel_full
FROM articles;
```

**Invisible indexes (MySQL 8.0+) — test before dropping:**
```sql
-- Make index invisible (optimizer ignores it, but it still exists)
ALTER TABLE orders ALTER INDEX idx_old_status INVISIBLE;

-- Verify query plan doesn't regress, then drop
ALTER TABLE orders DROP INDEX idx_old_status;
```

**Foreign key indexes — MySQL does NOT auto-create them unlike PostgreSQL:**
```sql
-- Always add index on FK columns
ALTER TABLE orders ADD INDEX idx_orders_customer_id (customer_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_customer
  FOREIGN KEY (customer_id) REFERENCES customers(id);
```

## EXPLAIN / EXPLAIN ANALYZE

**Reading EXPLAIN output:**
```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 123 AND status = 'pending';
-- type column (best to worst):
--   const    → single row via primary key or unique index
--   eq_ref   → one row per row from previous table (JOIN with unique key)
--   ref      → index lookup, multiple rows possible (non-unique index)
--   range    → index range scan (BETWEEN, IN, >, <)
--   index    → full index scan (better than ALL, worse than range)
--   ALL      → full table scan — RED FLAG on large tables
-- key: which index was used (NULL = no index used)
-- rows: estimated rows examined (not returned)
-- Extra:
--   "Using index"     = covering index (no table lookup)
--   "Using where"     = post-filter after index lookup
--   "Using filesort"  = sort without index — potential bottleneck
--   "Using temporary" = temp table (often with GROUP BY or DISTINCT)
```

**EXPLAIN ANALYZE (MySQL 8.0.18+) — actual execution stats:**
```sql
EXPLAIN ANALYZE
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'pending'
  AND o.created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY o.created_at DESC
LIMIT 100;
-- Shows: actual rows, actual time, loops — compare to estimated
```

**Force index for testing (do not use in production long-term):**
```sql
SELECT * FROM orders FORCE INDEX (idx_orders_status_date)
WHERE status = 'pending' AND created_at > '2026-01-01';
```

## Query Patterns

**Window functions (MySQL 8.0+):**
```sql
-- Running total and rank within partition
SELECT
  customer_id,
  order_date,
  amount,
  SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
  RANK() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS amount_rank
FROM orders;
```

**CTEs (MySQL 8.0+):**
```sql
WITH monthly_revenue AS (
  SELECT
    DATE_FORMAT(created_at, '%Y-%m') AS month,
    SUM(total) AS revenue
  FROM orders
  WHERE status = 'completed'
  GROUP BY month
),
ranked AS (
  SELECT *, RANK() OVER (ORDER BY revenue DESC) AS rnk
  FROM monthly_revenue
)
SELECT * FROM ranked WHERE rnk <= 3;
```

**JSON functions:**
```sql
-- Extract JSON field
SELECT JSON_EXTRACT(metadata, '$.source') AS source FROM events;
SELECT metadata->>'$.source' AS source FROM events;  -- shorthand, unquotes

-- JSON in WHERE clause (will NOT use index — add generated column if frequent)
SELECT * FROM events WHERE metadata->>'$.type' = 'click';

-- Generated column for JSON indexing
ALTER TABLE events
  ADD COLUMN event_type VARCHAR(50) GENERATED ALWAYS AS (metadata->>'$.type') VIRTUAL,
  ADD INDEX idx_events_type (event_type);
```

**GROUP BY gotcha — ONLY_FULL_GROUP_BY (default in MySQL 5.7+):**
```sql
-- Error in MySQL 5.7+: non-aggregated column in SELECT not in GROUP BY
SELECT user_id, name, MAX(created_at) FROM orders GROUP BY user_id;  -- ERROR if name not unique per user_id

-- Fix: include in GROUP BY or use ANY_VALUE() for non-deterministic columns
SELECT user_id, ANY_VALUE(name), MAX(created_at) FROM orders GROUP BY user_id;
```

## Zero-Downtime Migrations

**Decision matrix:**

| Operation | MySQL 8.0 | Recommendation |
|-----------|-----------|----------------|
| Add nullable column | ALGORITHM=INSTANT (8.0.29+) | Safe — no lock |
| Add column with default | ALGORITHM=INSTANT (8.0.29+) | Safe |
| Add/Drop index | ALGORITHM=INPLACE, LOCK=NONE | Online — small lock at start/end |
| Add NOT NULL column | ALGORITHM=COPY | Use expand/contract |
| Change column type | ALGORITHM=COPY | Use expand/contract |
| Add FULLTEXT index | ALGORITHM=INPLACE | Blocks concurrent DML briefly |
| Add/Drop FK | ALGORITHM=INPLACE, LOCK=NONE (8.0.19+) | Online |
| DROP TABLE | Instant | Irreversible — backup first |

**ALGORITHM=INSTANT (MySQL 8.0.29+) — fastest, no table lock:**
```sql
-- Add nullable column instantly
ALTER TABLE orders
  ADD COLUMN discount_pct DECIMAL(5,2) DEFAULT NULL,
  ALGORITHM=INSTANT;

-- Add column with default instantly
ALTER TABLE orders
  ADD COLUMN is_gift TINYINT(1) NOT NULL DEFAULT 0,
  ALGORITHM=INSTANT;
```

**Online DDL with INPLACE (lock-free after brief metadata lock):**
```sql
ALTER TABLE orders
  ADD INDEX idx_orders_customer_status (customer_id, status),
  ALGORITHM=INPLACE,
  LOCK=NONE;
```

**pt-online-schema-change (Percona Toolkit — for complex alters):**
```bash
pt-online-schema-change \
  --alter "ADD INDEX idx_customer_status (customer_id, status)" \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  D=production,t=orders \
  --execute \
  --progress time,30 \
  --chunk-size=5000 \
  --max-load='Threads_running=50' \
  --critical-load='Threads_running=100'
```

**gh-ost (GitHub — for very large tables with binlog-based migration):**
```bash
gh-ost \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --host="${DB_HOST}" \
  --database="production" \
  --table="orders" \
  --alter="ADD COLUMN discount_pct DECIMAL(5,2) DEFAULT NULL, ADD INDEX idx_discount (discount_pct)" \
  --execute \
  --verbose \
  --exact-rowcount \
  --max-load='Threads_running=50' \
  --critical-load='Threads_running=80'
```

**Batched UPDATE for backfills (avoid single transaction locking all rows):**
```sql
-- Backfill in batches with sleep to avoid replication lag
SET @batch_size = 5000;
SET @last_id = 0;

REPEAT
  UPDATE orders
  SET status_v2 = CASE status
    WHEN 'new' THEN 'pending'
    WHEN 'done' THEN 'completed'
    ELSE status
  END
  WHERE id > @last_id
    AND status_v2 IS NULL
  LIMIT @batch_size;

  SET @last_id = @last_id + @batch_size;
  SELECT SLEEP(0.1);  -- Throttle — adjust based on replication lag
UNTIL ROW_COUNT() = 0 END REPEAT;
```

## Replication

**GTID-based replication (preferred over binlog position):**
```sql
-- Check GTID mode
SHOW VARIABLES LIKE 'gtid_mode';  -- Should be ON

-- Check replication status on replica
SHOW REPLICA STATUS\G
-- Key fields:
--   Replica_IO_Running: Yes
--   Replica_SQL_Running: Yes
--   Seconds_Behind_Source: 0 (lag in seconds)
--   Retrieved_Gtid_Set vs Executed_Gtid_Set (gap = lag)

-- Monitor replication lag via CloudWatch (RDS)
-- Metric: AWS/RDS ReplicaLag
```

**Replication lag monitoring query (on replica):**
```sql
SELECT
  CHANNEL_NAME,
  SERVICE_STATE,
  LAST_ERROR_NUMBER,
  LAST_ERROR_MESSAGE,
  LAST_HEARTBEAT_TIMESTAMP,
  COUNT_TRANSACTIONS_BEHIND_SOURCE AS lag_count
FROM performance_schema.replication_applier_status_by_worker;
```

## Connection Management

**ProxySQL — connection pooling and read/write splitting:**
```sql
-- ProxySQL admin interface (port 6032)
-- Configure servers
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight)
VALUES (1, 'primary.rds.amazonaws.com', 3306, 1),
       (2, 'replica.rds.amazonaws.com', 3306, 1);

-- Write to primary (hostgroup 1), reads to replica (hostgroup 2)
INSERT INTO mysql_query_rules(rule_id, active, match_digest, destination_hostgroup, apply)
VALUES
  (1, 1, '^SELECT.*FOR UPDATE', 1, 1),  -- SELECT FOR UPDATE → primary
  (2, 1, '^SELECT', 2, 1);              -- All other SELECTs → replica

LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;
```

**RDS Proxy for MySQL — connection pooling managed by AWS:**
```bash
# Create RDS Proxy
aws rds create-db-proxy \
  --db-proxy-name prod-mysql-proxy \
  --engine-family MYSQL \
  --auth '[{"AuthScheme":"SECRETS","SecretArn":"arn:aws:secretsmanager:...","IAMAuth":"REQUIRED"}]' \
  --role-arn arn:aws:iam::123456789:role/rds-proxy-role \
  --vpc-subnet-ids subnet-xxx subnet-yyy \
  --vpc-security-group-ids sg-xxx

# Register target (the RDS instance)
aws rds register-db-proxy-targets \
  --db-proxy-name prod-mysql-proxy \
  --db-instance-identifiers prod-mysql
```

**Key connection parameters:**
```
max_connections        — Hard limit; exceeding causes "Too many connections"
wait_timeout           — Idle connection timeout (default 28800s = 8h; reduce to 300-600 for apps)
interactive_timeout    — Same but for interactive sessions
connect_timeout        — Network connection timeout
innodb_lock_wait_timeout — Row lock wait before deadlock error (default 50s; reduce to 10-15 for apps)
```

## RDS MySQL Specifics

**Parameter group — key settings:**
```
innodb_buffer_pool_size    = 75% of total RAM (most important parameter)
max_connections            = calculated: RAM_GB * 75 (rough rule, adjust to app needs)
slow_query_log             = 1 (always enable)
long_query_time            = 1 (log queries > 1 second; reduce to 0.5 for tuning)
log_queries_not_using_indexes = 1 (during tuning only — can flood logs)
binlog_format              = ROW (required for replication and pt-osc/gh-ost)
binlog_retention_hours     = 24 (or higher; RDS default is 0 = no retention)
performance_schema         = 1 (enable for Performance Insights)
```

**Check parameter group applied:**
```bash
aws rds describe-db-instances \
  --db-instance-identifier prod-mysql \
  --query 'DBInstances[0].DBParameterGroups'

# Describe current parameters
aws rds describe-db-parameters \
  --db-parameter-group-name prod-mysql-pg \
  --query 'Parameters[?ParameterValue!=`null`].[ParameterName,ParameterValue,IsModifiable]' \
  --output table
```

**RDS Blue/Green Deployments (zero-downtime major version upgrades):**
```bash
# Create Blue/Green deployment
aws rds create-blue-green-deployment \
  --blue-green-deployment-name prod-mysql-upgrade \
  --source arn:aws:rds:us-east-1:123456789:db:prod-mysql \
  --target-engine-version 8.0.35 \
  --target-db-parameter-group-name prod-mysql-80-pg

# Monitor sync status
aws rds describe-blue-green-deployments \
  --blue-green-deployment-identifier bgd-xxx \
  --query 'BlueGreenDeployments[0].{Status:Status,SwitchoverDetails:SwitchoverDetails}'

# Switchover (fast, ~1 min downtime)
aws rds switchover-blue-green-deployment \
  --blue-green-deployment-identifier bgd-xxx
```

**Enhanced Monitoring and Performance Insights:**
```bash
# Get Performance Insights top SQL
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier db-XXXXXXXXXXXXXXXXXX \
  --metric-queries '[{"Metric":"db.load.avg","GroupBy":{"Group":"db.sql","Limit":10}}]' \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period-in-seconds 60
```

## Backup & Restore

```bash
# Verify backup retention and PITR window
aws rds describe-db-instances \
  --db-instance-identifier prod-mysql \
  --query 'DBInstances[0].{Retention:BackupRetentionPeriod,Earliest:EarliestRestorableTime,Latest:LatestRestorableTime}'

# Manual snapshot before critical operations
aws rds create-db-snapshot \
  --db-instance-identifier prod-mysql \
  --db-snapshot-identifier "pre-migration-$(date +%Y%m%d-%H%M%S)"

# PITR restore
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-mysql \
  --target-db-instance-identifier prod-mysql-restored \
  --restore-time 2026-02-26T10:00:00Z

# mysqldump (logical backup — for smaller databases or subset exports)
mysqldump \
  --single-transaction \
  --routines \
  --triggers \
  --set-gtid-purged=OFF \
  -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" \
  production > production-$(date +%Y%m%d).sql

# Export to S3 from RDS (no mysqldump needed)
aws rds start-export-task \
  --export-task-identifier prod-mysql-export-$(date +%Y%m%d) \
  --source-arn arn:aws:rds:us-east-1:123456789:snapshot:prod-mysql-snap \
  --s3-bucket-name my-db-exports \
  --iam-role-arn arn:aws:iam::123456789:role/rds-export-role \
  --kms-key-id arn:aws:kms:us-east-1:123456789:key/xxx
```

## Security

**Privilege model — least privilege:**
```sql
-- Application user: only what the app needs
CREATE USER 'app'@'%' IDENTIFIED BY 'strong-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON production.* TO 'app'@'%';
-- NOT: GRANT ALL, DROP, ALTER, CREATE, SUPER

-- Read-only analytics user
CREATE USER 'analytics'@'%' IDENTIFIED BY 'another-password';
GRANT SELECT ON production.* TO 'analytics'@'%';

-- Migration user (separate, use only during migrations)
CREATE USER 'migrator'@'%' IDENTIFIED BY 'migration-password';
GRANT SELECT, INSERT, UPDATE, DELETE, ALTER, CREATE, INDEX, DROP ON production.* TO 'migrator'@'%';

-- View grants
SHOW GRANTS FOR 'app'@'%';
```

**Authentication plugin:**
```sql
-- MySQL 8.0 default: caching_sha2_password (more secure)
-- Some older clients require mysql_native_password
SELECT user, plugin FROM mysql.user;

-- Create user with explicit plugin
CREATE USER 'app'@'%' IDENTIFIED WITH caching_sha2_password BY 'password';
```

**TLS enforcement on RDS:**
```bash
# Require SSL for specific user
ALTER USER 'app'@'%' REQUIRE SSL;

# Or enforce at instance level via parameter group
# require_secure_transport = ON
```

**Audit log plugin (RDS MySQL):**
```bash
# Enable audit log via option group
aws rds add-option-to-option-group \
  --option-group-name prod-mysql-og \
  --options 'OptionName=MARIADB_AUDIT_PLUGIN,OptionSettings=[{Name=SERVER_AUDIT_EVENTS,Value=CONNECT,QUERY_DDL}]'
```

## Performance Tuning

**innodb_buffer_pool_size — most impactful parameter:**
```sql
-- Check current hit rate (should be > 99%)
SELECT
  ROUND((1 - (
    SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads'
  ) / (
    SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests'
  )) * 100, 2) AS buffer_pool_hit_pct;
```

**Performance Schema — top slow queries:**
```sql
SELECT
  DIGEST_TEXT AS query_pattern,
  COUNT_STAR AS executions,
  ROUND(AVG_TIMER_WAIT / 1e12, 4) AS avg_sec,
  ROUND(SUM_TIMER_WAIT / 1e12, 2) AS total_sec,
  ROUND(SUM_ROWS_EXAMINED / COUNT_STAR) AS avg_rows_examined,
  ROUND(SUM_ROWS_SENT / COUNT_STAR) AS avg_rows_sent
FROM performance_schema.events_statements_summary_by_digest
WHERE DIGEST_TEXT IS NOT NULL
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10;
```

**sys schema shortcuts:**
```sql
-- Top 10 slowest statements
SELECT * FROM sys.statement_analysis LIMIT 10;

-- Tables with full table scans
SELECT * FROM sys.schema_tables_with_full_table_scans LIMIT 10;

-- Unused indexes
SELECT * FROM sys.schema_unused_indexes WHERE object_schema NOT IN ('performance_schema', 'sys');

-- Current blocking
SELECT * FROM sys.innodb_lock_waits;

-- I/O by table
SELECT * FROM sys.io_global_by_file_by_bytes LIMIT 10;
```

**Slow query log analysis:**
```bash
# Enable slow query log on RDS via parameter group:
# slow_query_log = 1
# long_query_time = 1
# log_output = FILE (goes to CloudWatch) or TABLE

# Parse with mysqldumpslow
mysqldumpslow -s t -t 10 /var/log/mysql/slow.log

# Or use pt-query-digest (better)
pt-query-digest /var/log/mysql/slow.log --limit 10
```

## Common Mistakes / Anti-Patterns

- **`utf8` instead of `utf8mb4`** — MySQL's `utf8` is 3-byte only; emojis and some Unicode chars silently fail or error
- **`SELECT *` in production** — pulls unnecessary columns, prevents covering indexes, breaks when schema changes
- **Missing index on FK column** — MySQL does NOT auto-create indexes on foreign key columns (unlike PostgreSQL)
- **`LIMIT N` without `ORDER BY`** — non-deterministic results; different rows returned on each execution
- **Functions on indexed columns in WHERE** — `WHERE DATE(created_at) = '2026-01-01'` prevents index use; use `WHERE created_at >= '2026-01-01' AND created_at < '2026-01-02'`
- **Implicit type conversions** — `WHERE user_id = '123'` (string vs int) forces full scan; match types
- **MyISAM tables** — no transactions, no row-level locks, no FK support; always use InnoDB
- **No `--single-transaction` in mysqldump** — inconsistent backup of InnoDB tables; always include it
- **`DATETIME` vs `TIMESTAMP`** — `TIMESTAMP` overflows in 2038; use `DATETIME(6)` for new columns
- **Large transactions** — avoid multi-million row UPDATEs in one transaction; use batches
- **`GROUP BY` on non-indexed columns with large tables** — triggers `Using temporary; Using filesort`; add index

## Communication Style

When this skill is active:
- Distinguish MySQL-specific behavior from generic SQL or PostgreSQL behavior
- Flag operations that differ significantly between MySQL and PostgreSQL
- Call out charset/collation issues proactively when schema is involved
- Always specify the MySQL version when recommending features (8.0+, 8.0.29+, etc.)
- Alert on DDL statements that may lock tables in production

## Expected Output Quality

- EXPLAIN / EXPLAIN ANALYZE output with interpretation of `type`, `key`, `rows`, `Extra`
- DDL with explicit `ALGORITHM` and `LOCK` hints for production safety
- Migration scripts with both forward and rollback path
- pt-osc / gh-ost commands with `--max-load` and `--critical-load` guards
- Connection pool calculations with justification
- AWS CLI commands for RDS operations (describe, snapshot, PITR)

---
**Skill type:** Passive
**Applies with:** aws, terraform, nodejs, java, python
**Pairs well with:** mysql-agent, personal-engineering-agent
