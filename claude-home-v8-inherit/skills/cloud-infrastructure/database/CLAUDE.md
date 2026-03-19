# Skill: Database

## Scope

Design, operação e otimização de bancos de dados em contextos de produção. Cobre RDS (PostgreSQL, Aurora), DynamoDB, ElastiCache, migrations com zero-downtime, connection pooling, backup/restore e performance tuning. Aplicável quando trabalhando com qualquer sistema de persistência em AWS ou self-managed.

## Core Principles

- **Schema changes são irreversíveis em produção** — sempre adicionar antes de remover; planejar rollback para toda migration
- **Connection pool sizing matters** — muitas conexões podem derrubar um banco; pool adequado é crítico
- **Read replicas não são failover automático** — distinguir escala de leitura de alta disponibilidade
- **Backups não testados não existem** — PITR e snapshots devem ser testados em ambiente real regularmente
- **Encrypt at rest and in transit** — dados sensíveis sempre criptografados; TLS obrigatório

## RDS & Relational Databases

**Escolha de engine:**
- **PostgreSQL (RDS):** Padrão para a maioria dos casos — rico em features, community ativa
- **Aurora PostgreSQL:** Storage auto-scale, multi-region, serverless v2 — para cargas críticas
- **Aurora Serverless v2:** Scale instantâneo (ACUs), ideal para workloads variáveis — cobra por ACU por hora
- **MySQL/MariaDB:** See dedicated skill `skills/cloud-infrastructure/mysql/` for in-depth guidance; prefer PostgreSQL for new projects

**Sizing RDS:**
```bash
# Ver utilização atual para rightsizing
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --dimensions Name=DBInstanceIdentifier,Value=prod-db \
  --metric-name CPUUtilization \
  --start-time $(date -d '14 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date +%Y-%m-%dT%H:%M:%S) \
  --period 86400 --statistics Average,Maximum \
  --query 'sort_by(Datapoints,&Timestamp)[*].{Date:Timestamp,Avg:Average,Max:Maximum}'
```

**Multi-AZ vs Read Replicas:**
- **Multi-AZ:** Failover automático (~1-2 min), standby em outra AZ — HA, NÃO escala leitura
- **Read Replicas:** Escala leitura, replication lag pode existir, NÃO failover automático (manual promote)
- **Aurora:** Multi-AZ nativo, read replicas com < 10ms lag, failover em < 30 segundos

**Parameter Group — PostgreSQL importantes:**
```
max_connections         — Pool size × N_replicas; exceder = "too many connections"
shared_buffers          — 25% da RAM total
work_mem               — RAM por operação de sort/hash (cuidado: multiplicado por connections)
maintenance_work_mem    — RAM para VACUUM, CREATE INDEX (maior = mais rápido)
wal_level              — logical para logical replication, replica para default
autovacuum_vacuum_scale_factor  — reduzir para tabelas muito grandes (default 0.2 = 20%)
```

## DynamoDB & NoSQL

**Partition key design — regras:**
- Alta cardinalidade (muitos valores distintos): evitar hotspots
- Distribuição uniforme de acesso: todas as partições usadas igualmente
- Tamanho do item: < 400KB por item

**Access patterns first:**
```
Ruim: modelar dados relacionalmente, depois pentar em DynamoDB
Bom: definir todos os access patterns → derivar partition + sort key + GSI
```

**GSI (Global Secondary Index):**
```json
{
  "AttributeDefinitions": [
    {"AttributeName": "userId", "AttributeType": "S"},
    {"AttributeName": "createdAt", "AttributeType": "S"}
  ],
  "KeySchema": [{"AttributeName": "userId", "KeyType": "HASH"}],
  "GlobalSecondaryIndexes": [{
    "IndexName": "userId-createdAt-index",
    "KeySchema": [
      {"AttributeName": "userId", "KeyType": "HASH"},
      {"AttributeName": "createdAt", "KeyType": "RANGE"}
    ],
    "Projection": {"ProjectionType": "ALL"}
  }]
}
```

**Capacity modes:**
- **On-Demand:** Tráfego imprevisível; mais caro por request mas sem over-provisioning
- **Provisioned + Auto Scaling:** Tráfego estável; mais barato se bem ajustado
- **Regra:** Começar On-Demand, migrar para Provisioned após 4+ semanas de padrão estável

