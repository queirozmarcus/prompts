# Gemini Context: Marcus Agent Ecosystem v10

Este diretório contém a configuração e o "código-fonte" do **Marcus Agent Ecosystem**, uma plataforma de orquestração multi-agente para engenharia de software de alta performance, otimizada para o Gemini CLI.

## 🌍 Visão Geral do Ecossistema

O ecossistema é centrado no **Agent-Marcus**, um orquestrador carismático que gerencia 37 agentes especializados, 31 slash commands, 28 skills passivas e 12 playbooks operacionais.

*   **Público-alvo:** Desenvolvimento Backend Java/Spring Boot, QA, DevOps/SRE, Dados e Migração.
*   **Filosofia:** "Descreva o que precisa, Marcus delega".
*   **Arquitetura:** Isolamento de contexto, otimização de tokens e memória persistente (user/project).

## 📂 Estrutura do Projeto

*   **`/agents/`**: Definições dos 37 agentes especializados.
*   **`/commands/`**: Definições dos workflows multi-agente (slash commands) como `/dev-feature` e `/full-bootstrap`.
*   **`/skills/`**: Contexto passivo organizado por domínio (Java, AWS, K8s, etc.).
*   **`/playbooks/`**: Runbooks operacionais detalhados para incidentes, migrações e auditorias.
*   **`/checks/`**: Micro-checklists de validação.
*   **`install.sh`**: Script para instalação do ecossistema no diretório de configuração do usuário (`~/.gemini/`).

## 🛠️ Convenções de Desenvolvimento

### Idioma e Estilo
*   **Código e Estrutura Técnica:** Inglês (nomes de arquivos, campos YAML, variáveis).
*   **Documentação e Comentários:** Português (PT-BR) é o padrão para descrições de agentes, comandos, mensagens de commit e documentação de negócio.
*   **Personalidade do Marcus:** Carismático, prestativo, experiente e ocasionalmente bem-humorado.

### Padrões Técnicos Suportados (Target Codebase)
Os agentes são configurados para promover e implementar os seguintes padrões:
*   **Stack:** Java 21+ (Spring Boot 3.2+), PostgreSQL, Kafka, Redis, React, AWS/Kubernetes.
*   **Arquitetura:** Hexagonal (Ports & Adapters), Clean Architecture, Domain-Driven Design (DDD).
*   **Testes:** JUnit 5, Testcontainers, AssertJ, Pact (Consumer-Driven Contracts).
*   **Infra:** Terraform, Docker, Helm, GitHub Actions, ArgoCD (GitOps).

## 🚀 Guia de Operação para Gemini

Ao atuar neste diretório ou com este ecossistema, siga estas diretrizes:

1.  **Orquestração (Workflow do Marcus):**
    *   Siga as **5 Fases**: 1. Triagem + Brainstorm, 2. Plan, 3. Aprovação, 4. Execução, 5. Pós-execução.
    *   **Nunca implemente código diretamente** se a tarefa pertencer a um especialista; use a delegação para o agente correto.
    *   Para tarefas complexas, sempre proponha um plano estruturado e aguarde aprovação.

2.  **Uso de Agentes e Comandos:**
    *   Consulte `ANEXOIV-AGENT-CAPABILITIES.md` para entender qual agente é responsável por cada tarefa.
    *   Utilize os `commands/*.md` como templates para planejar execuções multi-step.

3.  **Skills e Contexto:**
    *   "Ative" as skills relevantes lendo os arquivos `skills/**/CLAUDE.md` (agora interpretados como contexto Gemini) quando trabalhar em um domínio específico.
    *   Respeite as restrições de ferramentas (Read-only vs Full Write) de cada perfil de agente.

## 📜 Code Style Preferences

