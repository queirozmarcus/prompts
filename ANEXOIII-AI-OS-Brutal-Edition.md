# AI-OS Backend & DevOps — Brutalist Operational Edition v10.2.0

> **ANEXO III** — Documento complementar ao [README.md](README.md). Para casos de uso detalhados, veja [ANEXO I](ANEXOI-MANUAL-CASOS-DE-USO.md). Para arquitetura interna, veja [ANEXO II](ANEXOII-ARQUITETURA.md). Para capacidades dos agents, veja [ANEXO IV](ANEXOIV-AGENT-CAPABILITIES.md).

## Filosofia

Um comando = uma ação clara.
Sem ambiguidade. Sem teoria desnecessária.
Marcus roteia tudo: `claude --agent marcus`.

---

## ÁRVORE DE DECISÃO RÁPIDA

### Criar

| Situação | Comando |
|----------|---------|
| Novo serviço (código só) | `/dev-bootstrap` |
| Novo serviço (código + testes + infra + pipeline + observabilidade) | `/full-bootstrap` |
| Nova feature end-to-end | `/dev-feature` |
| Nova API REST com OpenAPI | `/dev-api` |
| Nova infra completa (IaC + K8s + CI/CD + Obs + Sec) | `/devops-provision` |
| Pipeline CI/CD | `/devops-pipeline` |
| GitOps com ArgoCD/FluxCD | `/devops-gitops` |
| Service mesh (Istio/Linkerd) | `/devops-mesh` |
| Observabilidade (Prometheus + Grafana + tracing) | `/devops-observe` |
| Migration de schema zero-downtime | `/data-migrate` |

### Testar

| Situação | Comando |
|----------|---------|
| Gerar testes (unit + integration) | `/qa-generate` |
| Contract tests entre serviços | `/qa-contract` |
| Testes E2E de fluxo completo | `/qa-e2e` |
| Testes de performance (load/stress/soak) | `/qa-performance` |
| Testes de segurança OWASP | `/qa-security` |
| Teste flaky intermitente | `/qa-flaky` |
| Revisar gaps de cobertura | `/qa-review` |
| Auditoria completa de qualidade | `/qa-audit` |

### Diagnosticar

| Situação | Comando |
|----------|---------|
| Incidente em produção | `/devops-incident` |
| Query lenta / N+1 / full scan | `/data-optimize` |
| Custo alto na cloud | `/devops-finops` |
| Auditoria de segurança/compliance | `/devops-audit` |
| Disaster recovery | `/devops-dr` |
| Arquitetura AWS | `/devops-cloud` |

### Refatorar / Migrar

| Situação | Comando |
|----------|---------|
| Refatoração segura | `/dev-refactor` |
| Code review | `/dev-review` |
| Discovery do monólito | `/migration-discovery` |
| Preparar monólito para extração | `/migration-prepare` |
| Extrair bounded context | `/migration-extract` |
| Decomissionar módulo migrado | `/migration-decommission` |

### Utilidade

| Situação | Comando |
|----------|---------|
| Gerar/otimizar prompt para agent/skill/command | `/gen-prompt` |

---

## COMANDOS ESSENCIAIS — EXEMPLOS REAIS

### /full-bootstrap
**Objetivo:** Serviço production-ready do zero (código + testes + infra + pipeline)

**Lite:**
```
/full-bootstrap order-service aws
```

**Full:**
```
/full-bootstrap "order-service com:
- Hexagonal architecture, Java 21, Spring Boot 3.2
- PostgreSQL + Redis cache
- Kafka producer com Outbox Pattern
- Testcontainers + contract tests
- EKS com spot instances, HPA, probes
- GitHub Actions com quality gates
- Prometheus + Grafana + OpenTelemetry"
```

---

### /dev-feature
**Objetivo:** Feature completa: API → use case → persistence → review

**Lite:**
```
/dev-feature "CRUD de pedidos com validações"
```

**Full:**
```
/dev-feature "Implementar criação de pedido com:
- Validação de estoque via client do inventory-service
- Evento OrderCreated publicado via Kafka (Outbox)
- Idempotência por correlation ID
- Circuit breaker no client externo
- Testes unitários + integração com Testcontainers"
```

---

### /devops-incident
**Objetivo:** Guiar resposta a incidente e gerar postmortem

**Lite:**
```
/devops-incident "order-service com latência alta"
```

**Full:**
```
/devops-incident "order-service retornando 503 intermitente:
- Começou há 20min após deploy v2.3.1
- Logs mostram connection pool exhausted
- Métricas: p99 latency saltou de 200ms para 8s
- Afeta 30% das requests"
```

---

### /devops-provision
**Objetivo:** Provisionar infra completa para serviço

