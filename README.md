# Claude Code Agents

Biblioteca de sub-agentes especializados para o Claude Code CLI. **43 agentes** cobrindo desenvolvimento backend, QA, DevOps/SRE, infraestrutura e migracao de monolitos.

## Conceitos Rapidos

Existem **3 formas** de usar um agente:

```bash
# 1. Slash command — orquestra multiplos agentes automaticamente
claude> /dev-feature "criar endpoint de cancelamento de pedido"

# 2. Invocacao direta — pede a um agente especifico
claude> Use o dba para otimizar esta query lenta

# 3. Sessao dedicada — abre o Claude inteiro como aquele agente
claude --agent security-agent
```

**Slash commands** sao o caminho mais eficiente para tarefas completas — eles delegam para os agentes certos na ordem certa. Use invocacao direta para tarefas pontuais. Use sessao dedicada quando precisa de multiplas interacoes com o mesmo especialista.

**Nao sabe qual agente usar?** Pergunte ao `marcus-agent` — ele classifica seu pedido e indica o caminho certo.

## Instalacao

### Cenario 1: Instalar tudo (recomendado)

```bash
cd ~/.claude/agents

# Copiar agentes e commands de todos os packs para uso global
for pack in teams-agents-dev teams-agents-qa teams-agents-devops teams-agents-monolith-migration; do
  cp -r "$pack/.claude/agents/"* ~/.claude/agents/ 2>/dev/null
  cp -r "$pack/.claude/commands/"* ~/.claude/commands/ 2>/dev/null
done
```

Resultado: 30 agentes de pack + 22 slash commands + 13 standalone = tudo disponivel globalmente.

### Cenario 2: Instalar apenas um pack em um projeto

```bash
cd ~/meu-projeto
mkdir -p .claude/{agents,commands}
cp -r ~/.claude/agents/teams-agents-dev/.claude/agents/* .claude/agents/
cp -r ~/.claude/agents/teams-agents-dev/.claude/commands/* .claude/commands/
```

### Cenario 3: Usar apenas standalone agents

Os 13 agentes standalone (`*.md` na raiz) ja funcionam se este diretorio for `~/.claude/agents/`. Nao precisam de instalacao.

---

## Manual do Agent-Marcus

O `marcus-agent` e o **ponto de entrada unico** do ecossistema. Ele conhece todos os 42 agentes especialistas e 22 slash commands, classifica qualquer pedido tecnico e delega para o especialista certo. Nunca implementa — apenas roteia.

### Quando usar o Agent-Marcus

| Situacao | Exemplo |
|----------|---------|
| Nao sabe qual agente usar | "Preciso melhorar a performance do banco" |
| Pedido cruza dominios | "Quero criar um servico novo com testes e deploy" |
| Quer entender o ecossistema | "Quais agentes tenho para seguranca?" |
| Precisa de uma sequencia de acoes | "Como migro um modulo do monolito do inicio ao fim?" |

### Exemplos reais de uso

**Pedido vago — Marcus classifica e roteia:**

```
claude> Use o marcus-agent: preciso melhorar a performance de uma query lenta no PostgreSQL

Marcus responde:
→ Isso e tarefa para o `database-agent` (PostgreSQL specialist).
→ Use: "Use o database-agent para otimizar esta query: [cole a query]"
→ Se precisar tambem de indices e explain plan, o dba do Dev pack
  e mais completo para projetos Java/Spring Boot.
```

**Pedido cross-domain — Marcus sugere sequencia:**

```
claude> Use o marcus-agent: preciso criar um microsservico de notificacoes do zero,
        com testes, pipeline e observabilidade

Marcus responde:
→ Isso envolve 3 dominios. Sequencia recomendada:
  1. /dev-bootstrap notification-service     (estrutura + codigo)
  2. /qa-generate NotificationUseCase        (testes)
  3. /devops-provision notification-service   (infra + pipeline + observability)
```

**Pergunta sobre o ecossistema — Marcus responde diretamente:**

