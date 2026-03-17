# Data Team — Claude Code Agents

## Visão Geral

Equipe de sub-agentes especialistas em banco de dados para projetos com PostgreSQL, MySQL/MariaDB e AWS managed databases. Cobre schema design, migrations, query optimization, replication, disaster recovery e DBA operations.

## A Equipe

| Agente | Especialidade | Quando Usar |
|--------|---------------|-------------|
| **DBA** | Schema design, Flyway migrations, JPA/Hibernate tuning, indexação | Modelagem para Java/Spring Boot, migrations zero-downtime |
| **Database Engineer** | PostgreSQL + AWS RDS/Aurora, VACUUM, connection pooling, PITR, DynamoDB | Operações PostgreSQL, tuning, backup/restore, HA |
| **MySQL Engineer** | MySQL 8.x/MariaDB, RDS MySQL, pt-osc, gh-ost, GTID replication | Operações MySQL, migrations em tabelas grandes, replication |

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/data-optimize` | Análise de query + indexação + recommendations |
| `/data-migrate` | Planejar migration segura (zero-downtime, rollback, validação) |

## Quando Usar Qual Agente

| Situação | Agente |
|----------|--------|
| Modelar schema para projeto Java/Spring Boot | `dba` |
| Criar Flyway migration com zero-downtime | `dba` |
| Otimizar query PostgreSQL (EXPLAIN ANALYZE) | `database-engineer` |
| RDS Aurora operations, failover, PITR | `database-engineer` |
| DynamoDB table design, GSIs | `database-engineer` |
| Otimizar query MySQL, slow query log | `mysql-engineer` |
| Migration em tabela grande MySQL (pt-osc, gh-ost) | `mysql-engineer` |
| Replication lag, GTID, replica promotion | `mysql-engineer` |

## Stack

PostgreSQL 16, MySQL 8.x, MariaDB, AWS RDS/Aurora, DynamoDB, Flyway, JPA/Hibernate, RDS Proxy, PgBouncer, ProxySQL

## Artefatos

```
docs/data/
  migrations/  → Migration plans e rollback procedures
  schemas/     → Schema documentation, ER diagrams
  runbooks/    → Operational runbooks per database
```
