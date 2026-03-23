# Agent Capabilities — Referência Detalhada
**Versão:** v10.2.0

> **ANEXO IV** — Documento complementar ao [README.md](README.md). Para casos de uso práticos, veja [ANEXO I](ANEXOI-MANUAL-CASOS-DE-USO.md). Para arquitetura interna, veja [ANEXO II](ANEXOII-ARQUITETURA.md). Para referência operacional, veja [ANEXO III](ANEXOIII-AI-OS-Brutal-Edition.md).

Referência completa das capacidades de cada agent. Marcus consulta este arquivo para routing informado e brainstorm colaborativo.

## Como usar este documento

- **Marcus** consulta o catálogo inline (resumido) durante triagem e routing. Para decisões complexas, lê este ANEXO IV.
- **Você** consulta quando quer saber exatamente o que um agent faz antes de invocar.
- **Prompt-engineer** consulta ao gerar prompts otimizados — precisa saber o vocabulário e patterns de cada agent.

## Resumo por Pack

| Pack | Agents | Modelo dominante | Foco |
|------|--------|-----------------|------|
| **Dev** | 6 | Sonnet (Opus: architect) | Design + implementação Java/Spring Boot |
| **QA** | 8 | Sonnet (Haiku: qa-lead) | Testes unitários, integração, segurança, performance |
| **DevOps** | 11 | Sonnet (Haiku: devops-lead, finops) | Infra, CI/CD, K8s, observabilidade, segurança ops |
| **Data** | 3 | Sonnet | PostgreSQL, MySQL, schema, tuning |
| **Migration** | 7 | Sonnet (Opus: tech-lead, Haiku: domain-analyst) | Strangler Fig, DDD, extração |
| **Utility** | 2 | Sonnet | Routing (Marcus) + geração de prompts |

---

## Dev Pack (6 agents)

### architect (model: opus, memory: user)
**Papel:** Arquiteto de software — decisões estruturais e trade-offs.
**Capacidades:**
- Design de serviços: responsabilidades, limites, comunicação
- Trade-offs: avalia opções com prós, contras e impacto
- ADRs (Architecture Decision Records): documenta decisões com contexto
- Padrões distribuídos: Saga, CQRS, Event Sourcing, Outbox, Circuit Breaker
- Evolução arquitetural: caminhos de migração e modernização
**Sabe sobre:** Kafka, Redis, cache strategies, event-driven, DDD, hexagonal
**Quando usar:** Decisões que impactam múltiplos serviços, avaliação de trade-offs, ADRs

### backend-dev (model: sonnet, memory: user, context: fork)
**Papel:** Engenheiro backend sênior Java/Spring Boot.
**Capacidades:**
- Domain model: entidades, VOs, aggregates com invariantes
- Use cases: lógica de aplicação com arquitetura hexagonal (8 passos)
- Adapters in: controllers REST, Kafka consumers, validação
- Adapters out: JPA repositories, Kafka producers, HTTP clients, cache
- Config: Spring beans, security, profiles, properties
- Migration: Flyway SQL generation
- Detecta versão Java (8/21/25+) do pom.xml e adapta patterns
**Sabe sobre:** Hexagonal, Kafka, Redis, cache-aside, Outbox Pattern, multi-tenancy, virtual threads, structured concurrency, Problem Details (RFC 9457)
**Quando usar:** Implementação de features, endpoints, integrações, código de produção

### api-designer (model: sonnet)
**Papel:** Designer de APIs REST.
**Capacidades:**
- Design de recursos: nomes, hierarquias, relações
- OpenAPI 3.1 spec completa e versionada
- Paginação cursor-based e filtros
- Error responses com Problem Details (RFC 9457)
- Versionamento de API (/api/v1/)
**Sabe sobre:** REST, OpenAPI, JWT, HTTP semantics
**Quando usar:** Design de novos endpoints, documentação de API, contratos

### devops-engineer (model: sonnet, context: fork)
**Papel:** DevOps para contexto de desenvolvimento.
**Capacidades:**
- Docker: imagens otimizadas, multi-stage, seguras
- Kubernetes: Deployments, probes, HPA, PDB, resources, network policies
- Helm: charts configuráveis por ambiente
- CI/CD: pipelines com quality gates
- Observabilidade: Prometheus, Grafana, alertas
- Dev local: docker-compose com todas as dependências
**Sabe sobre:** Docker, Kubernetes, Helm, Prometheus, Grafana, PostgreSQL, Kafka
**Quando usar:** Containerização, Helm charts, docker-compose, deploy configs

