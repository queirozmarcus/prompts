# Manual Focado no ZIP — Claude Home v6

## O que este manual é

Este manual foi reconstruído **com foco estrito no conteúdo real do ZIP `claude-home-v6`**. O objetivo aqui não é inventar um ecossistema novo, mas **explicar, organizar e operacionalizar o que realmente existe** no pacote enviado.

Sempre que eu falar de arquitetura, agentes, comandos, playbooks, skills, plugins ou fluxo de trabalho, a referência é o material presente nestes arquivos:

- `CLAUDE.md`
- `README.md`
- `MANUAL-CASOS-DE-USO.md`
- `install.sh`
- `agents/`
- `commands/`
- `playbooks/`
- `skills/`

---

# PARTE 1 — VISÃO DO SISTEMA REAL DO ZIP

## 1.1 Estrutura encontrada

A estrutura real do ZIP é esta:

```text
claude-home-v6/
├── CLAUDE.md
├── README.md
├── MANUAL-CASOS-DE-USO.md
├── install.sh
├── agents/
├── commands/
├── playbooks/
├── skills/
└── checks/
```

## 1.2 Contagem real do ecossistema

Com base no conteúdo do ZIP:

- **36 agents** em `agents/`
- **30 commands** em `commands/`
- **12 playbooks** em `playbooks/`
- **28 skills técnicas** em `skills/` + `skills/README.md`
- **1 script de instalação** em `install.sh`
- **1 manual operacional adicional** em `MANUAL-CASOS-DE-USO.md`

## 1.3 Modelo operacional identificado

O modelo do ZIP segue uma arquitetura de camadas:

1. **Marcus** é o ponto de entrada principal e orquestrador.
2. **Packs de agents** especializam o trabalho por domínio.
3. **Slash commands** encadeiam múltiplos agents em sequências previsíveis.
4. **Skills** funcionam como contexto passivo e padrão técnico reutilizável.
5. **Playbooks** funcionam como roteiros operacionais para cenários recorrentes.
6. **Checks** aparecem como apoio reutilizável para revisão e validação.
7. **Plugins e connectors** são citados em `CLAUDE.md` como extensões do ecossistema.

## 1.4 A ideia central do sistema

O ZIP não foi montado como uma simples coleção de prompts. Ele foi estruturado como um **ambiente operacional para Claude Code**, em que cada tipo de trabalho técnico cai em uma combinação previsível de:

- um **agent especialista**
- uma **skill de domínio**
- um **command orquestrador**, quando a tarefa tem várias etapas
- um **playbook**, quando o problema é operacional ou recorrente

## 1.5 Papel do `CLAUDE.md`

O `CLAUDE.md` global é o arquivo mais importante do sistema porque ele define:

- a visão do diretório `~/.claude/`
- o papel do `marcus-agent`
- a separação entre packs
- o estilo de comunicação
- regras de processo de desenvolvimento
- idioma esperado
- relação entre agents, skills, commands, checks, playbooks, plugins e connectors

## 1.6 Papel do `README.md`

O `README.md` atua como guia de operação do ecossistema. Ele mostra:

- como iniciar com `claude --agent marcus`
- como validar agents e skills
- como usar o sistema no dia a dia
- exemplos de uso de commands como `/full-bootstrap`, `/dev-feature`, `/data-optimize`, `/devops-incident`, `/dev-review`, `/migration-*`, `/qa-security`

## 1.7 Papel do `MANUAL-CASOS-DE-USO.md`

Esse arquivo já é, no próprio ZIP, uma camada prática acima do README. Ele organiza cenários reais do dia a dia, como:

- início da sessão
- desenvolvimento de features
- refatoração
- problemas de banco
- incidentes
- migração de monólito
- testes e segurança

Em outras palavras: **o ZIP já contém sua própria documentação operacional**, e este manual serve para consolidar e reorganizar isso com foco total no material real.

---

# PARTE 2 — INVENTÁRIO EXATO DOS AGENTS

## 2.1 Lista completa dos 36 agents

