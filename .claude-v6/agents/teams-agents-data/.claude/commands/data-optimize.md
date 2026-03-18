---
name: data-optimize
description: "Análise de query, indexação e performance tuning. Orquestra DBA, Database Engineer ou MySQL Engineer conforme o banco."
argument-hint: "[query-ou-tabela] [postgres|mysql]"
---

# Otimização de Dados: $ARGUMENTS

Analise e otimize queries/índices para **$ARGUMENTS**.

## Instruções

### Step 1: Identificar banco

Se o argumento contém "mysql" ou o projeto usa MySQL, use **mysql-engineer**.
Caso contrário, assume PostgreSQL e use **database-engineer**.

### Step 2: Análise

Use o agente apropriado para:
- Executar/analisar EXPLAIN ANALYZE da query
- Verificar índices existentes vs necessários
- Identificar: sequential scans, missing indexes, N+1, bloat
- Verificar connection pool health
- Checar estatísticas da tabela (pg_stat_user_tables / Performance Schema)

### Step 3: Schema review

Use o sub-agente **dba** para:
- Verificar se o schema suporta a query de forma eficiente
- Propor índices compostos, parciais ou covering
- Verificar se migration é necessária para adicionar índice
- Criar migration Flyway se aplicável (CREATE INDEX CONCURRENTLY)

### Step 4: Apresentar

1. Query original + EXPLAIN ANALYZE
2. Problemas identificados com impacto
3. Índices recomendados com justificativa
4. Migration Flyway (se necessário)
5. Performance esperada após otimização