### code-reviewer (model: sonnet, memory: user)
**Papel:** Revisor de código multi-perspectiva.
**Capacidades:**
- Correção: bugs, edge cases, race conditions, null safety
- Design: aderência a hexagonal, SRP, coesão, acoplamento
- Legibilidade: nomes, estrutura, complexidade cognitiva
- Segurança: injection, auth, dados sensíveis, validação
- Performance: N+1, queries ineficientes, memory leaks
- Padrões: convenções do projeto, consistência
**Sabe sobre:** Hexagonal, Kafka, cache, Problem Details, Flyway, Pact
**Quando usar:** Review pré-merge, auditoria de qualidade, mentoria

### refactoring-engineer (model: sonnet, context: fork)
**Papel:** Especialista em refatoração segura.
**Capacidades:**
- Safe refactoring com testes como rede de segurança
- Complexity reduction (ciclomática e cognitiva)
- Extract: módulos, classes, métodos, interfaces
- Dead code removal
- Pattern migration: legado → moderno (callback → CompletableFuture)
- SOLID enforcement
**Quando usar:** Redução de dívida técnica, simplificação, modernização

---

## QA Pack (8 agents)

### qa-lead (model: haiku, memory: project)
**Papel:** Estrategista de qualidade.
**Capacidades:**
- Estratégia de testes: o quê, como, quanto, quando
- Análise de risco: priorizar por risco técnico e de negócio
- Quality gates: critérios que bloqueiam release
- Pirâmide de testes: proporção saudável entre camadas
- Métricas de qualidade mensuráveis
**Sabe sobre:** Testcontainers, Pact, SonarQube
**Quando usar:** Auditoria de qualidade, definição de estratégia, quality gates

### unit-test-engineer (model: sonnet, context: fork)
**Papel:** Gerador de testes unitários.
**Capacidades:**
- Gerar testes para domain model, use cases, services, validators
- TDD: Red → Green → Refactor
- Edge cases: limites, nulls, coleções vazias, concorrência
- Mutation testing com Pitest
**Quando usar:** Gerar testes unitários, TDD, cobrir edge cases

### integration-test-engineer (model: sonnet, context: fork)
**Papel:** Testes de integração com infra real.
**Capacidades:**
- Testcontainers: PostgreSQL, Kafka, Redis, Elasticsearch
- Repository tests com banco real
- Messaging tests: Kafka producer/consumer end-to-end
- Cache tests: Redis operations
- Migration tests: Flyway sem erro
- Context tests: Spring Boot context carrega
**Sabe sobre:** Testcontainers, Kafka, Redis, PostgreSQL, Docker, Outbox
**Quando usar:** Testes com banco/Kafka/Redis real, validar migrations

### contract-test-engineer (model: sonnet)
**Papel:** Contratos entre serviços.
**Capacidades:**
- Contratos REST com Pact / Spring Cloud Contract
- Contratos Kafka: schema versionado com compatibilidade
- Consumer-driven contracts
- Backward compatibility validation
- CI integration
**Quando usar:** Garantir paridade entre serviços, pré-deploy validation

### performance-engineer (model: sonnet, context: fork)
**Papel:** Testes de performance.
**Capacidades:**
- Load tests: carga normal sustentada (Gatling, k6)
- Stress tests: onde é o limite
- Soak tests: memory leak, degradação
- Spike tests: Black Friday, flash sale
- Baseline: referência de performance
- Bottleneck analysis: DB? rede? CPU? GC?
**Quando usar:** Validar SLOs, encontrar gargalos, pré-release

### e2e-test-engineer (model: sonnet, context: fork)
**Papel:** Testes end-to-end.
**Capacidades:**
- API testing: fluxos REST completos com RestAssured
- E2E flows: cenários multi-step
- Smoke tests: validação pós-deploy
- Cross-service: fluxos que cruzam serviços
**Quando usar:** Validar fluxos completos de usuário

### test-automation-engineer (model: sonnet)
**Papel:** Automação e otimização de testes.
**Capacidades:**
- Test generation a partir de código fonte
- Flaky detection: diagnosticar e corrigir testes instáveis
- Bug reproduction: transformar bugs em testes
- Coverage gaps: preencher lacunas críticas
- Mutation testing: Pitest
- Suite optimization: paralelizar, reduzir tempo
**Quando usar:** Flaky tests, gaps de cobertura, Pitest, otimização de suite