```
claude> Use o marcus-agent: quais agentes tenho para trabalhar com Kubernetes?

Marcus responde:
→ Dois agentes cobrem K8s:
  - `k8s-platform-agent` (standalone) — generico, qualquer stack
  - `kubernetes-engineer` (devops pack) — focado em Java/Spring Boot workloads
→ Para provisionar cluster + infra completa: /devops-provision
→ Para troubleshooting de pod/node: sessao dedicada com k8s-platform-agent
```

**Decisao arquitetural — Marcus delega para o especialista:**

```
claude> Use o marcus-agent: devo usar ECS Fargate ou EKS para 10 microsservicos?

Marcus responde:
→ Decisao de plataforma cloud — delego para o `aws-platform-agent`.
→ Use: "Use o aws-platform-agent para avaliar ECS Fargate vs EKS
  para 10 microsservicos com carga variavel e auto-scaling"
→ Para analise de custo complementar, consulte tambem o `finops-agent`.
```

**Incidente em producao — Marcus indica o caminho mais rapido:**

```
claude> Use o marcus-agent: o order-service esta com latencia de 5s, preciso resolver agora

Marcus responde:
→ Incidente ativo — use o slash command para resposta guiada:
  /devops-incident "latencia alta no order-service — p99 em 5s"
→ Ele orquestra SRE Engineer + Observability Engineer automaticamente.
→ Se preferir sessao direta: claude --agent incident-agent
```

### Dicas para usar o Agent-Marcus

**1. Seja especifico no pedido.** Quanto mais contexto voce der, melhor o roteamento.

```
# Vago — Marcus vai precisar perguntar
claude> Use o marcus-agent: tenho um problema de performance

# Especifico — Marcus roteia direto
claude> Use o marcus-agent: query de listagem de pedidos esta demorando 3s
        no PostgreSQL, tabela tem 2M de registros
```

**2. Use Marcus para descobrir commands.** Se voce esqueceu qual slash command existe para uma tarefa:

```
claude> Use o marcus-agent: quero fazer auditoria completa no meu projeto
→ Marcus: use /qa-audit (qualidade) e /devops-audit (infra) — juntos cobrem tudo
```

**3. Use Marcus para escolher entre standalone e pack.** Quando ambos cobrem o mesmo dominio:

```
claude> Use o marcus-agent: preciso configurar Terraform, mas meu projeto e Python/FastAPI
→ Marcus: use `terraform-infra-agent` (standalone, generico). O `iac-engineer` do
  pack DevOps assume contexto Java/Spring Boot + K8s.
```

**4. Nao use Marcus para tarefas que voce ja sabe rotear.** Se voce sabe que precisa do `dba`, va direto. Marcus e para quando voce nao sabe ou precisa de orientacao.

### Anti-patterns

| Nao faca | Faca |
|----------|------|
| Pedir ao Marcus para implementar codigo | Pedir ao Marcus para indicar qual agente implementa |
| Usar Marcus para cada interacao | Usar Marcus na primeira vez; depois va direto ao especialista |
| Perguntas genericas sem contexto | Dar contexto: stack, problema, objetivo |

---

## Guia de Uso por Cenario

### "Preciso implementar uma feature"

```
claude> /dev-feature "adicionar filtro por data no endpoint de pedidos"
```

O command orquestra: Architect (design) → API Designer (contrato) → DBA (schema) → Backend Dev (codigo) → Code Reviewer (revisao).

Depois de implementar:

```
claude> /qa-generate CreateOrderUseCase
```

Para features menores ou pontuais, va direto ao agente:

```
claude> Use o backend-dev para adicionar validacao de CPF no CreateCustomerUseCase
```

### "Preciso revisar codigo / PR"

```
# Review completo multi-perspectiva (codigo + arquitetura + banco)
claude> /dev-review src/main/java/com/example/order/

# Review focado apenas em codigo
claude> Use o code-reviewer para revisar OrderService.java

# Review focado em seguranca
claude> Use o security-test-engineer para auditar a API de autenticacao
```

### "Preciso criar um servico novo do zero"

```
claude> /dev-bootstrap order-service
claude> /devops-provision order-service aws
claude> /qa-audit
```