- `api-designer`
- `architect`
- `aws-cloud-engineer`
- `backend-dev`
- `backend-engineer`
- `cicd-engineer`
- `code-reviewer`
- `contract-test-engineer`
- `data-engineer`
- `database-engineer`
- `dba`
- `devops-engineer`
- `devops-lead`
- `domain-analyst`
- `e2e-test-engineer`
- `finops-engineer`
- `gitops-engineer`
- `iac-engineer`
- `integration-test-engineer`
- `kubernetes-engineer`
- `marcus-agent`
- `mysql-engineer`
- `observability-engineer`
- `performance-engineer`
- `platform-engineer`
- `qa-engineer`
- `qa-lead`
- `refactoring-engineer`
- `security-engineer`
- `security-ops`
- `security-test-engineer`
- `service-mesh-engineer`
- `sre-engineer`
- `tech-lead`
- `test-automation-engineer`
- `unit-test-engineer`

## 2.2 Como os agents estão organizados conceitualmente

Pelo `CLAUDE.md`, os agents estão agrupados em packs/domínios:

- **Marcus / Orquestração**
- **Dev**
- **QA**
- **DevOps**
- **Data**
- **Migration**

## 2.3 O padrão estrutural dos arquivos de agent

Os arquivos de agent seguem um padrão recorrente:

```yaml
---
name: ...
description: ...
tools: ...
model: inherit
color: ...
version: ...
---
```

Depois do front matter, o agent define:

- identidade técnica
- responsabilidades
- método de decisão
- padrões recomendados
- saídas esperadas
- checklists e princípios

## 2.4 Agents que definem arquitetura e decisão

### `architect`
Focado em:
- desenho de serviços
- trade-offs
- ADRs
- bounded contexts
- padrões distribuídos como SAGA, Outbox, CQRS e Event Sourcing

O `architect` é claramente um agente de **planejamento antes da implementação**.

### `tech-lead`
Age como coordenador em fluxos maiores, especialmente em migração e consolidação.

### `domain-analyst`
Ajuda a delimitar domínio, contexto e responsabilidades de negócio.

## 2.5 Agents de implementação

### `backend-dev`
É um dos agentes mais importantes do ZIP. O arquivo dele mostra que a implementação é orientada a:

- Java + Spring Boot
- arquitetura hexagonal
- domínio no centro
- adaptação conforme versão do Java detectada
- fluxo: domain → ports → use case → adapters → config → migration

### `backend-engineer`
Complementa a trilha backend e pode ser usado em cenários mais gerais.

### `api-designer`
Responsável pelo desenho da API e contrato.

### `refactoring-engineer`
Voltado para refatoração segura e incremental.

## 2.6 Agents de dados

### `dba`
Focado em análise de schema, índices, migrations, impacto e tuning.

### `database-engineer`
Trabalha em desenho e evolução do banco.

### `mysql-engineer`
Especialização explícita em MySQL.

### `data-engineer`
Completa a camada de dados quando a tarefa extrapola só o banco relacional.

## 2.7 Agents de QA

A cobertura de QA no ZIP é extensa. O sistema separa testes por responsabilidade:

- `qa-lead`
- `qa-engineer`
- `unit-test-engineer`
- `integration-test-engineer`
- `contract-test-engineer`
- `e2e-test-engineer`
- `performance-engineer`
- `security-test-engineer`
- `test-automation-engineer`

Isso mostra que o ZIP trata qualidade como **um conjunto de especialidades**, não como um agente único genérico.

## 2.8 Agents de DevOps / Plataforma / Operação

A trilha DevOps do ZIP é uma das mais fortes:

- `devops-engineer`
- `devops-lead`
- `aws-cloud-engineer`
- `iac-engineer`
- `kubernetes-engineer`
- `gitops-engineer`
- `cicd-engineer`
- `observability-engineer`
- `service-mesh-engineer`
- `security-ops`
- `sre-engineer`
- `platform-engineer`
- `finops-engineer`
- `security-engineer`

O padrão do ZIP deixa claro que DevOps aqui não é só pipeline: inclui cloud, infra, operação, custo, observabilidade, segurança e confiabilidade.

## 2.9 `marcus-agent`