### Java / Spring Boot (Stack Principal)
- **Version:** Java 8, 21 ou 25+ — detectar do `pom.xml`/`build.gradle` e adaptar features disponíveis
- **Default para projetos novos:** Java 21+ (LTS), Spring Boot 3.2+
- **Architecture:** Hexagonal (domain, application, adapter.in, adapter.out, config) — para Java 17+
- **Domain model:** Zero dependência de framework; regras de negócio na entidade
- **Naming:** camelCase para variáveis/métodos, PascalCase para classes, UPPER_SNAKE para constantes
- **Packages:** `com.{org}.{service}.{domain|application|adapter.in.web|adapter.out.persistence|config}`
- **DTOs:** `{Entity}Request`, `{Entity}Response` — records (21+) ou classes imutáveis (8)
- **Exceptions:** `{Entity}NotFoundException`, `{Rule}ViolationException` com código estável `{DOMAIN}-{NNN}`
- **Error handling:** Problem Details (RFC 9457) para toda API REST
- **API style:** `/api/v{n}/{resource}` (kebab-case, plural), OpenAPI/Swagger
- **Migrations:** Flyway `V{n}__{description}.sql` — nunca alterar migration aplicada
- **Kafka topics:** `{domain}.{entity}.{action}.v{n}`
- **Testing:** JUnit 5 + AssertJ + Mockito + Testcontainers; Given-When-Then; `{Class}Test`, `{Class}IntegrationTest`

### JavaScript / TypeScript
- **Indentation:** 2 spaces
- **Quotes:** Single quotes (`'`) for strings
- **Semicolons:** Required
- **Trailing commas:** Always in multi-line objects/arrays
- **Line length:** 80-100 chars target, 120 max
- **Naming:** camelCase for variables/functions, PascalCase for classes/components
- **Const over let/var:** Prefer `const` by default
- **Modern syntax:** async/await, destructuring, arrow functions

### Dockerfile
- **Base images:** Prefer slim/alpine variants (eclipse-temurin:21-jre-alpine para Java)
- **Multi-stage builds:** Always for Java (build com JDK, runtime com JRE)
- **Non-root user:** Obrigatório em produção
- **Comments:** Explain non-obvious RUN commands

### Terraform / IaC
- **Layout:** `infra/{cloud}/{environment}/{component}/`
- **Naming:** snake_case para resources, kebab-case para tags
- **Backend:** S3 + DynamoDB (AWS) ou GCS (GCP) — state isolado por ambiente
- **Modules:** Versionados, com variables tipadas e outputs documentados
- **Validation:** `terraform fmt -check && terraform validate && checkov -d .`

## 🔒 Security Practices

- **Never commit:** `.env`, API keys, tokens, passwords — always use env vars (gitignored)
- **Generate tokens:** `openssl rand -hex 24` (48 chars)
- **If secret exposed:** rotate immediately
- **Dependencies:** run `npm audit` / `./mvnw dependency-check:check` regularly; commit lockfiles
- **Review diff before staging:** look for accidental secrets
- **Never hardcode credentials** in config files or source code

## 🧪 Testing Approach

- **Test behavior, not implementation** — tests are documentation
- **Coverage targets:** 100% for security/auth paths; 80%+ for new features; 80%+ mutation score para domain
- **Naming:** `test('should return error when input is invalid')` (JS) / `shouldReturnError_whenInputInvalid()` (Java)
- **Pattern:** Arrange-Act-Assert (Given-When-Then); mock at boundaries only (ports out)
- **Testcontainers:** Obrigatório para testes de integração com banco, Kafka, Redis (Java) — nunca H2
- **Contract tests:** Pact ou Spring Cloud Contract para APIs entre serviços — falha bloqueia deploy

## 📝 Commit Message Format

Follow **Conventional Commits** — subject in PT-BR, body optional in PT-BR.

**Format:**
```
type(scope): descrição breve (máx 70 chars, imperativo, sem ponto final)

Explicação opcional do quê/por quê. Linhas de 72 caracteres.
- Use bullets para múltiplas mudanças
- Explique "por quê", não só "o quê"

Closes #issue_number (se aplicável)
```

**Types:** `feat` | `fix` | `docs` | `refactor` | `perf` | `test` | `chore` | `ci` | `style`

## 📜 Comandos de Instalação e Uso

```bash
# Instalar o ecossistema localmente
chmod +x install.sh
./install.sh

# Iniciar o orquestrador
# (Conceitual - Gemini CLI usa skills, mas seguimos o padrão do projeto)
gemini --agent marcus
```

---
*Este arquivo GEMINI.md serve como a "Constituição" para a operação do Gemini CLI neste ecossistema. Consulte-o sempre para manter a consistência com os padrões de Marcus.*