### security-test-engineer (model: sonnet)
**Papel:** Testes de segurança OWASP.
**Capacidades:**
- Auth bypass: sem token, token inválido, role insuficiente
- OWASP Top 10: injection, broken auth, sensitive data exposure
- Input validation: payloads maliciosos, fuzzing
- Dependency audit: CVEs com Trivy
- IDOR: acesso cross-tenant
- Data exposure: PII em logs, erros, headers
**Quando usar:** Auditoria OWASP, testes de auth, pré-release security

---

## DevOps Pack (11 agents)

### devops-lead (model: haiku, memory: project)
**Papel:** Estrategista de plataforma.
**Capacidades:**
- Estratégia de plataforma: padrões, ferramentas, evolução
- FinOps: custo, rightsizing, reservas, spot, waste
- SLOs/SLIs: objetivos operacionais mensuráveis
- Capacity planning: crescimento, escalabilidade
- Governança: compliance, segurança operacional
**Quando usar:** Decisões de plataforma, capacity planning, SLOs

### iac-engineer (model: sonnet, context: fork)
**Papel:** Infrastructure as Code com Terraform.
**Capacidades:**
- Módulos Terraform reutilizáveis e parametrizáveis
- State management: remote state, locking, workspaces
- Provisioning: K8s, databases, cache, messaging, networking
- Multi-environment: dev/staging/prod com mesma base
- Security: least privilege IAM, encryption, network isolation
**Sabe sobre:** Terraform, AWS (EKS, RDS, Redis), PostgreSQL
**Quando usar:** Criar/modificar infra, módulos Terraform, state management

### cicd-engineer (model: sonnet, context: fork)
**Papel:** Pipelines CI/CD.
**Capacidades:**
- Pipelines: build → test → quality gate → scan → image → deploy
- GitOps: ArgoCD/FluxCD para deploy declarativo
- Quality gates: Sonar, security scan, coverage, contract tests
- Deploy strategies: rolling, canary, blue-green
- Optimization: cache, paralelismo, incremental builds
**Sabe sobre:** GitHub Actions, ArgoCD, SonarQube, Trivy, Docker
**Quando usar:** Criar/otimizar pipelines, quality gates, deploy automation

### kubernetes-engineer (model: sonnet, context: fork)
**Papel:** Especialista Kubernetes.
**Capacidades:**
- Workloads: Deployments, StatefulSets, Jobs, CronJobs
- Autoscaling: HPA, VPA, Karpenter, Cluster Autoscaler
- Networking: Services, Ingress, NetworkPolicy, DNS
- Resources: requests/limits, PDB, topology, affinity
- Spot instances: tolerância, graceful shutdown
- Troubleshooting: CrashLoopBackOff, OOMKilled, scheduling failures
**Quando usar:** Troubleshooting K8s, autoscaling, networking, resource tuning

### observability-engineer (model: sonnet, memory: user)
**Papel:** Observabilidade completa.
**Capacidades:**
- Métricas: Prometheus scraping, recording rules, PromQL
- Dashboards: Grafana com USE/RED method
- Logs: Loki, structured logging, correlação com traces
- Traces: OpenTelemetry, Jaeger/Tempo
- Alertas: SLO-based com burn rate
**Sabe sobre:** Prometheus, Grafana, Kafka, Redis, Kubernetes, SLOs
**Quando usar:** Dashboards, alertas, SLOs, troubleshooting de performance

### security-ops (model: sonnet, memory: user)
**Papel:** Segurança operacional de infra.
**Capacidades:**
- Secrets: Vault, Kubernetes Secrets, Secrets Manager
- RBAC: Kubernetes RBAC, cloud IAM, service accounts
- Network: NetworkPolicy, pod isolation, egress control
- Scanning: image scanning, SAST, runtime
- Hardening: pod security, CIS benchmarks
- Compliance: auditoria, logging, LGPD
**Sabe sobre:** Vault, Kubernetes, Redis, Kafka, EKS, NetworkPolicy
**Quando usar:** Hardening, secrets, RBAC, compliance, scanning