Tres commands, equipe completa: codigo + infra + qualidade.

Para um bootstrap mais simples (so estrutura + Dockerfile):

```
claude> Use o architect para definir a estrutura do notification-service
claude> Use o devops-engineer para criar Dockerfile e docker-compose
```

### "Preciso debugar um problema de infra"

```bash
# Sessao dedicada com o agente de K8s
claude --agent k8s-platform-agent

# Para incidentes ativos, o command guia o processo completo
claude> /devops-incident "latencia alta no order-service"

# Pod em CrashLoopBackOff — diagnostico rapido
claude> Use o kubernetes-engineer para diagnosticar: pod order-service-7b4f em CrashLoopBackOff

# Problema de rede entre servicos
claude> Use o service-mesh-engineer para investigar timeout entre order-service e payment-service
```

### "Preciso trabalhar com banco de dados"

```bash
# PostgreSQL — sessao dedicada para modelagem
claude --agent database-agent

# MySQL — otimizar query especifica
claude> Use o mysql-agent para otimizar esta query: SELECT ... FROM orders WHERE ...

# Modelar schema para novo contexto (projeto Java/Spring Boot)
claude> Use o dba para modelar o schema do contexto de Payments com migrations Flyway

# Criar migration com zero-downtime
claude> Use o dba para criar migration Flyway que adiciona coluna status na tabela orders sem downtime
```

### "Preciso configurar observabilidade"

```
# Setup completo (Prometheus + Grafana + Loki + alertas + tracing)
claude> /devops-observe order-service

# Apenas criar dashboard Grafana
claude> Use o observability-engineer para criar dashboard Grafana para o order-service

# Definir SLOs e alertas
claude> Use o observability-engineer para definir SLOs de latencia e disponibilidade para payment-service

# Standalone — contexto generico (nao Java)
claude --agent observability-agent
```

### "Preciso de seguranca"

```bash
# Auditoria de seguranca no codigo
claude> Use o security-agent para auditar as APIs do modulo de autenticacao

# Testes OWASP na API
claude> Use o security-test-engineer para testar OWASP Top 10 na API do order-service

# Hardening de cluster K8s
claude> Use o security-ops para criar checklist de hardening do cluster EKS

# Configurar Vault para secrets
claude> Use o security-ops para configurar HashiCorp Vault com injecao de secrets nos pods

# Sessao dedicada para auditoria profunda
claude --agent security-agent
```

### "Preciso migrar um modulo do monolito"

```
claude> /migration-discovery                    # Fase 0: analise completa
claude> /migration-prepare order                # Fase 2: criar seams
claude> /migration-extract order                # Fase 3: extrair microsservico
claude> /migration-decommission order           # Fase 5: remover do monolito
```

Para tarefas pontuais de migracao:

```
# Mapear dependencias de um modulo
claude> Use o domain-analyst para mapear dependencias do modulo Payment no monolito

# Decisao sobre estrategia de dados
claude> Use o data-engineer para projetar split de banco entre Order e Payment

# Validar que o microsservico tem paridade funcional
claude> Use o qa-engineer para criar testes de paridade entre monolito e order-service
```

### "Preciso analisar custos / otimizar infra"

```bash
# Sessao dedicada com o agente de FinOps
claude --agent finops-agent

# Auditoria completa (seguranca + custo + resiliencia)
claude> /devops-audit

# Analise pontual de custos
claude> Use o finops-agent para analisar o aumento de 40% na fatura AWS deste mes

# Decisao de plataforma com analise de custo
claude> Use o devops-lead para avaliar custo de EKS vs ECS Fargate para 10 servicos
```

### "Preciso de uma decisao arquitetural"

```
# Trade-off entre abordagens
claude> Use o architect para avaliar CQRS vs read model separado para o modulo de relatorios

# ADR formal
claude> Use o architect para criar ADR sobre a decisao de usar Redis como cache

# Decisao de infra/cloud
claude> Use o aws-platform-agent para avaliar ECS Fargate vs EKS para nosso contexto

# Quando nao sabe qual especialista consultar
claude> Use o marcus-agent para avaliar a melhor abordagem para processar 100k eventos/dia
```