O `marcus-agent` aparece como o **roteador global**. Pelo `CLAUDE.md`, ele:

- é o ponto de entrada principal
- conhece os comandos
- faz varredura inicial do projeto
- delega para especialistas
- mantém um estilo mais humano e natural em PT-BR
- não é o executor principal de todas as tarefas; ele é o orquestrador

---

# PARTE 3 — INVENTÁRIO EXATO DOS COMMANDS

## 3.1 Lista completa dos 30 commands

- `data-migrate`
- `data-optimize`
- `dev-api`
- `dev-bootstrap`
- `dev-feature`
- `dev-refactor`
- `dev-review`
- `devops-audit`
- `devops-cloud`
- `devops-dr`
- `devops-finops`
- `devops-gitops`
- `devops-incident`
- `devops-mesh`
- `devops-observe`
- `devops-pipeline`
- `devops-provision`
- `full-bootstrap`
- `migration-decommission`
- `migration-discovery`
- `migration-extract`
- `migration-prepare`
- `qa-audit`
- `qa-contract`
- `qa-e2e`
- `qa-flaky`
- `qa-generate`
- `qa-performance`
- `qa-review`
- `qa-security`

## 3.2 O padrão dos commands no ZIP

Os commands do ZIP não são simples aliases. Eles seguem um padrão de **orquestração por etapas**, normalmente com:

- título do cenário
- seção `## Instruções`
- steps numerados
- delegação explícita para agents especializados
- saída consolidada no final

## 3.3 Blocos funcionais dos commands

### Desenvolvimento
- `dev-api`
- `dev-bootstrap`
- `dev-feature`
- `dev-refactor`
- `dev-review`
- `full-bootstrap`

### Dados
- `data-migrate`
- `data-optimize`

### DevOps
- `devops-audit`
- `devops-cloud`
- `devops-dr`
- `devops-finops`
- `devops-gitops`
- `devops-incident`
- `devops-mesh`
- `devops-observe`
- `devops-pipeline`
- `devops-provision`

### QA
- `qa-audit`
- `qa-contract`
- `qa-e2e`
- `qa-flaky`
- `qa-generate`
- `qa-performance`
- `qa-review`
- `qa-security`

### Migração
- `migration-discovery`
- `migration-prepare`
- `migration-extract`
- `migration-decommission`

## 3.4 Commands mais estruturantes

### `dev-feature`
No ZIP, esse command é uma cadeia explícita de:

1. Design
2. API
3. Schema
4. Implementação
5. Code Review
6. Apresentação

Ele é a melhor evidência de como o sistema foi pensado: **planejar, desenhar, implementar, revisar**.

### `dev-bootstrap`
Cria a base de um serviço com:

- definição arquitetural
- estrutura do projeto
- schema inicial
- API base
- infraestrutura

### `full-bootstrap`
É a versão mais ampla, coordenando Dev + QA + DevOps. O ZIP o posiciona como um bootstrap end-to-end para serviço production-ready.

### `devops-provision`
É um dos comandos mais completos da trilha DevOps. Ele encadeia:

- IaC
- Kubernetes
- CI/CD
- observabilidade
- segurança
- consolidação final via `devops-lead`

### `devops-incident`
É o command mais operacional da trilha SRE/observabilidade. Ele cobre:

- diagnóstico
- análise de dados
- mitigação
- postmortem

### `migration-discovery`
Estrutura a fase zero da migração do monólito com entregáveis claros em `docs/migration/...`.

## 3.5 O que o manual deve assumir sobre commands

Como o seu refinamento pediu foco máximo no ZIP, a forma correta de usar este manual é:

- tratar estes 30 commands como a **base oficial**
- não misturar com comandos inventados fora do pacote
- usar exemplos novos apenas quando eles **encaixarem nos commands existentes**

---

# PARTE 4 — INVENTÁRIO EXATO DOS PLAYBOOKS

## 4.1 Lista completa dos 12 playbooks

- `cost-optimization`
- `database-migration`
- `dependency-update`
- `dr-drill`
- `dr-restore`
- `incident-response`
- `k8s-deploy-safe`
- `network-troubleshooting`
- `rollback-strategy`
- `secret-rotation`
- `security-audit`
- `terraform-plan-apply`