### service-mesh-engineer (model: sonnet)
**Papel:** Service mesh (Istio/Linkerd).
**Capacidades:**
- mTLS: criptografia automática entre serviços
- Traffic management: canary, mirror, fault injection, retries
- Authorization: políticas L7 entre serviços
- Observabilidade: service graph, latência inter-serviço
- Rate limiting
**Sabe sobre:** Istio, canary, NetworkPolicy
**Quando usar:** mTLS, traffic shifting, canary com mesh, rate limiting

### sre-engineer (model: sonnet, memory: user)
**Papel:** Site Reliability Engineering.
**Capacidades:**
- Incident response: diagnóstico, mitigação, comunicação, status updates
- Postmortems: blameless com timeline, root cause, action items
- Chaos engineering: game days, fault injection
- Disaster recovery: DR plans, RTO/RPO, validação
- Capacity planning: projeção de carga, limites
- Runbooks: guias operacionais por serviço
**Sabe sobre:** Prometheus, Helm, Istio, Redis, SLOs
**Quando usar:** Incidentes, postmortems, chaos, DR, capacity planning

### aws-cloud-engineer (model: sonnet)
**Papel:** Arquitetura AWS.
**Capacidades:**
- Compute: EKS, ECS, Lambda, EC2
- Database: RDS, Aurora, DynamoDB, ElastiCache
- Networking: VPC, ALB, NAT, VPC Endpoints
- Storage: S3, EBS, EFS
- Security: IAM policies, KMS, Security Groups
- Cost: estimativas por componente
**Sabe sobre:** EKS, RDS, Aurora, Redis, Terraform, PostgreSQL
**Quando usar:** Projetar arquitetura AWS, trade-offs de serviços, IAM

### finops-engineer (model: haiku)
**Papel:** Otimização de custos cloud.
**Capacidades:**
- Análise de custo por categoria e serviço
- Rightsizing candidates (EC2, RDS)
- Waste detection: ELBs idle, EBS unattached, snapshots órfãos
- Savings Plans / Reserved Instances coverage
- Spot instance strategy
**Sabe sobre:** Terraform, EKS, RDS, Kubernetes, Savings Plans
**Quando usar:** Reduzir custos, rightsizing, waste elimination

### gitops-engineer (model: sonnet)
**Papel:** GitOps com ArgoCD/FluxCD.
**Capacidades:**
- ArgoCD Application manifests
- Sync policy: auto-sync, prune, self-heal
- Argo Rollouts: canary com analysis template
- Image Updater: write-back automático
- AppProject com RBAC
**Sabe sobre:** Helm, ArgoCD, Kubernetes, EKS, Istio, canary
**Quando usar:** Configurar GitOps, progressive delivery, Argo Rollouts

---

## Data Pack (3 agents)

### dba (model: sonnet, memory: project, context: fork)
**Papel:** Database Administrator para schema e queries.
**Capacidades:**
- Schema design: tabelas, relações, tipos, constraints
- Migrations: Flyway, zero-downtime, rollback
- Indexação: índices compostos para queries frequentes
- Query tuning: EXPLAIN ANALYZE, query rewrite
- JPA mapping: evitar N+1, lazy loading, cascade
- Retenção: archiving, particionamento, purge
- Outbox table para event publishing
**Sabe sobre:** PostgreSQL, Flyway, EXPLAIN ANALYZE, Testcontainers
**Quando usar:** Schema design, migrations, query optimization, JPA tuning

### database-engineer (model: sonnet, memory: project, context: fork)
**Papel:** Engenheiro de banco PostgreSQL/Aurora.
**Capacidades:**
- PostgreSQL tuning: parâmetros, VACUUM, bloat
- RDS/Aurora: configuração, failover, read replicas
- Replication: streaming, logical
- Performance: pg_stat_statements, slow queries
- Backup: PITR, snapshots, restore
**Sabe sobre:** PostgreSQL, RDS, Aurora, VACUUM, replication, EXPLAIN ANALYZE
**Quando usar:** Tuning PostgreSQL, VACUUM, replication, RDS config

### mysql-engineer (model: sonnet, memory: project, context: fork)
**Papel:** Especialista MySQL/MariaDB.
**Capacidades:**
- MySQL 8.x: charset, collation, InnoDB tuning
- Schema changes: pt-osc, gh-ost para zero-downtime
- Replication: GTID, semi-sync, group replication
- Query optimization: EXPLAIN, index hints
- RDS/Aurora MySQL: configuração específica
**Sabe sobre:** MySQL, replication, GTID, pt-osc, gh-ost, EXPLAIN ANALYZE
**Quando usar:** MySQL tuning, migrations com pt-osc/gh-ost, charset issues

