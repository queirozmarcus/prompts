# 🗄️ Data Team — Claude Code Agents

Equipe de sub-agentes especialistas em banco de dados. PostgreSQL, MySQL/MariaDB, AWS RDS/Aurora, DynamoDB, migrations e query optimization.

## A Equipe

| Agente | Cor | Especialidade |
|--------|-----|---------------|
| **DBA** | 🟡 | Schema design, Flyway migrations, JPA/Hibernate, indexação |
| **Database Engineer** | 🟡 | PostgreSQL, RDS/Aurora, VACUUM, connection pooling, PITR, DynamoDB |
| **MySQL Engineer** | 🟡 | MySQL 8.x, MariaDB, pt-osc, gh-ost, GTID replication, ProxySQL |

## Instalação

```bash
cp -r teams-agents-data/.claude/agents/* .claude/agents/
cp -r teams-agents-data/.claude/commands/* .claude/commands/
```

## Slash Commands

### `/data-optimize [query-ou-tabela]` — Otimizar query
EXPLAIN ANALYZE + indexação + migration se necessário.

### `/data-migrate [descrição-da-mudança]` — Migration segura
Zero-downtime plan + rollback + validação + checklist.

## Uso Direto

```
claude> Use o dba para modelar schema do contexto Payment com Flyway
claude> Use o database-engineer para otimizar: SELECT * FROM orders WHERE status = 'CREATED'
claude> Use o mysql-engineer para criar migration pt-osc na tabela com 50M registros
```