## 4.2 O papel dos playbooks no ZIP

Os playbooks do ZIP cobrem situações operacionais repetíveis. Em vez de focar em geração de código, eles focam em **execução segura e previsível**.

## 4.3 Playbooks mais críticos

### `incident-response`
Apoia incidentes, mitigação, diagnóstico e pós-incidente.

### `k8s-deploy-safe`
Mostra que o ecossistema valoriza deploy seguro em Kubernetes, não apenas manifestação YAML.

### `terraform-plan-apply`
Formaliza o ciclo de plan/apply com segurança e revisão.

### `rollback-strategy`
Indica que rollback é tratado como processo deliberado, não improvisado.

### `database-migration`
Reflete a mesma preocupação de segurança e impacto vista nos commands de dados.

### `network-troubleshooting`
Reforça o eixo operacional para problemas de tráfego, DNS, rede e conectividade.

### `secret-rotation`
Mostra preocupação explícita com o ciclo de vida de segredos.

### `cost-optimization`
Conecta a camada FinOps com operação prática.

---

# PARTE 5 — INVENTÁRIO EXATO DAS SKILLS

## 5.1 Lista completa das 28 skills técnicas

- `application-development/api-design`
- `application-development/frontend`
- `application-development/java`
- `application-development/nodejs`
- `application-development/python`
- `application-development/testing`
- `cloud-infrastructure/argocd`
- `cloud-infrastructure/aws`
- `cloud-infrastructure/database`
- `cloud-infrastructure/istio`
- `cloud-infrastructure/kubernetes`
- `cloud-infrastructure/mysql`
- `cloud-infrastructure/terraform`
- `containers-docker/docker`
- `containers-docker/docker-ci`
- `containers-docker/docker-security`
- `devops-cicd/ci-cd`
- `devops-cicd/git`
- `devops-cicd/github-actions`
- `devops-cicd/release-management`
- `devops-cicd/workflows`
- `operations-monitoring/finops`
- `operations-monitoring/incidents`
- `operations-monitoring/monitoring-as-code`
- `operations-monitoring/networking`
- `operations-monitoring/observability`
- `operations-monitoring/secrets-management`
- `operations-monitoring/security`

## 5.2 Como as skills funcionam

Pelo `CLAUDE.md` e `skills/README.md`, as skills são **contexto passivo**. Elas não são, por padrão, o comando principal que você chama; elas enriquecem a execução de agents e commands.

## 5.3 Macrogrupos de skills

### Application Development
- `application-development/api-design`
- `application-development/frontend`
- `application-development/java`
- `application-development/nodejs`
- `application-development/python`
- `application-development/testing`

### Cloud Infrastructure
- `cloud-infrastructure/aws`
- `cloud-infrastructure/database`
- `cloud-infrastructure/mysql`
- `cloud-infrastructure/kubernetes`
- `cloud-infrastructure/terraform`
- `cloud-infrastructure/argocd`
- `cloud-infrastructure/istio`

### Containers & Docker
- `containers-docker/docker`
- `containers-docker/docker-ci`
- `containers-docker/docker-security`

### DevOps & CI/CD
- `devops-cicd/git`
- `devops-cicd/github-actions`
- `devops-cicd/ci-cd`
- `devops-cicd/release-management`
- `devops-cicd/workflows`

### Operations & Monitoring
- `operations-monitoring/security`
- `operations-monitoring/secrets-management`
- `operations-monitoring/observability`
- `operations-monitoring/networking`
- `operations-monitoring/incidents`
- `operations-monitoring/finops`
- `operations-monitoring/monitoring-as-code`

## 5.4 Skills mais aderentes ao seu foco backend + DevOps

Para o teu cenário, as skills mais centrais dentro do ZIP são:

- `application-development/java`
- `application-development/api-design`
- `application-development/testing`
- `cloud-infrastructure/aws`
- `cloud-infrastructure/kubernetes`
- `cloud-infrastructure/terraform`
- `devops-cicd/github-actions`
- `devops-cicd/ci-cd`
- `operations-monitoring/observability`
- `operations-monitoring/incidents`
- `operations-monitoring/security`
- `operations-monitoring/secrets-management`
- `operations-monitoring/finops`