**TTL:** Expirar itens automaticamente sem custo — ideal para sessions, cache, eventos temporários.

## PostgreSQL Deep Dive

**Explaining queries:**
```sql
-- Ver query plan sem executar
EXPLAIN SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';

-- Ver plan e executar (inclui timing real)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM orders WHERE user_id = 123;

-- Seq Scan em tabela grande = problema (checar índice)
-- Nested Loop com Filter rows alto = candidato a índice composto
```

**Índices — padrões:**
```sql
-- Índice simples para coluna de alta seletividade
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Índice composto (ordem importa — campo mais seletivo primeiro)
CREATE INDEX CONCURRENTLY idx_orders_user_status ON orders(user_id, status);

-- Índice parcial (apenas subset de rows — mais eficiente)
CREATE INDEX CONCURRENTLY idx_orders_pending ON orders(created_at)
WHERE status = 'pending';

-- CONCURRENTLY: não bloqueia tabela durante criação (mais lento, mas seguro em prod)
```

**VACUUM e autovacuum:**
```sql
-- Ver tabelas com dead tuples acumulados
SELECT relname, n_dead_tup, n_live_tup, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC LIMIT 10;

-- Forçar vacuum em tabela específica
VACUUM ANALYZE orders;

-- Monitorar long-running queries (podem bloquear vacuum)
SELECT pid, duration, state, query
FROM pg_stat_activity
WHERE state != 'idle' AND duration > interval '5 minutes'
ORDER BY duration DESC;
```

## Database Migrations

**Regra de ouro:** Migrations devem ser backward-compatible com o código anterior e novo.

**Padrão expand-contract para zero-downtime:**
```
Fase 1 (expand):  ADD COLUMN new_col (nullable)
Deploy v1:        Código escreve em ambas old_col e new_col
Fase 2:           Backfill UPDATE SET new_col = old_col WHERE new_col IS NULL
Deploy v2:        Código lê de new_col
Fase 3 (contract): DROP COLUMN old_col (em release separado, semanas depois)
```

**Operações perigosas em produção:**
```sql
-- EVITAR (bloqueia tabela inteira):
ALTER TABLE orders ADD COLUMN total DECIMAL NOT NULL DEFAULT 0;
CREATE INDEX idx_orders_user ON orders(user_id);  -- sem CONCURRENTLY

-- SEGURO:
ALTER TABLE orders ADD COLUMN total DECIMAL;  -- nullable, sem default
ALTER TABLE orders ALTER COLUMN total SET DEFAULT 0;  -- depois
CREATE INDEX CONCURRENTLY idx_orders_user ON orders(user_id);
```

**Migration tools:**
- Node.js: `node-pg-migrate`, `db-migrate`, `Prisma Migrate`
- Python: `Alembic` (SQLAlchemy), `Django migrations`
- Java: `Flyway`, `Liquibase`

**Sempre ter down migration:**
```javascript
// node-pg-migrate
exports.up = (pgm) => {
  pgm.addColumn('orders', { new_status: { type: 'varchar(50)' } });
};
exports.down = (pgm) => {
  pgm.dropColumn('orders', 'new_status');
};
```

## Connection Management

**Pool sizing formula:**
```
max_pool_size = (cpu_cores * 2) + effective_spindle_count
# Para RDS db.r6g.2xlarge (8 vCPUs): max_pool_size ≈ 17-20 per app instance

# Total connections = pool_size × N_app_instances
# Deve ser menor que max_connections do PostgreSQL (- reserva para admin)
```

**PgBouncer — connection pooler:**
```ini
# pgbouncer.ini
[databases]
production = host=prod-db.xxx.rds.amazonaws.com port=5432 dbname=app

[pgbouncer]
pool_mode = transaction       # transaction pooling (mais eficiente)
max_client_conn = 1000        # max conexões de clientes
default_pool_size = 20        # pool de conexões reais ao banco
```

**RDS Proxy** (gerenciado pela AWS):
- Ideal para Lambda e workloads com conexões curtas/frequentes
- Mantém pool de conexões persistentes ao RDS
- Failover transparente (preserva conexões durante Multi-AZ failover)

## Backup & Disaster Recovery