---

## Migration Pack (7 agents)

### tech-lead (model: opus)
**Papel:** Coordenador de migração monólito → microsserviços.
**Capacidades:**
- Priorização de extração: risco × valor × acoplamento
- ADRs para decisões de migração
- Planos de migração com dependências e critérios de sucesso
- Matriz de acoplamento entre módulos
- Coordenação end-to-end
**Sabe sobre:** Strangler Fig, Pact, bounded contexts, RDS
**Quando usar:** Coordenar migração, priorizar extrações, ADRs de migração

### domain-analyst (model: haiku)
**Papel:** Analista de domínio DDD.
**Capacidades:**
- Event Storming: commands, events, aggregates, policies
- Bounded Contexts: descobrir contextos implícitos
- Context Mapping: customer-supplier, conformist, ACL
- Domain Events que cruzam fronteiras
- Mapeamento de dependências
**Sabe sobre:** Event Storming, bounded contexts, Saga
**Quando usar:** Mapear bounded contexts, Event Storming, dependências

### backend-engineer (model: sonnet, context: fork)
**Papel:** Engenheiro de migração (extração de código).
**Capacidades:**
- Criar seams no monólito (interfaces nos limites)
- Implementar microsserviços extraídos
- Portar regras de negócio com paridade funcional
- Padrões distribuídos: Outbox, Saga, idempotência, circuit breaker
- Kafka producers/consumers robustos com DLQ
**Sabe sobre:** Hexagonal, Outbox, Saga, Kafka, Testcontainers, Docker
**Quando usar:** Extrair código do monólito, criar seams, Strangler Fig

### data-engineer (model: sonnet, context: fork)
**Papel:** Engenheiro de dados para migração.
**Capacidades:**
- Inventário de schema: tabelas, views, procedures, triggers
- Estratégia de split: separar banco por serviço
- Migração de dados: CDC, dual-write, ETL, sync temporário
- Validação de integridade pós-migração
- Substituir FKs cross-context por event/API/cache
**Sabe sobre:** CDC, cache, Flyway
**Quando usar:** Split de schema, CDC, dual-write, validação de dados

### platform-engineer (model: sonnet)
**Papel:** Infra para coexistência monólito + microsserviços.
**Capacidades:**
- Kubernetes: Helm, probes, HPA, PDB, network policies
- CI/CD: pipelines com quality gates
- Observabilidade: Prometheus, Grafana, tracing
- Roteamento: shadow traffic, canary, blue-green, feature flags
- Docker: multi-stage, non-root
- Coexistência: monólito e microsserviços juntos
**Quando usar:** Routing durante migração, shadow traffic, infra de coexistência

### qa-engineer (model: sonnet)
**Papel:** QA de migração.
**Capacidades:**
- Paridade funcional: microsserviço = módulo extraído
- Contract tests: REST e Kafka
- Regressão: monólito estável após extração
- Carga: microsserviço >= módulo no monólito
- Chaos: resiliência nos pontos de integração
- Baseline de comportamento atual
**Quando usar:** Validar paridade, contract tests de migração, chaos

### security-engineer (model: sonnet)
**Papel:** Segurança de migração.
**Capacidades:**
- Superfície de ataque: auditar novos endpoints
- Auth entre serviços: mTLS, JWT, service accounts
- RBAC/ABAC distribuído corretamente
- Dados sensíveis: classificar, proteger, auditar
- Compliance: LGPD, retenção, trilha de auditoria
- API hardening: rate limiting, validação
**Sabe sobre:** JWT, RBAC, Vault, Kubernetes, Istio
**Quando usar:** Distribuir auth por serviço, hardening, compliance

---

## Utility (2 agents)

### marcus (model: sonnet, memory: user)
**Papel:** Orquestrador global — roteia, nunca implementa.

### prompt-engineer (model: sonnet, memory: user)
**Papel:** Gerador de prompts, agents, skills, commands, playbooks.
**Capacidades:**
- Gerar prompts otimizados para qualquer agent
- Criar novos agents com frontmatter completo
- Criar skills, commands, playbooks alinhados ao ecossistema
- Otimizar prompts existentes
- Recomendar modelo + effort por tarefa
**Quando usar:** /gen-prompt, criar artefatos, otimizar prompts