## 5.5 Exemplo concreto: skill de Kubernetes

A skill `cloud-infrastructure/kubernetes` é densa e operacional. Ela cobre, entre outros pontos:

- manifesto declarativo como fonte de verdade
- requests e limits obrigatórios
- liveness e readiness probes
- RBAC mínimo
- graceful shutdown
- separação por namespaces
- padrões para Deployments, StatefulSets, Services e Ingress
- segurança com ServiceAccount, IRSA e NetworkPolicy

Isso mostra que o ecossistema não trata K8s só no nível superficial; existe base suficiente no ZIP para orientar deploy, operação e troubleshooting.

## 5.6 Exemplo concreto: skill de Terraform

A skill `cloud-infrastructure/terraform` reforça a camada IaC do sistema e deve ser lida em conjunto com:

- `devops-provision`
- `terraform-plan-apply`
- `iac-engineer`

Na prática, a skill define padrões; o command organiza a execução; o playbook orienta a operação segura.

---

# PARTE 6 — COMO AS PEÇAS DO ZIP SE CONECTAM

## 6.1 Fluxo canônico encontrado

O fluxo mais típico no ZIP é este:

```text
pedido do usuário
→ Marcus classifica
→ command organiza a sequência
→ agents especializados executam
→ skills enriquecem o julgamento técnico
→ playbook apoia se for um cenário operacional recorrente
→ saída consolidada
```

## 6.2 Exemplo: nova feature backend

Fluxo real baseado no ZIP:

```text
/dev-feature
→ architect
→ api-designer
→ dba
→ backend-dev
→ code-reviewer
```

## 6.3 Exemplo: incidente de produção

Fluxo real baseado no ZIP:

```text
/devops-incident
→ sre-engineer
→ observability-engineer
→ sre-engineer
→ postmortem
```

## 6.4 Exemplo: provisionamento de infra

Fluxo real baseado no ZIP:

```text
/devops-provision
→ iac-engineer
→ kubernetes-engineer
→ cicd-engineer
→ observability-engineer
→ security-ops
→ devops-lead
```

## 6.5 Exemplo: migração de monólito

Fluxo real baseado no ZIP:

```text
/migration-discovery
→ /migration-prepare
→ /migration-extract
→ /migration-decommission
```

Com suporte de vários agents e entregáveis em `docs/migration/...`.

---

# PARTE 7 — COMO LER O ZIP COM FOCO OPERACIONAL

## 7.1 Ordem recomendada de leitura

Se a meta é absorver tudo do ZIP sem se perder, a melhor ordem é:

1. `CLAUDE.md`
2. `README.md`
3. `MANUAL-CASOS-DE-USO.md`
4. `commands/`
5. `agents/`
6. `skills/README.md`
7. `skills/` mais aderentes ao seu trabalho
8. `playbooks/`
9. `install.sh`

## 7.2 O que estudar primeiro no seu caso

Como seu foco é backend, microserviços, DevOps, K8s e Terraform, a trilha prioritária dentro do ZIP deveria ser:

### Núcleo de desenvolvimento
- `agents/architect.md`
- `agents/backend-dev.md`
- `agents/api-designer.md`
- `commands/dev-feature.md`
- `commands/dev-bootstrap.md`
- `commands/full-bootstrap.md`

### Núcleo de QA
- `commands/qa-audit.md`
- `commands/qa-generate.md`
- `commands/qa-contract.md`
- `skills/application-development/testing/CLAUDE.md`

### Núcleo DevOps
- `agents/iac-engineer.md`
- `agents/kubernetes-engineer.md`
- `agents/observability-engineer.md`
- `agents/sre-engineer.md`
- `agents/security-ops.md`
- `commands/devops-provision.md`
- `commands/devops-incident.md`
- `commands/devops-observe.md`
- `playbooks/k8s-deploy-safe.md`
- `playbooks/terraform-plan-apply.md`
- `skills/cloud-infrastructure/kubernetes/CLAUDE.md`
- `skills/cloud-infrastructure/terraform/CLAUDE.md`
- `skills/operations-monitoring/observability/CLAUDE.md`
- `skills/operations-monitoring/incidents/CLAUDE.md`

