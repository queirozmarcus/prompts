
# Migration Segura: $ARGUMENTS

Planeje e crie uma migration segura para **$ARGUMENTS**.

## Instruções

### Step 1: Analisar impacto

Use **dba** + o database engineer apropriado (PostgreSQL ou MySQL) para:
- Avaliar a mudança: é destrutiva? Bloqueia a tabela? Por quanto tempo?
- Volume da tabela afetada
- Estratégia: INSTANT? INPLACE? expand-then-contract? pt-osc/gh-ost?
- Impacto em replication lag (MySQL)
- Impacto em VACUUM/bloat (PostgreSQL)

### Step 2: Criar migration

Use **dba** para:
- Criar migration Flyway: `V{n}__{descricao}.sql`
- Se destrutiva: criar em 2+ fases (expand → backfill → contract)
- CREATE INDEX CONCURRENTLY para PostgreSQL
- ALGORITHM=INSTANT ou pt-osc para MySQL
- Down migration (rollback) quando possível

### Step 3: Plano de validação

Use o database engineer apropriado para:
- Queries de validação pré e pós migration
- Contagem de registros, checksums
- Plano de rollback (snapshot, PITR, down migration)
- Checklist de execução por ambiente (staging primeiro)

### Step 4: Apresentar

1. Migration SQL completa
2. Impacto estimado (lock time, replication lag)
3. Plano de execução: staging → validação → prod
4. Plano de rollback
5. Checklist de deploy