### "Preciso trabalhar com testes"

```
# Gerar testes para uma classe
claude> /qa-generate CreateOrderUseCase

# Testes de contrato entre servicos
claude> /qa-contract order-service

# Testes E2E para um fluxo completo
claude> /qa-e2e "fluxo de criacao de pedido ate pagamento"

# Diagnosticar teste flaky
claude> /qa-flaky OrderServiceIntegrationTest

# Load test com Gatling
claude> /qa-performance order-service

# Auditoria completa de qualidade
claude> /qa-audit

# Sessao dedicada para TDD
claude --agent unit-test-engineer
```

### "Preciso configurar CI/CD"

```
# Pipeline completo com quality gates
claude> /devops-pipeline order-service

# GitOps com ArgoCD
claude> Use o gitops-agent para configurar ArgoCD com ApplicationSets para 5 servicos

# Otimizar pipeline lento
claude> Use o cicd-engineer para otimizar o pipeline — esta demorando 20 minutos

# Standalone — GitHub Actions generico (qualquer stack)
claude --agent ci-agent
```

---

## Quando Usar O Que

| Situacao | Melhor abordagem |
|----------|-----------------|
| Tarefa completa (feature, bootstrap, auditoria) | Slash command (`/dev-feature`, `/qa-audit`) |
| Pergunta pontual a um especialista | Invocacao direta (`Use o dba para...`) |
| Sessao longa de trabalho focado | Sessao dedicada (`claude --agent backend-dev`) |
| Nao sabe qual agente/command usar | `marcus-agent` (gateway que classifica e delega) |
| Decisao que cruza dominios | `marcus-agent` ou sequencia de commands |
| Incidente em producao | `/devops-incident` ou `claude --agent incident-agent` |

### Standalone vs Pack: Qual Escolher?

5 agentes standalone tem equivalente nos team packs. A regra e simples:

| Contexto do projeto | Use |
|---------------------|-----|
| Java/Spring Boot + K8s | Agentes do **pack** (mais especificos) |
| Python, Node, Go, infra pura | Agentes **standalone** (genericos) |
| Duvida? | Pergunte ao `marcus-agent` |

---

## Estrategias de Composicao

### Estrategia 1: Pipeline completo (novo servico)

O caminho mais completo para criar um servico do zero ate producao:

```
/dev-bootstrap order-service         # Estrutura hexagonal + Dockerfile
/dev-api orders                      # OpenAPI spec
/dev-feature "criar pedido"          # Primeiro use case
/qa-generate CreateOrderUseCase      # Testes unitarios + integracao
/qa-contract order-service           # Contract tests
/devops-provision order-service aws  # Terraform + K8s + CI/CD + observability
/devops-pipeline order-service       # Pipeline com quality gates
```

### Estrategia 2: Hardening pre-release

Antes de ir para producao, rode essa sequencia:

```
/dev-review src/                     # Code review completo
/qa-audit                            # Auditoria de qualidade (cobertura, piramide, gaps)
/qa-performance order-service        # Load test com baseline
/devops-audit                        # Seguranca + custo + resiliencia
```

### Estrategia 3: Investigacao de problema

Quando algo esta errado mas voce nao sabe onde:

```
# 1. Pergunte ao Marcus para classificar
claude> Use o marcus-agent: o order-service esta lento em producao, onde comeco?

# 2. Marcus pode sugerir:
#    - Se e infra: /devops-incident ou k8s-platform-agent
#    - Se e banco: database-agent ou dba
#    - Se e codigo: code-reviewer ou performance-engineer
#    - Se e rede: service-mesh-engineer

# 3. Siga a recomendacao e aprofunde com sessao dedicada se necessario
claude --agent database-agent
```

### Estrategia 4: Migracao progressiva de monolito

Workflow completo para cada bounded context extraido:

```
# Fase 0 — Discovery (uma vez)
/migration-discovery

# Fase 2-5 — Por contexto (repetir para cada)
/migration-prepare payment
/migration-extract payment
/qa-contract payment-service           # Validar contratos
/qa-e2e "fluxo order→payment"         # Validar integracao
/devops-provision payment-service aws  # Infra do novo servico
/migration-decommission payment       # Remover do monolito
```

### Estrategia 5: Day-to-day development

Fluxo diario tipico de desenvolvimento:

```
# Manha — implementar
/dev-feature "adicionar desconto por cupom"

# Depois de implementar — revisar
/dev-review src/main/java/com/example/discount/

# Gerar testes
/qa-generate DiscountCalculator

# Se o teste falhar intermitentemente
/qa-flaky DiscountCalculatorTest

# Fim do dia — garantir qualidade
/qa-audit
```

---

## Referencia Rapida: Todos os Commands

### Dev Team (`/dev-*`)

| Comando | O que faz |
|---------|-----------|
| `/dev-feature "descricao"` | Implementar feature completa: design → API → schema → codigo → review |
| `/dev-bootstrap nome` | Criar microsservico novo com estrutura hexagonal completa |
| `/dev-review caminho/` | Code review multi-perspectiva (codigo + arquitetura + banco) |
| `/dev-refactor Classe` | Refatoracao segura com preservacao de comportamento |
| `/dev-api recurso` | Projetar API REST completa com OpenAPI spec |

### QA Team (`/qa-*`)

| Comando | O que faz |
|---------|-----------|
| `/qa-audit` | Auditoria completa: cobertura, piramide, seguranca, score |
| `/qa-generate Classe` | Gerar testes unitarios + integracao para classe/pacote |
| `/qa-review Classe` | Revisar testes existentes, identificar gaps e anti-patterns |
| `/qa-performance servico` | Criar load/stress/soak tests com Gatling ou k6 |
| `/qa-flaky TestClass` | Diagnosticar e corrigir testes instaveis |
| `/qa-contract servico` | Criar/validar contract tests REST e Kafka |
| `/qa-e2e fluxo` | Criar testes E2E e smoke tests para fluxos completos |

### DevOps Team (`/devops-*`)

| Comando | O que faz |
|---------|-----------|
| `/devops-provision servico cloud` | Provisionar infra completa: IaC + K8s + CI/CD + observability |
| `/devops-pipeline servico` | Criar/otimizar pipeline CI/CD com quality gates |
| `/devops-observe servico` | Configurar Prometheus + Grafana + alertas + Loki + tracing |
| `/devops-incident "descricao"` | Guiar resposta a incidente + gerar postmortem |
| `/devops-audit` | Auditoria de infra: seguranca, custo, resiliencia, compliance |
| `/devops-dr servico` | Planejar e validar disaster recovery |

### Migration Team (`/migration-*`)

| Comando | O que faz |
|---------|-----------|
| `/migration-discovery` | Fase 0: analise completa do monolito (contexts, dados, seguranca) |
| `/migration-prepare contexto` | Fase 2: criar seams, interfaces, feature flags |
| `/migration-extract contexto` | Fase 3: extrair bounded context como microsservico |
| `/migration-decommission contexto` | Fase 5: remover modulo migrado do monolito |

---

## Referencia Rapida: Standalone Agents

Agentes genericos que funcionam em qualquer contexto, sem dependencia de team packs.