---

# PARTE 8 — CASOS DE USO REAIS SUPORTADOS PELO ZIP

## 8.1 Criar um microsserviço

O ZIP suporta isso principalmente via:

- `full-bootstrap`
- `dev-bootstrap`
- `dev-api`
- skills de Java, API, testing, AWS, Kubernetes, Terraform, CI/CD

## 8.2 Implementar uma feature backend

O caminho mais fiel ao ZIP é:

```text
/dev-feature
+ /qa-generate
+ /dev-review
```

## 8.3 Revisar qualidade de um projeto

O ZIP já prevê isso com:

- `qa-audit`
- `dev-review`
- `devops-audit`
- `qa-review`

## 8.4 Resolver problema de banco

O caminho real do ZIP é:

- `data-optimize`
- `data-migrate`
- apoio de `dba`, `database-engineer`, `mysql-engineer`

## 8.5 Preparar e operar infra

O caminho real do ZIP é:

- `devops-provision`
- `devops-pipeline`
- `devops-gitops`
- `devops-observe`
- `terraform-plan-apply`
- `k8s-deploy-safe`

## 8.6 Responder a incidentes

O ZIP já traz a base operacional com:

- `devops-incident`
- `incident-response`
- `rollback-strategy`
- `network-troubleshooting`

## 8.7 Migrar monólito para microsserviços

O ZIP trata isso como uma trilha estruturada, não como um prompt solto:

- `migration-discovery`
- `migration-prepare`
- `migration-extract`
- `migration-decommission`

---

# PARTE 9 — LIMITES DO QUE EXISTE NO ZIP

## 9.1 O que está claramente presente

Está claramente presente no pacote:

- ecossistema de agents especializados
- commands multi-step
- playbooks operacionais
- skills passivas densas
- foco forte em Java/Spring Boot, QA, AWS, K8s, Terraform, CI/CD, incidentes, observabilidade, segurança e migração

## 9.2 O que não deve ser confundido com base oficial

Se o objetivo é fidelidade ao ZIP, então não devemos tratar como nativo do pacote coisas como:

- comandos com nomes que não existem em `commands/`
- agents inventados fora de `agents/`
- workflows que não encaixam na estrutura real dos packs

Ou seja: **o ZIP já tem linguagem própria, nomes próprios e fluxos próprios**. O manual refinado deve respeitar isso.

---

# PARTE 10 — LEITURA EXECUTIVA FINAL

## 10.1 O que o ZIP realmente representa

O `claude-home-v6` representa um **sistema operacional pessoal de engenharia assistida por IA** para Claude Code, organizado por especialidade técnica e por fluxo de trabalho.

Ele não é só um conjunto de prompts. Ele é composto por:

- **governança** em `CLAUDE.md`
- **operação guiada** em `README.md` e `MANUAL-CASOS-DE-USO.md`
- **especialização** em `agents/`
- **orquestração** em `commands/`
- **procedimentos repetíveis** em `playbooks/`
- **conhecimento passivo** em `skills/`

## 10.2 Onde está a maior força do material

A maior força do ZIP está em três coisas:

1. **orquestração disciplinada**
2. **especialização clara por papel técnico**
3. **forte cobertura de backend + QA + DevOps + operação**

## 10.3 Como usar este manual daqui pra frente

Se a tua prioridade é manter tudo fiel ao ZIP, o uso ideal deste manual é:

- consultar a arquitetura geral
- localizar o command correto
- identificar os agents realmente envolvidos
- aprofundar nas skills correspondentes
- usar playbooks quando o cenário for operacional

## 10.4 Resumo em uma frase

O ZIP é um ecossistema técnico maduro para Claude Code, com Marcus como orquestrador e uma base consistente de agents, commands, skills e playbooks voltados para engenharia backend, qualidade, cloud, Kubernetes, Terraform, operação e migração.
