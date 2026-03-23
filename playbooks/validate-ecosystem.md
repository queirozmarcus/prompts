# Playbook: Validacao Semantica do Ecossistema

**Quando usar:** Apos mudancas significativas no ecossistema (novo agent, novo command, atualizacao do Marcus, bump de versao) ou periodicamente para detectar drift.

**Pre-requisito:** Executar `~/.claude/validate-ecosystem.sh` primeiro para validacao estrutural. Este playbook cobre o que Bash nao consegue — analise semantica que requer LLM.

**Executor:** Humano, Marcus, ou agent dedicado (recomendado: code-reviewer ou architect).

---

## Categoria 1 — Coerencia Logica do Marcus

### 1.1 Workflow 5 fases e executavel

**O que validar:** Cada fase do workflow referencia tools que Marcus tem no frontmatter. Steps nao contradizem core rules. Transicoes entre fases sao claras.

**Como:**
1. Ler `~/.claude/agents/marcus.md` secao "Workflow — 5 Fases"
2. Listar todas as acoes que Marcus realiza em cada step
3. Verificar que cada acao e possivel com as tools declaradas no frontmatter
4. Verificar que nenhuma acao contradiz as "core rules"

**Resultado esperado:** Nenhuma acao requer tool ausente. Nenhuma contradição com core rules.

**Registro:** `[ ] PASS / WARN / FAIL` — Detalhar findings se houver.

---

### 1.2 Core rules nao contradizem workflow

**O que validar:** As regras em "Your core rules" sao respeitadas ao longo de todo o documento.

**Como:**
1. Listar cada core rule
2. Buscar no documento inteiro por acoes que violem cada regra
3. Exemplo classico: regra diz "nunca X" mas algum step faz X

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 1.3 Classificacao direto vs complexo e aplicavel

**O que validar:** A tabela de criterios na Fase 1 permite classificar de forma nao ambigua qualquer pedido razoavel.

**Como:** Testar com estes 5 pedidos e verificar se a classificacao e clara:
1. "otimize esta query SQL" → esperado: direto
2. "crie um microsservico de notificacoes" → esperado: complexo
3. "gere testes pro OrderService" → esperado: direto
4. "migre o modulo de pagamentos para microsservico" → esperado: complexo
5. "adicione cache Redis no order-service" → esperado: direto (com contexto da episodic memory)

**Registro:** `[ ] PASS / WARN / FAIL` — Anotar pedidos ambiguos.

---

### 1.4 Fallbacks cobrem falhas reais

**O que validar:** Cada ponto de falha no workflow tem tratamento documentado.

**Como:** Verificar se ha fallback para:
- [ ] Episodic memory indisponivel (plugin nao instalado)
- [ ] Agent delegado falha ou nao existe
- [ ] Plano nao aprovado pelo usuario
- [ ] Command referenciado nao existe
- [ ] Plugin referenciado nao instalado

**Registro:** `[ ] PASS / WARN / FAIL` — Listar fallbacks ausentes.

---

## Categoria 2 — Routing e Delegacao

### 2.1 Cobertura de dominios

**O que validar:** Todo dominio tecnico razoavel tem pelo menos um agent/command mapeado.

**Como:** Verificar cobertura para:
- [ ] Backend (Java/Spring Boot) → backend-dev, architect
- [ ] Frontend (se aplicavel) → skill frontend-design
- [ ] Banco de dados → dba, database-engineer, mysql-engineer
- [ ] Testes (unit, integration, e2e, contract, security, performance) → QA pack
- [ ] Infraestrutura (K8s, Terraform, CI/CD) → DevOps pack
- [ ] Seguranca → security-ops, security-test-engineer, security-engineer
- [ ] Migracao → Migration pack
- [ ] Observabilidade → observability-engineer
- [ ] Custo → finops-engineer

**Gaps conhecidos e aceitos:** Mobile, frontend frameworks (React/Vue/Angular), ML/AI, IoT. Marcus deve reconhecer estes gaps honestamente.

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 2.2 Cadeias de delegacao sao logicas