| Agente | Dominio | Autonomia |
|--------|---------|-----------|
| `marcus-agent` | Gateway orquestrador: classifica qualquer pedido e delega para o agente/command certo | Consultive |
| `mysql-agent` | MySQL: queries, performance, replicacao, backup | Consultive |
| `database-agent` | PostgreSQL: schema, migrations, tuning, vacuum | Consultive |
| `security-agent` | Seguranca: OWASP, IAM, CVE triage, audit | Advisory |
| `incident-agent` | Resposta a incidentes: IC methodology, comunicacao, postmortem | Semi-autonomous |
| `gitops-agent` | GitOps: ArgoCD, ApplicationSets, workflows | Semi-autonomous |
| `finops-agent` | FinOps: custos AWS, rightsizing, savings plans | Consultive |
| `aws-platform-agent` | AWS: ECS, EKS, Step Functions, EventBridge, IAM | Consultive |
| `k8s-platform-agent` | Kubernetes generico: workloads, HPA, networking, troubleshooting | Semi-autonomous |
| `observability-agent` | Observabilidade: Prometheus, Grafana, Loki, SLOs | Semi-autonomous |
| `ci-agent` | CI/CD: GitHub Actions, pipelines, caching, security scan | Semi-autonomous |
| `terraform-infra-agent` | Terraform: plan, apply, state, drift, modules | Semi-autonomous |
| `backend-java-agent` | Java/Spring Boot: arquitetura hexagonal, modular (7 dominios) | Modular |

---

## Fluxo Completo de Engenharia

Os tres packs principais formam um pipeline:

```
       DESENVOLVIMENTO              QUALIDADE                 ENTREGA
       ──────────────              ──────────                 ───────
  /dev-bootstrap ─────────> /qa-audit ──────────────> /devops-provision
  /dev-feature   ─────────> /qa-generate ───────────> /devops-pipeline
  /dev-review    ─────────> /qa-contract              /devops-observe
  /dev-refactor  ─────────> /qa-performance
  /dev-api       ─────────> /qa-e2e
```

O pack de **Migration** entra transversalmente quando o projeto envolve decomposicao de monolitos.

O **Agent-Marcus** fica acima de tudo como gateway — ele conhece o pipeline inteiro e sabe indicar por onde comecar.

---

## Dicas para Uso Eficiente

**1. Comece pelo command, nao pelo agente.**
Commands ja sabem quais agentes orquestrar e em qual ordem. Invocar agentes diretamente e para tarefas pontuais.

**2. Use o `marcus-agent` quando nao souber por onde comecar.**
Ele classifica o pedido e delega para o agente ou slash command certo. Nao use Marcus para tarefas que voce ja sabe rotear.

**3. Combine packs progressivamente.**
Nao precisa instalar tudo de uma vez. Comece com Dev, adicione QA quando tiver testes, adicione DevOps quando for deployar.

**4. Sessoes dedicadas para trabalho profundo.**
`claude --agent dba` para uma sessao inteira modelando schema. `claude --agent architect` para uma sessao de design. O agente mantem o contexto da conversa inteira.

**5. Standalone para contextos fora de Java/Spring Boot.**
Trabalhando com Python, Node, ou infra pura? Os standalone agents sao genericos e funcionam em qualquer stack. Os team packs assumem Java/Spring Boot.

**6. Apos implementar, rode o review.**
Habito eficiente: `/dev-feature` → `/dev-review` → `/qa-generate`. O code reviewer pega problemas que o implementador nao ve.

**7. Use `/qa-audit` e `/devops-audit` como checkpoints.**
Antes de releases, PRs grandes, ou marcos do projeto. Eles encontram gaps que passam despercebidos no dia-a-dia.

**8. Sessao dedicada para incidentes.**
`claude --agent incident-agent` mantem contexto do incidente inteiro — timeline, acoes tomadas, decisoes. Melhor que invocacoes isoladas.

**9. Pergunte ao Marcus sobre o ecossistema.**
"Quais agentes tenho para X?" — Marcus responde diretamente sem delegar. Util para descobrir capacidades que voce nao sabia que existiam.

**10. Um agente por vez para tarefas pontuais.**
Nao chame 3 agentes no mesmo prompt. Escolha o mais relevante, ou use um slash command que orquestra a sequencia certa.

---

## Documentacao por Pack

Cada team pack tem seu proprio README com instalacao detalhada, exemplos e estrutura de arquivos:

- [Dev Team](teams-agents-dev/README.md) — 7 agentes, 5 commands
- [QA Team](teams-agents-qa/README.md) — 8 agentes, 7 commands
- [DevOps Team](teams-agents-devops/README.md) — 8 agentes, 6 commands
- [Migration Team](teams-agents-monolith-migration/README.md) — 7 agentes, 4 commands