**Lite:**
```
/devops-provision "EKS + RDS para order-service"
```

**Full:**
```
/devops-provision "Infra para order-service:
- EKS com Karpenter e spot instances
- RDS PostgreSQL multi-AZ com read replica
- ElastiCache Redis cluster mode
- ALB com WAF
- Terraform modular, 3 ambientes (dev/staging/prod)
- Prometheus + Grafana + alertas SLO-based"
```

---

### /data-optimize
**Objetivo:** Análise de query, indexação e tuning

**Lite:**
```
/data-optimize "SELECT * FROM orders WHERE status = 'PENDING' ORDER BY created_at"
```

**Full:**
```
/data-optimize "Query de listagem de pedidos:
- Tabela orders com 50M rows
- JOIN com order_items e customers
- Filtro por status + date range
- Paginação com offset
- Response time atual: 3.2s, target: 200ms"
```

---

### /qa-generate
**Objetivo:** Gerar testes para módulo/classe

**Lite:**
```
/qa-generate "testes para CreateOrderUseCase"
```

**Full:**
```
/qa-generate "Testes completos para o pacote domain.order:
- Unit tests para todas as entidades e value objects
- Integration tests com Testcontainers (PostgreSQL + Kafka)
- Edge cases: estoque insuficiente, pedido duplicado, timeout
- Mutation testing com Pitest (target: 80% score)"
```

---

## WORKFLOWS REAIS

### Incidente em produção
```
1. /devops-incident "descrição do problema"     → diagnóstico + mitigação
2. /data-optimize "query problemática"           → se for bottleneck de DB
3. /devops-observe "alertas para o serviço"      → melhorar monitoramento pós-incidente
```

### Feature nova end-to-end
```
1. /dev-feature "descrição da feature"           → design + implementação + review
2. /qa-generate "testes para o módulo"           → cobertura completa
3. /qa-contract "contrato com serviço X"         → contract tests
4. /devops-pipeline "quality gates"              → CI/CD atualizado
```

### Novo serviço do zero
```
1. /full-bootstrap "nome-do-serviço aws"         → código + testes + infra + pipeline
2. /qa-audit                                     → auditoria de qualidade
3. /devops-audit "nome-do-serviço"               → auditoria de infra
```

### Migração monólito → microsserviço
```
1. /migration-discovery                          → análise do monólito
2. /migration-prepare "módulo X"                 → criar seams e interfaces
3. /migration-extract "bounded context X"        → extrair como microsserviço
4. /migration-decommission "módulo X"            → remover do monólito
```

### Otimização de custos
```
1. /devops-finops "análise do cluster EKS"       → identificar waste
2. /devops-cloud "revisar arquitetura AWS"       → rightsizing + reservas
3. /devops-audit "compliance e segurança"        → garantir que cortes não afetam segurança
```

---

## PLAYBOOKS OPERACIONAIS

13 playbooks prontos em `~/.claude/playbooks/`:

| Playbook | Quando usar |
|----------|------------|
| `incident-response` | Incidente em produção |
| `rollback-strategy` | Rollback de deploy |
| `k8s-deploy-safe` | Deploy seguro em K8s |
| `database-migration` | Migration de schema |
| `terraform-plan-apply` | Aplicar Terraform com segurança |
| `security-audit` | Auditoria de segurança |
| `secret-rotation` | Rotação de secrets |
| `dr-drill` | Simulação de disaster recovery |
| `dr-restore` | Restore de DR real |
| `cost-optimization` | Redução de custos |
| `dependency-update` | Atualizar dependências |
| `network-troubleshooting` | Diagnóstico de rede |
| `validate-ecosystem` | Validar ecossistema de agents |

---

## NÍVEIS DE USO

### Iniciante
Usa comandos com prompts simples (Lite).

### Intermediário
Usa prompts detalhados (Full) e valida as respostas.

### Avançado
Encadeia comandos em sequência (workflows acima).

### Expert
Usa `claude --agent marcus` para orquestração automática. Marcus classifica, planeja e executa.

---

## PROMPT RUIM vs PROMPT CORRETO

**Ruim:**
```
não funciona
```

**Correto:**
```
/devops-incident "order-service retornando 503:
- Pod em CrashLoopBackOff
- Logs: connection refused PostgreSQL port 5432
- Último deploy: v2.3.1 há 15min
- Rollback para v2.3.0 não resolveu"
```

**Regra:** Sempre dar contexto, sempre incluir logs/métricas relevantes, sempre especificar o que já tentou.

---

## REGRA FINAL

IA não substitui você.
Ela amplifica sua capacidade de decisão.
31 commands + 37 agents + Marcus = execução precisa.