**O que validar:** A ordem dos agents nos commands faz sentido (design antes de implementacao, schema antes de codigo, etc).

**Como:** Para cada command com cadeia de delegacao no marcus.md:
1. Verificar se a ordem respeita dependencias naturais
2. Cruzar com o arquivo real do command em `~/.claude/commands/`
3. Confirmar que a cadeia no marcus.md bate com os Steps do command

**Commands a validar:**
- [ ] `/dev-feature`: architect → api-designer → dba → backend-dev → code-reviewer
- [ ] `/dev-bootstrap`: architect → backend-dev → dba → devops-engineer
- [ ] `/dev-review`: code-reviewer → architect → dba
- [ ] `/devops-provision`: iac-engineer → kubernetes-engineer → cicd-engineer → observability-engineer → security-ops
- [ ] `/migration-discovery`: domain-analyst → data-engineer → security-engineer → tech-lead
- [ ] `/migration-extract`: ALL migration agents

**Registro:** `[ ] PASS / WARN / FAIL` — Detalhar inversoes encontradas.

---

### 2.3 Sugestoes pos-execucao sao relevantes

**O que validar:** A tabela "Acabou de fazer → Sugere" no marcus.md propoe proximos passos que fazem sentido tecnico.

**Como:** Para cada entrada da tabela:
1. O command sugerido complementa o que foi executado?
2. A ordem faz sentido? (ex: testes depois de feature, review depois de testes)
3. O playbook sugerido e relevante para o contexto?

**Tabela a validar:**
- [ ] `/dev-feature` → `/qa-generate` → `/dev-review`
- [ ] `/dev-bootstrap` → `/qa-audit` → `/devops-provision`
- [ ] `/devops-provision` → `/devops-observe` → `/qa-security`
- [ ] `/migration-extract` → `/qa-contract` → `/devops-provision`
- [ ] `/devops-incident` → playbook `incident-response.md` → postmortem
- [ ] Qualquer deploy → playbook `k8s-deploy-safe.md`

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 2.4 Playbooks sugeridos no contexto certo

**O que validar:** A tabela de playbooks no marcus.md mapeia cenarios para os playbooks corretos.

**Como:** Para cada playbook:
1. O cenario de trigger e realista?
2. O playbook sugerido realmente cobre o cenario?
3. O playbook existe e tem conteudo util?

**Registro:** `[ ] PASS / WARN / FAIL`

---

## Categoria 3 — Consistencia Documental

### 3.1 CLAUDE.md global <-> marcus.md

**O que validar:** Mesmos numeros, mesmos nomes, mesmas listas de plugins/skills.

**Como:**
1. Comparar contagens (agents, commands, plugins, playbooks, skills)
2. Comparar listas de plugins e suas skills/commands
3. Comparar descricoes de packs (agents por pack, commands por pack)
4. Comparar tabela de modelo por perfil

**Registro:** `[ ] PASS / WARN / FAIL` — Listar divergencias.

---

### 3.2 marcus.md <-> agents/CLAUDE.md (repo)

**O que validar:** Contagens e totais alinhados entre o agent e o repo.

**Como:**
1. Comparar contagem de agents por pack
2. Comparar contagem de commands por pack
3. Verificar se a nota sobre commands fantasma esta atualizada

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 3.3 Agent descriptions <-> capabilities

**O que validar:** O que cada agent diz saber fazer e compativel com as tools que ele tem.

**Como:** Para cada agent, verificar:
1. Se diz "escrever codigo" → tem Write e Edit?
2. Se diz "executar comandos" → tem Bash?
3. Se diz "buscar na web" → tem WebFetch/WebSearch?
4. Se e read-only (advisory) → nao deveria ter Write/Edit
5. Se diz "criar arquivos" → tem Write?

**Amostra recomendada:** Validar pelo menos 1 agent por pack + Marcus.

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 3.4 Changelog reflete estado atual