```bash
# Verificar backup retention
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Retention:BackupRetentionPeriod,Window:PreferredBackupWindow}'

# PITR — Point-in-Time Recovery (dentro da janela de retenção)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-db \
  --target-db-instance-identifier prod-db-restored \
  --restore-time 2026-02-25T10:00:00Z

# Snapshot manual antes de mudanças críticas
aws rds create-db-snapshot \
  --db-instance-identifier prod-db \
  --db-snapshot-identifier before-migration-$(date +%Y%m%d)

# Restaurar snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-db-from-snapshot \
  --db-snapshot-identifier before-migration-20260225
```

**Retention strategy:**
- Automated backups: 7 dias para dev/staging, 30 dias para produção
- Manual snapshots antes de migrations críticas ou major upgrades
- Cross-region copy para DR: `aws rds copy-db-snapshot --destination-region us-west-2`

## Security

```sql
-- Criar role com mínimo de permissões
CREATE ROLE app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

CREATE ROLE app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
-- NOT GRANT: DROP, ALTER, TRUNCATE, CREATE

-- Nunca usar o master user na aplicação
-- Criar usuário de aplicação com permissões mínimas
```

**IAM Authentication para RDS:**
```python
import boto3
rds_client = boto3.client('rds')
token = rds_client.generate_db_auth_token(
    DBHostname='prod-db.xxx.rds.amazonaws.com',
    Port=5432,
    DBUsername='app_user'
)
# Usar token como senha (válido por 15 minutos)
```

**Encryption:**
- Sempre habilitar encryption at rest (KMS customer-managed key)
- Enforce SSL: `aws rds modify-db-parameter-group --parameters "ParameterName=rds.force_ssl,ParameterValue=1"`
- Secrets rotation via AWS Secrets Manager (Lambda rotation function)

## Performance & Optimization

**N+1 query — identificar e resolver:**
```javascript
// Problema: N+1 (1 query + N queries)
const orders = await Order.findAll();
for (const order of orders) {
  order.user = await User.findByPk(order.userId); // N queries!
}

// Solução: Eager loading
const orders = await Order.findAll({
  include: [{ model: User }] // JOIN - 1 query
});
```

**Slow query log:**
```sql
-- RDS: habilitar via parameter group
-- log_min_duration_statement = 1000 (log queries > 1 segundo)

-- Verificar no CloudWatch Logs:
-- /aws/rds/instance/prod-db/postgresql
```

**Caching strategy:**
```
Cache de aplicação (Redis):
- Session data: TTL curto (15-30 min)
- Reference data (países, categorias): TTL longo (24h)
- Computed results (dashboards): TTL médio (5-15 min)

Cache-aside pattern:
1. Try cache
2. On miss: query DB
3. Store in cache with TTL
4. Return result
```

## Common Mistakes / Anti-Patterns

- **master user na aplicação** — blast radius enorme se comprometido; criar app user com permissões mínimas
- **`SELECT *` em tabelas grandes** — trafega dados desnecessários; selecionar apenas colunas necessárias
- **Migration sem down** — sem rollback possível; sempre escrever down migration
- **Blocking DDL em produção** — `ALTER TABLE ADD COLUMN NOT NULL` bloqueia; usar nullable + backfill
- **Read replica como backup HA** — replica lag existe; NÃO é failover automático
- **Backup sem teste de restore** — backup não testado = não existe; testar PITR trimestralmente
- **Pool muito grande** — excede `max_connections` do PostgreSQL; matar conexões reais com overhead

## Communication Style

Quando esta skill está ativa:
- Mencionar tipo de banco específico (PostgreSQL, Aurora, DynamoDB) — comportamentos diferentes
- Alertar sobre operações que bloqueiam tabelas em produção
- Sempre mencionar impacto de migrations em dados existentes
- Distinguir entre PITR (recovery granular) e snapshot (ponto específico)

## Expected Output Quality

- SQL com EXPLAIN ANALYZE para diagnosticar performance
- Migration com UP e DOWN completos
- Pool size calculation com justificativa
- Backup/restore commands específicos do AWS CLI

---
**Skill type:** Passive
**Applies with:** aws, security, observability, terraform, nodejs, java
**Pairs well with:** database-engineer (Data pack), data-engineer (Migration pack), aws-cloud-engineer (DevOps pack), architect (Dev pack)
