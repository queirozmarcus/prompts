# Migration Artifacts

Este diretório contém os artefatos gerados pela equipe de migração.

## Estrutura

```
docs/migration/
  adr/              → Architecture Decision Records (ADR-000, ADR-001, ...)
  context-maps/     → Mapas de bounded contexts, dependências, ownership de dados
  extraction-cards/ → Fichas de extração por bounded context
  runbooks/         → Runbooks operacionais por microsserviço
  baselines/        → Golden datasets e baselines de performance
```

## Como os artefatos são gerados

| Comando | Artefatos |
|---------|-----------|
| `/migration-discovery` | context-maps/*, adr/ADR-000, extraction-ranking.md, security-assessment.md |
| `/migration-prepare {ctx}` | baselines/{ctx}-golden-dataset.json, baselines/{ctx}-performance.md |
| `/migration-extract {ctx}` | adr/ADR-00N, runbooks/{ctx}-service.md, extraction-cards/{ctx}.md |
| `/migration-decommission {ctx}` | adr/ADR-00N (decommission), atualização de context-maps |