**O que validar:** Ultimas entradas do changelog descrevem o estado real do ecossistema.

**Como:**
1. Ler ultima entrada do changelog em CLAUDE.md global
2. Verificar se claims numericos batem com realidade
3. Verificar se features mencionadas realmente existem

**Registro:** `[ ] PASS / WARN / FAIL`

---

## Categoria 4 — Testes de Cenario (dry-run)

Simular 5 pedidos e verificar se o Marcus rotearia corretamente. Para cada cenario: apresentar o input, descrever o resultado esperado, e comparar com o que o Marcus faria.

### 4.1 Tarefa direta simples

**Input:** "otimize esta query SELECT * FROM orders WHERE status = 'CREATED'"

**Resultado esperado:**
- Classifica como direta
- Roteia para `/data-optimize`
- Sugere `/qa-generate` como proximo passo

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 4.2 Tarefa complexa multi-dominio

**Input:** "crie um microsservico de notificacoes com testes e deploy"

**Resultado esperado:**
- Classifica como complexa
- Abre brainstorm com architect
- Gera plano com 4+ etapas cruzando Dev, QA e DevOps
- Pede aprovacao antes de executar

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 4.3 Pedido ambiguo

**Input:** "preciso melhorar a performance"

**Resultado esperado:**
- Pergunta UMA coisa antes de rotear (API? banco? infra?)
- NAO assume dominio
- NAO faz multiplas perguntas de uma vez

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 4.4 Pergunta sobre Claude Code

**Input:** "como instalo um plugin?"

**Resultado esperado:**
- Responde direto sem delegar a outro agent
- Mostra o comando exato: `/plugin install {name}@{marketplace}`
- Opcionalmente menciona `/plugin marketplace add` para descobrir plugins

**Registro:** `[ ] PASS / WARN / FAIL`

---

### 4.5 Dominio sem agent

**Input:** "crie um app React Native"

**Resultado esperado:**
- Reconhece que nao tem agent especializado para mobile
- Oferece ajuda direta ou sugere como configurar o ambiente
- NAO finge ter um agent que nao existe

**Registro:** `[ ] PASS / WARN / FAIL`

---

## Template de Relatorio

Apos executar todas as categorias, preencher:

```
══════════════════════════════════════════════════
  SEMANTIC VALIDATION REPORT
  Date: {YYYY-MM-DD}
  Validator: {nome do executor}
  Marcus version: {version do frontmatter}
══════════════════════════════════════════════════

  Category 1 — Coerencia Logica
  [ ] 1.1 Workflow executavel
  [ ] 1.2 Core rules consistentes
  [ ] 1.3 Classificacao aplicavel
  [ ] 1.4 Fallbacks cobrem falhas

  Category 2 — Routing e Delegacao
  [ ] 2.1 Cobertura de dominios
  [ ] 2.2 Cadeias logicas
  [ ] 2.3 Sugestoes pos-execucao
  [ ] 2.4 Playbooks contextuais

  Category 3 — Consistencia Documental
  [ ] 3.1 CLAUDE.md <-> marcus.md
  [ ] 3.2 marcus.md <-> agents/CLAUDE.md
  [ ] 3.3 Descriptions <-> capabilities
  [ ] 3.4 Changelog atual

  Category 4 — Testes de Cenario
  [ ] 4.1 Tarefa direta
  [ ] 4.2 Tarefa complexa
  [ ] 4.3 Pedido ambiguo
  [ ] 4.4 Pergunta Claude Code
  [ ] 4.5 Dominio sem agent

══════════════════════════════════════════════════
  RESULTS: {X} PASS · {Y} WARN · {Z} FAIL
══════════════════════════════════════════════════

  FINDINGS:
  - {finding 1}
  - {finding 2}

  ACTION ITEMS:
  - [ ] {acao corretiva 1}
  - [ ] {acao corretiva 2}
══════════════════════════════════════════════════
```
