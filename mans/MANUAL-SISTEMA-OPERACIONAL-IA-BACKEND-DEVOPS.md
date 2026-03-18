# SISTEMA OPERACIONAL PESSOAL COM IA
## Para Backend, Microserviços, DevOps, Kubernetes e Terraform

**Versão 2.0 — Evolução do Claude Home v6**

> Manual massivo, denso e operacional. Baseado em sistema real de 36 agentes, 30 comandos, 28 skills e 12 playbooks — expandido, melhorado e generalizado para produção.

---

# PARTE 1 — VISÃO DO SISTEMA

## 1.1 Arquitetura Original

O sistema é um **ecossistema multi-agent** operado via terminal (Claude Code CLI), onde um orquestrador central (`Agent-Marcus`) classifica qualquer requisição e delega para agentes especializados organizados em 5 times (packs).

```
┌─────────────────────────────────────────────────────────────────┐
│                      CAMADA DE ORQUESTRAÇÃO                      │
│              Agent-Marcus (gateway + routing + personality)       │
├─────────────────────────────────────────────────────────────────┤
│                      CAMADA DE COMANDOS                          │
│  30 slash commands que orquestram múltiplos agents em sequência   │
├──────────┬──────────┬───────────┬────────┬──────────────────────┤
│ Dev (6)  │ QA (8)   │ DevOps(11)│Data (3)│ Migration (7)        │
│ 6 cmds   │ 8 cmds   │ 11 cmds   │ 2 cmds │ 4 cmds              │
├──────────┴──────────┴───────────┴────────┴──────────────────────┤
│                      CAMADA DE SKILLS (passivas)                 │
│  28 skills por contexto: cloud, docker, dev, cicd, operations    │
├─────────────────────────────────────────────────────────────────┤
│                      CAMADA DE PLAYBOOKS                         │
│  12 guias operacionais passo-a-passo para operações críticas     │
├─────────────────────────────────────────────────────────────────┤
│                      CAMADA DE PLUGINS                           │
│  superpowers, playwright, qodo-skills, frontend-design, etc.     │
├─────────────────────────────────────────────────────────────────┤
│                      CAMADA DE CONNECTORS (MCP)                  │
│  Slack, GitHub, Jira, Google Drive, Figma, 50+ integrações       │
└─────────────────────────────────────────────────────────────────┘
```

### Como o Sistema Funciona

O fluxo completo opera em 4 níveis:

```
NÍVEL 1: ENTRADA
  Usuário descreve problema em linguagem natural
  OU executa slash command diretamente
       │
NÍVEL 2: ROTEAMENTO (Marcus)
  Marcus classifica: qual pack? qual command? qual agent?
  Regra: slash command > agent direto > plugin
       │
NÍVEL 3: ORQUESTRAÇÃO (Command)
  O slash command orquestra N agents em sequência
  Cada agent recebe context window isolado (fork)
  Skills passivas enriquecem o contexto automaticamente
       │
NÍVEL 4: EXECUÇÃO (Agent)
  Agent especialista executa com tools próprias
  Gera output (código, config, análise, plan)
  Resultado volta ao command que consolida
```

### Conceitos Fundamentais

**Agent** — Especialista com identidade, ferramentas e context window próprio. Definido como `.md` com YAML frontmatter. Exemplos: `backend-dev`, `kubernetes-engineer`, `sre-engineer`. Total: 36 agents.

**Skill** — Boas práticas passivas carregadas automaticamente por contexto de domínio. Quando Claude trabalha com Terraform, a skill `cloud-infrastructure/terraform` é lida automaticamente. Não são invocadas — são contextuais. Total: 28 skills em 5 categorias.

**Command** — Slash command que orquestra múltiplos agents em sequência definida. `/dev-feature` orquestra `architect → api-designer → dba → backend-dev → code-reviewer`. Total: 30 commands.

**Playbook** — Guia operacional passo-a-passo para operações críticas. Referenciado manualmente ou sugerido pelo Marcus. Inclui comandos bash reais, checklists e planos de rollback. Total: 12 playbooks.

**Plugin** — Extensão que adiciona skills, agents e commands. `superpowers` adiciona `/brainstorm`, `/write-plan`, `/execute-plan` + skills de TDD e debugging.

**Pack** — Agrupamento lógico de agents + commands por domínio: Dev, QA, DevOps, Data, Migration.

**Connector (MCP)** — Integração com ferramentas externas via Model Context Protocol: Slack, GitHub, Jira, Figma, etc.

### Sinergia entre Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    COMO COEXISTEM                             │
├─────────────────────────────────────────────────────────────┤
│ Skill dá contexto passivo → Agent executa com identidade     │
│ Plugin skill complementa skill local → sem conflito          │
│ Agent consulta skill para adaptar-se (ex: detectar Java 8)   │
│ Check é referenciado por agent ou playbook durante revisão   │
│ Command orquestra múltiplos agents em sequência              │
│ Playbook referencia commands, agents, skills e checks        │
│ Marcus conhece TUDO e roteia para o componente certo         │
└─────────────────────────────────────────────────────────────┘
```

## 1.2 Estrutura de Diretórios

```
~/.claude/
├── CLAUDE.md                       # Instruções globais (estilo, processo, convenções)
├── agents/                         # 36 agents (flat — cada .md é um agent)
│   ├── marcus-agent.md             # Orquestrador global
│   ├── architect.md                # Dev pack — design e ADRs
│   ├── backend-dev.md              # Dev pack — Java/Spring Boot
│   ├── api-designer.md             # Dev pack — OpenAPI/REST
│   ├── code-reviewer.md            # Dev pack — qualidade e segurança
│   ├── refactoring-engineer.md     # Dev pack — refatoração segura
│   ├── devops-engineer.md          # Dev pack — Docker/Helm/CI
│   ├── qa-lead.md                  # QA pack — estratégia de testes
│   ├── unit-test-engineer.md       # QA pack — JUnit/Mockito/TDD
│   ├── integration-test-engineer.md # QA pack — Testcontainers
│   ├── contract-test-engineer.md   # QA pack — Pact/Spring Cloud Contract
│   ├── performance-engineer.md     # QA pack — Gatling/k6
│   ├── e2e-test-engineer.md        # QA pack — RestAssured/Playwright
│   ├── test-automation-engineer.md # QA pack — geração/flaky detection
│   ├── security-test-engineer.md   # QA pack — OWASP/fuzzing
│   ├── devops-lead.md              # DevOps pack — estratégia de plataforma
│   ├── iac-engineer.md             # DevOps pack — Terraform/OpenTofu
│   ├── cicd-engineer.md            # DevOps pack — GitHub Actions/ArgoCD
│   ├── kubernetes-engineer.md      # DevOps pack — workloads/autoscaling
│   ├── observability-engineer.md   # DevOps pack — Prometheus/Grafana/Loki
│   ├── security-ops.md             # DevOps pack — Vault/RBAC/NetworkPolicy
│   ├── service-mesh-engineer.md    # DevOps pack — Istio/Linkerd
│   ├── sre-engineer.md             # DevOps pack — incidentes/postmortem/DR
│   ├── aws-cloud-engineer.md       # DevOps pack — EKS/RDS/IAM/VPC
│   ├── finops-engineer.md          # DevOps pack — custos/rightsizing
│   ├── gitops-engineer.md          # DevOps pack — ArgoCD/FluxCD
│   ├── dba.md                      # Data pack — schema/Flyway/JPA
│   ├── database-engineer.md        # Data pack — PostgreSQL/Aurora
│   ├── mysql-engineer.md           # Data pack — MySQL 8.x/MariaDB
│   ├── tech-lead.md                # Migration pack — coordenação
│   ├── domain-analyst.md           # Migration pack — bounded contexts
│   ├── backend-engineer.md         # Migration pack — seams/extração
│   ├── data-engineer.md            # Migration pack — CDC/dual-write
│   ├── platform-engineer.md        # Migration pack — routing/canary
│   ├── qa-engineer.md              # Migration pack — testes de paridade
│   └── security-engineer.md        # Migration pack — auth distribuída
├── commands/                       # 30 slash commands (flat)
│   ├── dev-feature.md              # Implementar feature completa
│   ├── dev-bootstrap.md            # Bootstrap de microsserviço
│   ├── full-bootstrap.md           # Bootstrap completo (3 packs)
│   ├── dev-review.md               # Code review multi-perspectiva
│   ├── dev-refactor.md             # Refatoração segura
│   ├── dev-api.md                  # Design de API/OpenAPI
│   ├── qa-audit.md                 # Auditoria de qualidade
│   ├── qa-generate.md              # Gerar testes
│   ├── qa-review.md                # Review de testes existentes
│   ├── qa-performance.md           # Load/stress test
│   ├── qa-flaky.md                 # Diagnosticar flaky tests
│   ├── qa-contract.md              # Testes de contrato
│   ├── qa-security.md              # Testes OWASP
│   ├── qa-e2e.md                   # Testes end-to-end
│   ├── devops-provision.md         # Provisionar infra completa
│   ├── devops-pipeline.md          # CI/CD pipeline
│   ├── devops-observe.md           # Observabilidade
│   ├── devops-incident.md          # Gestão de incidentes
│   ├── devops-audit.md             # Auditoria de infra
│   ├── devops-dr.md                # Disaster recovery
│   ├── devops-finops.md            # Otimização de custos
│   ├── devops-gitops.md            # ArgoCD/GitOps
│   ├── devops-cloud.md             # Arquitetura AWS
│   ├── devops-mesh.md              # Service mesh
│   ├── data-optimize.md            # Query/índice optimization
│   ├── data-migrate.md             # Migrations SQL
│   ├── migration-discovery.md      # Mapear monólito
│   ├── migration-prepare.md        # Preparar decomposição
│   ├── migration-extract.md        # Extrair microsserviço
│   └── migration-decommission.md   # Desativar legado
├── skills/                         # 28 skills passivas (por categoria)
│   ├── application-development/    # java, nodejs, python, frontend, api-design, testing
│   ├── cloud-infrastructure/       # aws, kubernetes, terraform, argocd, istio, database, mysql
│   ├── containers-docker/          # docker, docker-ci, docker-security
│   ├── devops-cicd/                # ci-cd, git, github-actions, release-management, workflows
│   ├── operations-monitoring/      # finops, incidents, monitoring-as-code, networking,
│   │                               # observability, secrets-management, security
│   └── skill-helper.sh             # CLI de gerenciamento
├── playbooks/                      # 12 playbooks operacionais
│   ├── incident-response.md        # Outage, latência, serviço fora do ar
│   ├── rollback-strategy.md        # Deploy com problemas
│   ├── database-migration.md       # Schema change zero-downtime
│   ├── secret-rotation.md          # Rotação de credenciais
│   ├── security-audit.md           # Auditoria pré-release
│   ├── terraform-plan-apply.md     # Terraform seguro em produção
│   ├── k8s-deploy-safe.md          # Deploy seguro em K8s
│   ├── cost-optimization.md        # Reduzir custos cloud
│   ├── dr-drill.md                 # Simular DR
│   ├── dr-restore.md               # Restore real de DR
│   ├── dependency-update.md        # Atualizar deps com segurança
│   └── network-troubleshooting.md  # Debug de rede/DNS/VPC
├── checks/                         # Micro-checklists reutilizáveis
└── plugins/                        # Plugins instalados
```

---

# PARTE 2 — SISTEMA DE AGENTES (EXPANDIDO)

## 2.1 Visão Geral dos 5 Packs

### Mapa de Cobertura

```
┌──────────────────────────────────────────────────────────────────┐
│                        CICLO DE VIDA COMPLETO                     │
├──────────┬──────────┬───────────┬────────┬───────────────────────┤
│  DESIGN  │  BUILD   │   TEST    │ DEPLOY │     OPERATE           │
│          │          │           │        │                       │
│architect │backend-  │qa-lead    │cicd-   │sre-engineer           │
│api-      │  dev     │unit-test  │  engr  │observability-engr     │
│designer  │dba       │integr-    │k8s-    │security-ops           │
│          │refact-   │  test     │  engr  │finops-engineer        │
│          │  engr    │contract-  │iac-    │aws-cloud-engr         │
│          │code-     │  test     │  engr  │service-mesh-engr      │
│          │  reviewer│perf-engr  │gitops- │devops-lead            │
│          │devops-   │e2e-test   │  engr  │                       │
│          │  engr    │sec-test   │sec-ops │                       │
│          │          │test-auto  │        │                       │
└──────────┴──────────┴───────────┴────────┴───────────────────────┘
```

## 2.2 Dev Pack (6 agents)

### 2.2.1 architect

**Função:** Arquiteto de software responsável por decisões estruturais. Avalia trade-offs, define limites de módulos e bounded contexts, gera ADRs.

**Quando usar:**
- Projetar arquitetura de novos serviços
- Avaliar trade-offs (sync vs async, cache vs DB, SAGA vs Outbox)
- Gerar Architecture Decision Records (ADRs)
- Revisar design existente e propor evolução

**Input:** Descrição do problema/requisito/decisão
**Output:** Design com trade-offs, ADR documentado, diagrama de componentes

**Exemplo REAL:**
```
Input: "Precisamos decidir como o order-service vai comunicar com payment-service"

Output do architect:
  CONTEXTO: Order precisa confirmar pagamento antes de mudar status
  RESTRIÇÕES: Latência < 500ms, tolerância a falha do payment-service

  OPÇÃO A — Síncrono (REST)
    Prós: Simples, resposta imediata, fácil debugar
    Contras: Acoplamento temporal, order falha se payment fora
    Custo: Baixo setup, alto acoplamento

  OPÇÃO B — Assíncrono (Kafka + SAGA)
    Prós: Desacoplado, resiliente, escalável
    Contras: Complexidade, eventual consistency, mais infra
    Custo: Médio setup, baixo acoplamento

  RECOMENDAÇÃO: Opção B com Outbox Pattern
  ADR-003 gerado em docs/architecture/adr/
```

### 2.2.2 backend-dev

**Função:** Engenheiro backend sênior Java 21+/Spring Boot 3.x. Implementa features completas seguindo arquitetura hexagonal.

**Quando usar:**
- Implementar domain model (entidades, VOs, aggregates)
- Criar use cases com regras de negócio
- Implementar controllers REST, Kafka consumers/producers
- Padrões: Outbox, idempotência, circuit breaker

**Input:** Design aprovado pelo architect + schema do DBA
**Output:** Código completo: domain → application → adapter (hexagonal)

**Detecção automática:** Verifica `<java.version>` no `pom.xml` e adapta (Java 8 sem records, Java 21+ com virtual threads).

**Exemplo REAL:**
```java
// Output do backend-dev para CreateOrderUseCase

// domain/model/Order.java — ZERO frameworks
public class Order {
    private OrderId id;
    private CustomerId customerId;
    private Money totalAmount;
    private OrderStatus status;
    private List<OrderItem> items;

    public void addItem(Product product, Quantity quantity) {
        validateNotFinalized();
        var item = OrderItem.create(product, quantity);
        this.items.add(item);
        recalculateTotal();
    }

    private void validateNotFinalized() {
        if (status == OrderStatus.CONFIRMED || status == OrderStatus.CANCELLED) {
            throw new OrderAlreadyFinalizedException(id);
        }
    }
}

// application/port/in/CreateOrderUseCase.java
public interface CreateOrderUseCase {
    OrderId execute(CreateOrderCommand command);
}

// application/service/CreateOrderService.java
@Service
@RequiredArgsConstructor
public class CreateOrderService implements CreateOrderUseCase {
    private final LoadCustomerPort loadCustomer;
    private final SaveOrderPort saveOrder;
    private final PublishEventPort publishEvent;

    @Override
    @Transactional
    public OrderId execute(CreateOrderCommand command) {
        var customer = loadCustomer.load(command.customerId())
            .orElseThrow(() -> new CustomerNotFoundException(command.customerId()));

        var order = Order.create(customer.id(), command.items());
        saveOrder.save(order);
        publishEvent.publish(new OrderCreatedEvent(order.id(), order.totalAmount()));
        return order.id();
    }
}
```

### 2.2.3 api-designer

**Função:** Designer de APIs REST com OpenAPI 3.1. Garante contratos consistentes, previsíveis e evoluíveis.

**Quando usar:**
- Projetar APIs REST com spec OpenAPI completa
- Definir recursos, verbos, status codes, paginação
- Padronizar erros com Problem Details (RFC 9457)
- Estratégia de versionamento

**Exemplo REAL:**
```yaml
# Output do api-designer
openapi: 3.1.0
info:
  title: Order Service API
  version: 1.0.0
paths:
  /api/v1/orders:
    get:
      summary: Listar pedidos com paginação cursor-based
      parameters:
        - name: status
          in: query
          schema: { type: string, enum: [CREATED, CONFIRMED, SHIPPED, CANCELLED] }
        - name: from
          in: query
          schema: { type: string, format: date }
        - name: cursor
          in: query
          schema: { type: string }
        - name: size
          in: query
          schema: { type: integer, default: 20, maximum: 100 }
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                properties:
                  data: { type: array, items: { $ref: '#/components/schemas/OrderResponse' } }
                  cursor: { type: string, nullable: true }
                  hasMore: { type: boolean }
        '400':
          content:
            application/problem+json:
              schema: { $ref: '#/components/schemas/ProblemDetail' }

components:
  schemas:
    ProblemDetail:
      type: object
      properties:
        type: { type: string, format: uri }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }
        instance: { type: string }
        code: { type: string }  # Código estável: ORDER-001
```

### 2.2.4 code-reviewer

**Função:** Revisor sênior focado em correção, design, segurança e performance.

**Quando usar:** PROATIVAMENTE após implementação — toda feature passa por review.

**Checklist que ele segue:**
```
ARQUITETURA
  □ Domain model sem import de Spring/JPA/Kafka
  □ Use case não acessa banco diretamente (usa port out)
  □ Controller não tem lógica de negócio

SEGURANÇA
  □ Sem SQL injection (parameterized queries)
  □ Sem dados sensíveis em logs
  □ Endpoints protegidos por autenticação

PERFORMANCE
  □ Sem N+1 queries
  □ Índices existem para queries frequentes
  □ Sem memory leak (streams não fechados)
```

### 2.2.5 refactoring-engineer

**Função:** Refatoração segura com preservação de comportamento.

**Quando usar:** God class, anemic domain, duplicação, dead code, complexidade ciclomática alta.

**Método:** Mede antes → cria testes se não existem → refatora em passos pequenos → mede depois.

### 2.2.6 devops-engineer (Dev pack context)

**Função:** Docker, Helm, CI/CD e docker-compose para contexto de desenvolvimento.

**Output típico:** Dockerfile multi-stage + docker-compose + Helm chart base.

## 2.3 QA Pack (8 agents)

### 2.3.1 qa-lead

**Função:** Estrategista de qualidade. Define pirâmide de testes, quality gates, priorização de gaps.

**Exemplo REAL de output:**
```
SCORE DE QUALIDADE: 62/100

PIRÂMIDE ATUAL:
  Unit: 145 testes (OK)
  Integration: 23 testes (BAIXO — esperado: 40+)
  Contract: 0 testes (CRÍTICO — sem contrato entre serviços)
  E2E: 5 testes (ACEITÁVEL para smoke)
  Performance: 0 (RISCO — sem baseline de carga)

TOP 5 GAPS POR RISCO:
  1. [CRÍTICO] CreateOrderUseCase sem teste unitário — regras de negócio core
  2. [CRÍTICO] Sem contract tests — payment-service pode quebrar order-service
  3. [ALTO] Repository tests usando H2 em vez de Testcontainers
  4. [MÉDIO] Sem teste de idempotência no Kafka consumer
  5. [BAIXO] 12 testes com Thread.sleep (flaky candidates)
```

### 2.3.2 unit-test-engineer

**Função:** JUnit 5 + Mockito + AssertJ. TDD quando possível. Given-When-Then.

**Exemplo REAL:**
```java
@DisplayName("CreateOrderUseCase")
class CreateOrderUseCaseTest {

    @Mock LoadCustomerPort loadCustomer;
    @Mock SaveOrderPort saveOrder;
    @Mock PublishEventPort publishEvent;
    @InjectMocks CreateOrderService sut;

    @Test
    @DisplayName("should create order when customer exists and items valid")
    void shouldCreateOrder_whenCustomerExistsAndItemsValid() {
        // Given
        var customerId = CustomerId.of(UUID.randomUUID());
        var command = new CreateOrderCommand(customerId, List.of(
            new OrderItemCommand(ProductId.of(1L), Quantity.of(2))
        ));
        given(loadCustomer.load(customerId))
            .willReturn(Optional.of(CustomerFixture.aCustomer(customerId)));

        // When
        var orderId = sut.execute(command);

        // Then
        assertThat(orderId).isNotNull();
        then(saveOrder).should().save(argThat(order ->
            order.customerId().equals(customerId) &&
            order.items().size() == 1 &&
            order.status() == OrderStatus.CREATED
        ));
        then(publishEvent).should().publish(any(OrderCreatedEvent.class));
    }

    @Test
    @DisplayName("should throw when customer not found")
    void shouldThrow_whenCustomerNotFound() {
        // Given
        var command = new CreateOrderCommand(CustomerId.of(UUID.randomUUID()), List.of());
        given(loadCustomer.load(any())).willReturn(Optional.empty());

        // When/Then
        assertThatThrownBy(() -> sut.execute(command))
            .isInstanceOf(CustomerNotFoundException.class);
        then(saveOrder).shouldHaveNoInteractions();
    }
}
```

### 2.3.3 integration-test-engineer

**Função:** Testcontainers com PostgreSQL/Kafka/Redis reais. Nunca H2.

**Exemplo REAL:**
```java
@SpringBootTest
@Testcontainers
class OrderRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired OrderJpaRepository repository;

    @Test
    @DisplayName("should persist and retrieve order with items")
    void shouldPersistAndRetrieveOrderWithItems() {
        // Given
        var order = OrderFixture.anOrder().withItems(3).build();

        // When
        repository.save(OrderMapper.toEntity(order));
        var found = repository.findById(order.id().value());

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getItems()).hasSize(3);
    }
}
```

### 2.3.4 contract-test-engineer

**Função:** Pact ou Spring Cloud Contract para APIs e Kafka events entre serviços.

### 2.3.5 performance-engineer

**Função:** Gatling/k6 para load, stress e soak tests com SLOs definidos.

### 2.3.6 e2e-test-engineer

**Função:** RestAssured para API E2E, Playwright para UI.

### 2.3.7 test-automation-engineer

**Função:** Geração automática, detecção de flaky tests, Pitest para mutation testing.

### 2.3.8 security-test-engineer

**Função:** OWASP Top 10 — injection, auth bypass, IDOR, XSS, misconfig. Gera testes automatizados integráveis ao CI.

## 2.4 DevOps Pack (11 agents) — EXPANDIDO

### 2.4.1 devops-lead

**Função:** Estrategista de plataforma. FinOps, priorização, definição de SLOs.

### 2.4.2 iac-engineer

**Função:** Terraform/OpenTofu. Módulos, state management, multi-environment.

**Quando usar:**
- Criar módulos Terraform para EKS, RDS, VPC
- Estruturar repositório IaC multi-cloud e multi-environment
- Gerenciar state (remote, locking, workspaces)
- Provisionar clusters, databases, cache, messaging

**Exemplo REAL — módulo EKS com Karpenter:**
```hcl
# modules/eks/main.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project}-${var.environment}"
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access  = var.environment == "production" ? false : true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      labels = { role = "system" }
      taints = []
    }
  }

  # Karpenter
  enable_karpenter = true
  karpenter_node = {
    iam_role_additional_policies = {
      SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  tags = var.common_tags
}

# Karpenter NodePool para workloads com spot
resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata   = { name = "default" }
    spec = {
      template = {
        spec = {
          requirements = [
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot", "on-demand"] },
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "node.kubernetes.io/instance-type", operator = "In",
              values = ["t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge"] }
          ]
          nodeClassRef = { name = "default" }
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter          = "720h"
      }
      limits = { cpu = "100", memory = "400Gi" }
    }
  })
}
```

### 2.4.3 cicd-engineer

**Função:** GitHub Actions, GitOps, quality gates, deploy strategies.

**Exemplo REAL — Pipeline completo:**
```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read
  packages: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '21', cache: maven }

      - name: Build and test
        run: ./mvnw verify -B -Dorg.slf4j.simpleLogger.log.org.apache=ERROR

      - name: Quality gate — coverage
        run: |
          COVERAGE=$(grep -oP 'INSTRUCTION.*?(\d+)%' target/site/jacoco/index.html | grep -oP '\d+' | head -1)
          if [ "${COVERAGE}" -lt 80 ]; then
            echo "❌ Coverage ${COVERAGE}% < 80%"
            exit 1
          fi

  security-scan:
    runs-on: ubuntu-latest
    needs: build-test
    steps:
      - uses: actions/checkout@v4
      - name: Dependency check
        run: ./mvnw dependency-check:check -DfailBuildOnCVSS=7

      - name: Secret scan
        uses: gitleaks/gitleaks-action@v2

  build-image:
    runs-on: ubuntu-latest
    needs: [build-test, security-scan]
    if: github.ref == 'refs/heads/main'
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build-image
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Update image tag in GitOps repo
        uses: actions/github-script@v7
        with:
          script: |
            // Trigger ArgoCD sync via image tag update
```

### 2.4.4 kubernetes-engineer

**Função:** Workloads, autoscaling (HPA/VPA/Karpenter), networking, spot instances, troubleshooting.

**Quando usar:**
- Configurar workloads (Deployment, StatefulSet, Jobs)
- Autoscaling com HPA + custom metrics (Kafka consumer lag)
- Networking (Services, Ingress, NetworkPolicy)
- Spot instances com tolerância a interrupção
- Troubleshooting: CrashLoopBackOff, OOMKilled, scheduling failures

**Exemplo REAL — Deployment production-ready:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  template:
    spec:
      serviceAccountName: order-service
      terminationGracePeriodSeconds: 30
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: order-service
      containers:
        - name: order-service
          image: registry/order-service:abc1234
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
          startupProbe:
            httpGet: { path: /actuator/health/liveness, port: 8080 }
            failureThreshold: 30
            periodSeconds: 2
          livenessProbe:
            httpGet: { path: /actuator/health/liveness, port: 8080 }
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet: { path: /actuator/health/readiness, port: 8080 }
            periodSeconds: 5
            failureThreshold: 2
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 5"]
          env:
            - name: JAVA_OPTS
              value: "-XX:MaxRAMPercentage=75 -XX:+UseZGC"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: order-service
```

### 2.4.5 observability-engineer

**Função:** Prometheus, Grafana, Loki, OpenTelemetry, alertas SLO-based.

**Exemplo REAL — SLO-based alerting com burn rate:**
```yaml
# PrometheusRule para burn rate alerting
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: order-service-slo
spec:
  groups:
    - name: order-service.slo
      rules:
        # Recording: error ratio últimas N horas
        - record: order_service:error_ratio:1h
          expr: |
            sum(rate(http_server_requests_seconds_count{service="order-service",status=~"5.."}[1h]))
            /
            sum(rate(http_server_requests_seconds_count{service="order-service"}[1h]))

        # Alert: SLO 99.9% — burn rate > 14.4x em 1h (page)
        - alert: OrderServiceHighErrorBurnRate
          expr: order_service:error_ratio:1h > (14.4 * 0.001)
          for: 2m
          labels:
            severity: critical
            team: backend
          annotations:
            summary: "order-service error budget burning fast"
            description: "Error rate {{ $value | humanizePercentage }} — SLO 99.9%"
            runbook: "https://wiki/runbooks/order-service-errors"
```

### 2.4.6 security-ops

**Função:** Vault, NetworkPolicy, RBAC, Pod Security Standards, scanning.

**Exemplo REAL — NetworkPolicy zero trust:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: order-service-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: order-service
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: payment-service
      ports:
        - port: 8080
    - to:  # PostgreSQL
        - namespaceSelector:
            matchLabels:
              name: database
      ports:
        - port: 5432
    - to:  # DNS
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
```

### 2.4.7 service-mesh-engineer

**Função:** Istio/Linkerd — mTLS, traffic management, canary, circuit breaking.

### 2.4.8 sre-engineer

**Função:** Incidents, postmortems, chaos engineering, DR, runbooks.

**Workflow de incidente:**
```
1. DETECT  → Alerta Prometheus/Datadog/PagerDuty
2. TRIAGE  → SEV1-4, impacto, serviços afetados
3. MITIGATE → Rollback, scale up, feature flag
4. DIAGNOSE → Root cause (logs, traces, deploy diff)
5. FIX     → Correção definitiva
6. POSTMORTEM → Timeline + root cause + action items
```

**Comandos de diagnóstico rápido:**
```bash
# O que mudou?
kubectl rollout history deployment/order-service -n production
helm history order-service -n production

# Pods saudáveis?
kubectl get pods -n production -l app=order-service
kubectl top pods -n production -l app=order-service

# Logs de erro
kubectl logs -l app=order-service -n production --tail=100 | grep ERROR

# Métricas instantâneas
kubectl exec -it $(kubectl get pod -l app=prometheus -o name) -- \
  promtool query instant http://localhost:9090 \
  'rate(http_server_requests_seconds_count{service="order-service",status=~"5.."}[5m])'
```

### 2.4.9 aws-cloud-engineer

**Função:** EKS, ECS, RDS/Aurora, IAM, VPC — design, trade-offs e custo.

### 2.4.10 finops-engineer

**Função:** Análise de custos AWS, rightsizing, Savings Plans, waste identification.

**Exemplo REAL — Identificar waste:**
```bash
# ELBs sem targets (idle)
aws elbv2 describe-target-groups --query \
  'TargetGroups[?length(LoadBalancerArns)==`0`].{Name:TargetGroupName,ARN:TargetGroupArn}'

# EBS volumes não anexados
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[*].{ID:VolumeId,Size:Size,Type:VolumeType,Created:CreateTime}'

# Snapshots órfãos (sem volume associado)
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<`2025-01-01`].{ID:SnapshotId,Size:VolumeSize}'

# NAT Gateway data processing (custo oculto)
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToDestination \
  --dimensions Name=NatGatewayId,Value=nat-xxx \
  --start-time $(date -d '7 days ago' --utc +%FT%TZ) \
  --end-time $(date --utc +%FT%TZ) \
  --period 86400 --statistics Sum
```

### 2.4.11 gitops-engineer

**Função:** ArgoCD, FluxCD, progressive delivery, Image Updater.

## 2.5 Data Pack (3 agents)

### 2.5.1 dba

**Função:** Schema design, Flyway migrations, JPA/Hibernate, query tuning.

**Exemplo REAL — Migration zero-downtime (add column NOT NULL):**
```sql
-- V15__add_discount_to_orders.sql
-- Fase 1: Adicionar coluna nullable (sem lock)
ALTER TABLE orders ADD COLUMN discount_amount DECIMAL(19,2);

-- V16__backfill_discount_default.sql
-- Fase 2: Backfill em batches (sem lock longo)
UPDATE orders SET discount_amount = 0.00
WHERE discount_amount IS NULL
  AND id IN (SELECT id FROM orders WHERE discount_amount IS NULL LIMIT 10000);
-- Repetir até completar (script de loop no runbook)

-- V17__set_discount_not_null.sql (APÓS código atualizado para enviar discount)
-- Fase 3: Constraint NOT NULL (lock breve)
ALTER TABLE orders ALTER COLUMN discount_amount SET NOT NULL;
ALTER TABLE orders ALTER COLUMN discount_amount SET DEFAULT 0.00;
```

### 2.5.2 database-engineer

**Função:** PostgreSQL/Aurora — RDS operations, EXPLAIN ANALYZE, VACUUM, connection pooling, DR.

### 2.5.3 mysql-engineer

**Função:** MySQL 8.x/MariaDB — pt-osc, gh-ost, GTID replication, Performance Schema.

## 2.6 Migration Pack (7 agents)

### 2.6.1 tech-lead — Coordenação, ADRs, priorização de extração
### 2.6.2 domain-analyst — Bounded contexts, Event Storming, context maps
### 2.6.3 backend-engineer — Seams, Strangler Fig, extração de microsserviço
### 2.6.4 data-engineer — CDC, dual-write, data split, validação de integridade
### 2.6.5 platform-engineer — Routing progressivo, shadow traffic, canary
### 2.6.6 qa-engineer — Testes de paridade, golden dataset, regression
### 2.6.7 security-engineer — Distribuição de auth por serviço

## 2.7 Agentes NOVOS (Expansão)

### 2.7.1 chaos-engineer (NOVO)

**Função:** Chaos engineering automatizado com Litmus/Chaos Mesh.

**Quando usar:**
- Validar resiliência antes de lançamento
- Simular falhas de rede, pod kill, latência
- Game days automatizados
- Validar circuit breakers e fallbacks

**Exemplo de prompt:**
```
Input: "Quero validar que o order-service sobrevive se payment-service ficar fora"

Output:
  EXPERIMENTO: Payment Service Unavailable
  HIPÓTESE: Orders em estado PENDING devem aguardar retry sem perder dados
  MÉTODO: Chaos Mesh NetworkChaos — block traffic para payment-service por 5min
  MÉTRICAS: error rate do order-service, consumer lag do Kafka, latência p99
  ROLLBACK: Remover ChaosExperiment CR automaticamente após 5min

  apiVersion: chaos-mesh.org/v1alpha1
  kind: NetworkChaos
  metadata:
    name: payment-unavailable
  spec:
    action: partition
    mode: all
    selector:
      namespaces: [production]
      labelSelectors:
        app: payment-service
    direction: both
    duration: "5m"
```

### 2.7.2 cost-guardian (NOVO)

**Função:** Monitoramento contínuo de custos com alertas automáticos.

**Quando usar:**
- Spike de custo inesperado
- Budget threshold atingido
- Análise de custo por feature/deploy
- Recomendações de Savings Plans

### 2.7.3 compliance-auditor (NOVO)

**Função:** LGPD, SOC2, PCI-DSS — checklists automatizados.

**Quando usar:**
- Auditoria pré-compliance
- Verificar data retention policies
- Validar encryption at rest/in transit
- Mapear dados sensíveis (PII)

### 2.7.4 migration-validator (NOVO)

**Função:** Validação automatizada de paridade entre monólito e microsserviço.

**Quando usar:**
- Shadow traffic comparison
- Golden dataset validation
- Performance baseline comparison
- Data integrity check pós-migração

---

# PARTE 3 — COMANDOS (BASE + EVOLUÇÃO)

## 3.1 Mapa Completo de Comandos

```
┌──────────────────────────────────────────────────────────────┐
│                     COMANDOS POR PACK                         │
├──────────────────────────────────────────────────────────────┤
│ DEV (6)                                                       │
│  /dev-feature    → architect→api-designer→dba→backend-dev→   │
│                    code-reviewer                              │
│  /dev-bootstrap  → architect→backend-dev→dba→api-designer→   │
│                    devops-engineer                            │
│  /full-bootstrap → DEV+QA+DEVOPS packs completos             │
│  /dev-review     → code-reviewer→architect→dba (paralelo)    │
│  /dev-refactor   → refactoring-engineer→code-reviewer        │
│  /dev-api        → architect→api-designer                    │
├──────────────────────────────────────────────────────────────┤
│ QA (8)                                                        │
│  /qa-audit       → qa-lead→test-auto→security-test (paralelo)│
│  /qa-generate    → test-auto→unit-test→integration-test      │
│  /qa-review      → qa-lead→test-auto                         │
│  /qa-performance → performance-engineer                      │
│  /qa-flaky       → test-automation-engineer                  │
│  /qa-contract    → contract-test-engineer                    │
│  /qa-security    → security-test-engineer                    │
│  /qa-e2e         → e2e-test-engineer                         │
├──────────────────────────────────────────────────────────────┤
│ DEVOPS (11)                                                   │
│  /devops-provision → iac→k8s→cicd→observ→security (cadeia)   │
│  /devops-pipeline  → cicd-engineer→security-ops              │
│  /devops-observe   → observability-engineer→devops-lead      │
│  /devops-incident  → sre-engineer→observability-engineer     │
│  /devops-audit     → security-ops→devops-lead→k8s→sre        │
│  /devops-dr        → sre→iac→devops-lead                    │
│  /devops-finops    → finops-engineer→devops-lead             │
│  /devops-gitops    → gitops-engineer→cicd-engineer           │
│  /devops-cloud     → aws-cloud-engineer→security-ops         │
│  /devops-mesh      → service-mesh-engineer→k8s-engineer      │
├──────────────────────────────────────────────────────────────┤
│ DATA (2)                                                      │
│  /data-optimize    → database-engineer ou mysql→dba           │
│  /data-migrate     → dba→database-engineer ou mysql           │
├──────────────────────────────────────────────────────────────┤
│ MIGRATION (4)                                                 │
│  /migration-discovery    → domain-analyst→data→security→tech │
│  /migration-prepare      → backend-engineer→qa-engineer      │
│  /migration-extract      → TODOS os 7 agents migration       │
│  /migration-decommission → backend→data→qa                   │
└──────────────────────────────────────────────────────────────┘
```

## 3.2 Comandos DevOps Detalhados

### /devops-provision — Provisionar Infra Completa

**Descrição:** Provisiona toda a infraestrutura para um novo serviço: IaC, Kubernetes, CI/CD, observabilidade e segurança.

**Agentes envolvidos:** iac-engineer → kubernetes-engineer → cicd-engineer → observability-engineer → security-ops → devops-lead (consolidação)

**Prompt completo:**
```
/devops-provision order-service aws
```

**O que acontece:**
1. `iac-engineer` — Módulos Terraform (RDS, cache, messaging, IAM, security groups)
2. `kubernetes-engineer` — Helm chart completo (deployment, service, configmap, HPA, PDB)
3. `cicd-engineer` — Pipeline CI/CD (build → test → quality gate → security → image → deploy)
4. `observability-engineer` — ServiceMonitor, dashboard Grafana, alertas SLO-based
5. `security-ops` — Vault secrets, NetworkPolicy, ServiceAccount, Pod Security Standards
6. `devops-lead` — Runbook operacional, SLOs iniciais, estimativa de custo

**Output esperado:**
```
infra/
  modules/
    order-service/
      main.tf           # RDS PostgreSQL, ElastiCache Redis
      variables.tf      # Inputs tipados com validação
      outputs.tf        # Endpoints para o Helm chart
  environments/
    staging/order-service/
      main.tf
      terraform.tfvars

helm/
  order-service/
    Chart.yaml
    values.yaml
    values-staging.yaml
    values-production.yaml
    templates/
      deployment.yaml   # Com probes, resources, PDB, topology
      service.yaml
      configmap.yaml
      hpa.yaml
      networkpolicy.yaml
      servicemonitor.yaml

.github/workflows/
  order-service-ci.yaml  # Build + test + quality gate
  order-service-cd.yaml  # Deploy via ArgoCD image update

monitoring/
  order-service-dashboard.json   # Grafana (RED method)
  order-service-alerts.yaml      # PrometheusRule SLO-based

docs/devops/
  runbooks/order-service.md
  slos/order-service.md
```

### /devops-incident — Gestão de Incidentes

**Descrição:** Guia resposta a incidente ativo com diagnóstico, mitigação e postmortem.

**Agentes:** sre-engineer → observability-engineer → sre-engineer (postmortem)

**Prompt completo:**
```
/devops-incident "order-service indisponível, erro 503 intermitente"
```

**Sequência de execução:**
```
Step 1 — TRIAGE (sre-engineer)
  Severidade: SEV2 (parcial outage, > 10% error rate)
  Impacto: Checkout afetado, pedidos não são criados
  Serviços: order-service, possivelmente payment-service

Step 2 — SIGNAL GATHERING (observability-engineer)
  Métricas: error rate subiu de 0.1% para 15% às 14:32
  Logs: "Connection refused to payment-service:8080"
  Traces: Latência p99 de 200ms → 30s (timeout)
  Correlação: Deploy do payment-service v2.3.1 às 14:30

Step 3 — MITIGATE (sre-engineer)
  Ação: Rollback payment-service para v2.3.0
  Comando: helm rollback payment-service 5 -n production
  Verificação: Error rate caiu para 0.1% em 2 minutos

Step 4 — POSTMORTEM (sre-engineer)
  docs/devops/postmortems/2025-03-15-order-service-503.md
  Root cause: payment-service v2.3.1 mudou porta de health check
  Action items:
    1. [P0] Adicionar contract test de health endpoint
    2. [P1] Smoke test automático pós-deploy
    3. [P2] Alert de error rate > 1% com page
```

### /k8s-debug (NOVO)

**Descrição:** Diagnóstico automatizado de problemas em Kubernetes.

**Agentes:** kubernetes-engineer → observability-engineer

**Prompt completo:**
```
/k8s-debug order-service production
```

**Sequência:**
```
Step 1 — Pod Status
  kubectl get pods -n production -l app=order-service -o wide
  kubectl describe pod <pod-com-problema>

Step 2 — Eventos
  kubectl get events -n production --field-selector involvedObject.name=order-service --sort-by=.lastTimestamp

Step 3 — Logs
  kubectl logs -l app=order-service -n production --tail=200 --since=15m | grep -E "ERROR|WARN|OOM|Kill"

Step 4 — Resources
  kubectl top pods -n production -l app=order-service
  kubectl describe node <node-do-pod> | grep -A5 "Allocated resources"

Step 5 — Diagnóstico
  CrashLoopBackOff → verificar logs de startup, readiness probe, OOM
  ImagePullBackOff → verificar registry, credentials, tag
  Pending → verificar resources, node capacity, taints
  Evicted → node under pressure (disk/memory)

Step 6 — Recomendação
  Se OOMKilled: aumentar memory limit ou investigar leak
  Se CrashLoop: verificar startup probe timeout, connection strings
```

### /terraform-apply (NOVO)

**Descrição:** Apply seguro com pre-flight checks, plan review, e rollback plan.

**Agentes:** iac-engineer → security-ops → devops-lead

**Prompt completo:**
```
/terraform-apply production vpc
```

**Sequência:**
```
Step 1 — Pre-flight (iac-engineer)
  aws sts get-caller-identity  # Conta correta?
  terraform init               # Backend conectado?
  terraform fmt -check         # Formatação?
  terraform validate           # Sintaxe?
  tflint --recursive           # Lint?
  checkov -d . --compact       # Security?

Step 2 — Plan review (iac-engineer)
  terraform plan -out=tfplan -no-color
  # Revisar: quantos create, update, destroy?
  # ALERTA se destroy > 0 em produção

Step 3 — Cost impact (devops-lead)
  infracost diff --path . --format table
  # BLOQUEAR se aumento > threshold

Step 4 — Security review (security-ops)
  # IAM changes? Security group changes? Public access?

Step 5 — Apply (com aprovação explícita)
  terraform apply tfplan
  # Verificar que recursos foram criados corretamente

Step 6 — Rollback plan
  git revert HEAD --no-edit
  terraform plan  # Verificar que reverte limpo
```

### /analyze-logs (NOVO)

**Descrição:** Análise profunda de logs com correlação de eventos.

**Agentes:** observability-engineer → sre-engineer

**Prompt completo:**
```
/analyze-logs order-service production "últimas 2 horas"
```

**Sequência:**
```
Step 1 — Coleta
  # Loki
  logcli query '{app="order-service",namespace="production"}' --since=2h --limit=5000

  # CloudWatch (fallback)
  aws logs filter-log-events --log-group-name /eks/production/order-service \
    --start-time $(date -d '2 hours ago' +%s000) --filter-pattern "ERROR"

Step 2 — Classificação
  Agrupar por:
    - Error type (NullPointer, Connection, Timeout, Auth)
    - Frequência (top 10 errors)
    - Correlação temporal (spikes)
    - TraceID (distributed tracing)

Step 3 — Correlação
  Cruzar com:
    - Deploys recentes
    - Métricas de infra (CPU, memory, connections)
    - Eventos K8s (pod restarts, evictions)

Step 4 — Relatório
  Top 5 problemas com impacto estimado
  Timeline de eventos
  Sugestões de correção
```

### /design-service (NOVO)

**Descrição:** Design completo de microsserviço antes da implementação.

**Agentes:** architect → api-designer → dba → devops-lead

**Prompt completo:**
```
/design-service notification-service
```

**Output:**
```
1. RESPONSABILIDADE
   Enviar notificações (email, SMS, push) disparadas por eventos de domínio

2. COMUNICAÇÃO
   - Consome eventos via Kafka (OrderCreated, PaymentConfirmed, ShipmentSent)
   - Expõe REST para consulta de histórico e preferências
   - Não chama outros serviços sincronamente

3. MODELO DE DADOS
   - notifications (id, user_id, channel, type, status, created_at, sent_at)
   - user_preferences (user_id, channel, enabled, quiet_hours_start/end)
   - templates (id, type, channel, subject_template, body_template, version)

4. API REST
   GET  /api/v1/notifications?userId=xxx&status=SENT&from=2025-01-01
   GET  /api/v1/notifications/{id}
   PUT  /api/v1/users/{userId}/preferences
   POST /api/v1/notifications/send (admin — bypass event)

5. INFRAESTRUTURA ESTIMADA
   - EKS: 2-4 pods (1 vCPU, 1GB each) — ~$50/mês
   - RDS PostgreSQL db.t3.medium — ~$65/mês
   - SES (email) — ~$0.10/1000 emails
   - Total: ~$120/mês staging, ~$200/mês produção

6. ADR-001: Escolha de canal de comunicação
   Decisão: Kafka consumer (não REST webhook)
   Razão: Desacoplamento, retry nativo, backpressure
```

## 3.3 Comandos de Dados e Database

### /data-optimize — Otimização de Query

**Prompt:**
```
/data-optimize "SELECT o.*, c.name FROM orders o JOIN customers c ON o.customer_id = c.id WHERE o.status = 'CREATED' AND o.created_at > '2025-01-01' ORDER BY o.created_at DESC LIMIT 50"
```

**Output esperado:**
```
EXPLAIN ANALYZE:
  Seq Scan on orders (cost=0.00..45123.00 rows=125000)
  Filter: status = 'CREATED' AND created_at > '2025-01-01'
  → 95% do tempo em sequential scan

PROBLEMAS:
  1. Sequential scan na tabela orders (500k rows) — sem índice para status+created_at
  2. Sort on created_at DESC sem índice — filesort em disco
  3. SELECT * carrega 25 colunas — só precisa de 8

SOLUÇÃO:
  -- Migration Flyway
  -- V23__add_idx_orders_status_created.sql
  CREATE INDEX CONCURRENTLY idx_orders_status_created_desc
    ON orders (status, created_at DESC)
    WHERE status IN ('CREATED', 'PENDING');  -- partial index

  -- Query otimizada
  SELECT o.id, o.customer_id, o.total_amount, o.status, o.created_at, c.name
  FROM orders o
  JOIN customers c ON o.customer_id = c.id
  WHERE o.status = 'CREATED' AND o.created_at > '2025-01-01'
  ORDER BY o.created_at DESC
  LIMIT 50;

RESULTADO ESPERADO:
  Antes: 1200ms (seq scan + filesort)
  Depois: 3ms (index scan + index-ordered)
```

---

# PARTE 4 — VERSÕES LITE (CRÍTICO)

Para cada comando existe uma versão completa (multi-agent, multi-step) e uma versão LITE (rápida, single-agent, foco no essencial).

## 4.1 Dev Pack — Lite

| Comando Completo | Versão LITE | O que muda |
|---|---|---|
| `/dev-feature "feature"` | `Implemente [feature] seguindo hexagonal, com controller, use case e repository` | Sem architect + review separados; backend-dev faz tudo |
| `/dev-bootstrap service` | `Crie estrutura hexagonal Spring Boot para [service] com application.yml e Dockerfile` | Sem ADR, sem Helm, sem pipeline |
| `/full-bootstrap service aws` | `/dev-bootstrap` + `/devops-provision` separados | 2 comandos ao invés de 1 mega-orquestração |
| `/dev-review path/` | `Revise este código por qualidade e segurança` | Review single-perspective |
| `/dev-refactor Class` | `Refatore [Class] reduzindo complexidade` | Sem métricas antes/depois |
| `/dev-api resource` | `Projete endpoints REST para [resource] com OpenAPI` | Sem validação de architect |

## 4.2 QA Pack — Lite

| Comando Completo | Versão LITE | O que muda |
|---|---|---|
| `/qa-audit` | `Mapeie testes existentes e identifique gaps críticos` | Sem score numérico nem security scan |
| `/qa-generate Class` | `Gere testes unitários para [Class] com JUnit 5 e Mockito` | Só unitários, sem integração |
| `/qa-security service` | `Verifique OWASP Top 5 nos endpoints de [service]` | Top 5 ao invés de Top 10 |
| `/qa-contract service` | `Crie contract test básico para [endpoint] com Spring Cloud Contract` | 1 endpoint ao invés de todos |
| `/qa-performance service` | `Crie script k6 básico de load test para [endpoint]` | 1 cenário, sem Gatling |
| `/qa-e2e flow` | `Crie smoke test para [flow] com RestAssured` | Só happy path |
| `/qa-flaky TestClass` | `Analise [TestClass] e identifique causa de instabilidade` | Sem loop de 10x |
| `/qa-review path/` | `Liste anti-patterns nos testes em [path]` | Sem comparação com source |

## 4.3 DevOps Pack — Lite

| Comando Completo | Versão LITE | O que muda |
|---|---|---|
| `/devops-provision svc aws` | `Crie Helm chart para [svc] com deployment, service e HPA` | Só K8s, sem Terraform nem pipeline |
| `/devops-pipeline svc` | `Crie GitHub Actions workflow básico: build → test → docker push` | Sem quality gates avançados |
| `/devops-incident "desc"` | `Diagnostique: pods saudáveis? logs de erro? deploy recente?` | Sem postmortem formal |
| `/devops-observe svc` | `Crie ServiceMonitor e 3 alertas básicos para [svc]` | Sem dashboard completo |
| `/devops-audit` | `Verifique: probes, resources, PDB e NetworkPolicy de [namespace]` | Sem score nem FinOps |
| `/devops-finops` | `Liste top 5 recursos mais caros e waste óbvio` | Sem Savings Plans analysis |
| `/devops-gitops svc` | `Crie ArgoCD Application para [svc] com auto-sync` | Sem Rollouts nem Image Updater |
| `/devops-cloud svc` | `Projete arquitetura AWS básica para [svc]` | Sem IAM detalhado nem custo |
| `/devops-dr svc` | `Defina RTO/RPO e procedimento básico de restore para [svc]` | Sem game day |
| `/devops-mesh svc` | `Configure mTLS e VirtualService básico para [svc]` | Sem canary nem AuthorizationPolicy |

## 4.4 Data Pack — Lite

| Comando Completo | Versão LITE | O que muda |
|---|---|---|
| `/data-optimize query` | `Analise EXPLAIN desta query e sugira índice` | Sem migration Flyway |
| `/data-migrate "desc"` | `Crie migration Flyway para [mudança]` | Sem análise de impacto nem rollback |

## 4.5 Migration Pack — Lite

| Comando Completo | Versão LITE | O que muda |
|---|---|---|
| `/migration-discovery` | `Mapeie bounded contexts deste monólito com acoplamento entre eles` | Sem data inventory nem security |
| `/migration-extract ctx` | `Extraia [ctx] como microsserviço com estrutura hexagonal` | Sem testes de paridade nem infra |

---

# PARTE 5 — WORKFLOWS REAIS

## 5.1 Workflow: Criar Microsserviço do Zero ao Deploy

**Cenário:** Novo `notification-service` precisa ir ao ar em produção.

```
FASE 1 — DESIGN (30 min)
  > /design-service notification-service
  OU
  > /dev-api notifications
  Resultado: ADR + API spec + schema + estimativa de custo

FASE 2 — CÓDIGO (1h)
  > /full-bootstrap notification-service aws
  OU (passo a passo):
  > /dev-bootstrap notification-service
  > /qa-audit
  > /devops-provision notification-service aws
  Resultado: Código + testes + infra + pipeline + observabilidade

FASE 3 — REVIEW (20 min)
  > /dev-review src/main/java/com/example/notification/
  > /qa-security notification-service
  Resultado: Review multi-perspectiva + OWASP scan

FASE 4 — DEPLOY STAGING
  > git push origin main
  Pipeline roda: build → test → quality gate → image → ArgoCD sync staging
  > /qa-e2e "envio de notificação por email"
  Resultado: E2E smoke test passa em staging

FASE 5 — DEPLOY PRODUÇÃO
  Aprovação manual no GitHub Environment
  ArgoCD sync com canary (10% → 50% → 100%)
  > /devops-observe notification-service
  Resultado: Dashboard Grafana + alertas SLO prontos
```

## 5.2 Workflow: Debug de Falha Real em Produção

**Cenário:** Alerta dispara — `order-service` com latência p99 de 5 segundos.

```
MINUTO 0 — ALERTA
  PagerDuty page: "OrderServiceHighLatency - p99 > 3s"

MINUTO 1 — TRIAGE
  > /devops-incident "order-service latência p99 de 5s, erro rate subindo"

  sre-engineer executa:
    kubectl get pods -n production -l app=order-service
    # 3/3 pods Running, mas 1 com 15 restarts

    kubectl logs order-service-7b9f4-xxx --tail=50
    # "java.lang.OutOfMemoryError: Java heap space"

    kubectl top pods -l app=order-service
    # order-service-7b9f4-xxx: 980Mi/1Gi (98% memory!)

MINUTO 5 — DIAGNÓSTICO
  observability-engineer:
    # Grafana: Memory usage crescendo linearmente desde deploy v3.2.0 (2h atrás)
    # Trace: Query N+1 no novo endpoint /api/v1/orders/export
    # O endpoint carrega todos os orders em memória sem paginação

MINUTO 8 — MITIGAÇÃO
  sre-engineer:
    # Opção A: Rollback (mais seguro)
    helm rollback order-service -n production
    # Opção B: Scale up temporário + kill pod com OOM
    kubectl scale deployment order-service --replicas=5 -n production
    kubectl delete pod order-service-7b9f4-xxx

MINUTO 10 — VERIFICAÇÃO
  # Latência p99 caiu para 200ms
  # Error rate voltou a 0.1%
  # Memory estável em 400Mi/1Gi

POST-INCIDENTE
  > /data-optimize "SELECT * FROM orders WHERE status IN ('SHIPPED','DELIVERED')"
  # Adicionar paginação + índice + streaming no endpoint de export

  Postmortem em docs/devops/postmortems/2025-03-15-order-service-oom.md
```

## 5.3 Workflow: Pipeline CI/CD Completo

```
FASE 1 — SETUP
  > /devops-pipeline order-service
  cicd-engineer gera GitHub Actions workflow

FASE 2 — QUALITY GATES
  > /devops-pipeline order-service  (inclui security-ops)
  Gates:
    ✅ Build compila
    ✅ Testes unitários passam
    ✅ Coverage > 80%
    ✅ SonarQube quality gate
    ✅ Dependency check (CVE < 7)
    ✅ Secret scan (gitleaks)
    ✅ Docker image scan (Trivy)
    ✅ Contract tests passam

FASE 3 — DEPLOY
  > /devops-gitops order-service
  gitops-engineer configura:
    ArgoCD Application + auto-sync staging
    Argo Rollouts canary para produção
    Image Updater para write-back de tag
    Sync windows: prod apenas seg-qui 09:00-17:00
```

## 5.4 Workflow: Infra com Terraform

```
FASE 1 — MÓDULOS
  > /devops-provision order-service aws
  iac-engineer cria:
    modules/rds-postgres/     # RDS com multi-AZ, encryption, backups
    modules/elasticache/      # Redis cluster
    modules/eks-service/      # IAM role, service account, namespace

FASE 2 — AMBIENTES
  iac-engineer cria:
    environments/staging/order-service/main.tf
    environments/production/order-service/main.tf
  Cada um com:
    terraform.tfvars específico
    State isolado em S3

FASE 3 — VALIDAÇÃO
  > /terraform-apply staging order-service
  Pre-flight: fmt → validate → tflint → checkov → plan → infracost
  Apply em staging

FASE 4 — PRODUÇÃO
  > /terraform-apply production order-service
  Plan review + aprovação manual + apply
  Verificação pós-apply
```

## 5.5 Workflow: Migração de Monólito (Strangler Fig)

```
FASE 0 — DISCOVERY (1 dia)
  > /migration-discovery
  domain-analyst mapeia bounded contexts
  data-engineer mapeia tabelas e ownership
  tech-lead prioriza: payment > order > user

FASE 1 — PREPARAR (2 dias)
  > /migration-prepare payment
  backend-engineer cria seams no monólito
  qa-engineer captura golden dataset
  ArchUnit tests bloqueiam novas dependências

FASE 2 — EXTRAIR (3-5 dias)
  > /migration-extract payment
  7 agents trabalham em sequência:
    domain-analyst → backend-engineer → data-engineer →
    platform-engineer → qa-engineer → security-engineer → tech-lead

FASE 3 — VALIDAR (2 dias)
  > /qa-contract payment-service
  > /qa-e2e "fluxo de pagamento completo"
  Shadow traffic: 100% duplicado para o novo serviço
  Comparação de respostas: monólito vs microsserviço

FASE 4 — CANARY (1 semana)
  platform-engineer configura:
    5% → 25% → 50% → 75% → 100% do tráfego
  Métricas monitoradas: latência, error rate, data consistency

FASE 5 — DECOMMISSION
  > /migration-decommission payment
  Remover código legado do monólito
  Remover tabelas migradas (após período de segurança)
```

---

# PARTE 6 — CASOS DE USO MASSIVOS

## 6.1 APIs — Design e Evolução

### Cenário: API com breaking change necessária

```
> /dev-api orders

Problema: Campo `totalAmount` precisa ser renomeado para `total` e mudar de string para number

Solução (api-designer):
  Versioning strategy: URL path (/api/v1 → /api/v2)

  1. Criar /api/v2/orders com novo schema
  2. Manter /api/v1/orders por 6 meses (deprecation)
  3. Header Sunset: Sat, 01 Jan 2026 00:00:00 GMT
  4. Response header: Deprecation: true
  5. Log consumers usando v1 para comunicar migração
  6. Contract test validando ambas versões

  Migration path para consumers:
    v1: { "totalAmount": "99.90" }
    v2: { "total": 99.90, "currency": "BRL" }
```

### Cenário: Rate limiting e idempotência

```
> "Como implementar idempotência no POST /api/v1/orders?"

backend-dev:
  1. Client envia header: Idempotency-Key: uuid-xxx
  2. Server verifica se key já existe na tabela idempotency_keys
  3. Se existe: retorna response salvo (HTTP 200, não 201)
  4. Se não: processa, salva response, retorna 201

  CREATE TABLE idempotency_keys (
    key VARCHAR(255) PRIMARY KEY,
    response_status INTEGER NOT NULL,
    response_body JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '24 hours'
  );
  CREATE INDEX idx_idempotency_expires ON idempotency_keys(expires_at);
  -- Cleanup job: DELETE WHERE expires_at < NOW()
```

## 6.2 Pods Quebrando — Diagnóstico Completo

### CrashLoopBackOff

```
> /k8s-debug order-service production

kubectl describe pod order-service-xxx:
  State: Waiting (CrashLoopBackOff)
  Last State: Terminated (Exit Code 137)  ← OOMKilled!
  Restart Count: 15

kubectl logs order-service-xxx --previous:
  "java.lang.OutOfMemoryError: Java heap space"

DIAGNÓSTICO:
  Exit Code 137 = SIGKILL (OOMKilled pelo kernel)
  Container memory limit: 512Mi
  JVM heap: 256Mi default (-XX:MaxRAMPercentage=50)
  Off-heap (metaspace, threads, NIO): ~300Mi
  Total: 556Mi > 512Mi limit = OOM!

CORREÇÃO:
  resources:
    requests: { memory: 768Mi }
    limits: { memory: 1Gi }
  env:
    - name: JAVA_OPTS
      value: "-XX:MaxRAMPercentage=75 -XX:+UseZGC -XX:+ZGenerational"
  # 75% de 1Gi = 768Mi heap, ~250Mi off-heap = OK
```

### ImagePullBackOff

```
DIAGNÓSTICO:
  kubectl describe pod → "Failed to pull image: 401 Unauthorized"

  Causas comuns:
  1. Secret de registry expirado/errado
  2. Image tag não existe
  3. ECR login token expirado (12h)

  kubectl get secret regcred -o json | jq '.data[".dockerconfigjson"]' -r | base64 -d
  # Verificar se credentials estão corretas

CORREÇÃO:
  # Recriar secret ECR
  aws ecr get-login-password | kubectl create secret docker-registry regcred \
    --docker-server=123.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS --docker-password-stdin \
    --dry-run=client -o yaml | kubectl apply -f -
```

## 6.3 Logs Complexos — Análise e Correlação

```
> /analyze-logs payment-service production "últimos 30 minutos"

RESULTADO:
  Total de logs: 45,000
  Errors: 1,230 (2.7%)
  Warns: 3,450 (7.7%)

  TOP 5 ERRORS:
  1. [523x] "Connection pool exhausted" — HikariCP max connections atingido
  2. [312x] "Timeout calling fraud-service" — 5s timeout, upstream lento
  3. [198x] "Duplicate key violation" — race condition em pagamento idempotente
  4. [112x] "SSL handshake failed" — certificado expirado no fraud-service
  5. [85x]  "JSON parse error" — payload inválido de webhook externo

  CORRELAÇÃO TEMPORAL:
  14:30 — Deploy fraud-service v1.5.0 (certificado novo com CN errado)
  14:32 — Timeout errors começam (fraud-service não responde TLS)
  14:35 — Connection pool esgota (threads bloqueadas esperando fraud-service)
  14:38 — Cascade: payment-service fica slow, order-service timeout

  ROOT CAUSE: Certificado TLS do fraud-service v1.5.0 com CN incorreto
  MITIGAÇÃO: Rollback fraud-service para v1.4.9
```

## 6.4 Autoscaling — Configuração e Troubleshooting

### HPA não escalando

```
> "HPA do order-service não escala apesar de CPU alta"

kubernetes-engineer diagnostica:

  kubectl get hpa order-service -n production
  # TARGETS: <unknown>/70%  ← metrics-server não retornando dados!

  kubectl top pods -l app=order-service
  # error: Metrics API not available

  CAUSA: metrics-server não instalado ou crashlooping
  kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

  CORREÇÃO:
  helm install metrics-server metrics-server/metrics-server -n kube-system \
    --set args[0]="--kubelet-insecure-tls"

  # Após 2 minutos:
  kubectl get hpa order-service
  # TARGETS: 85%/70%  ← agora funciona, vai escalar!
```

### HPA com custom metrics (Kafka consumer lag)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-consumer
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-consumer
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: External
      external:
        metric:
          name: kafka_consumer_lag
          selector:
            matchLabels:
              topic: orders.created.v1
              consumer_group: order-processor
        target:
          type: AverageValue
          averageValue: "1000"  # Escala quando lag > 1000 por pod
```

## 6.5 Observabilidade — Stack Completa

```
> /devops-observe order-service

MÉTRICAS (Prometheus):
  ServiceMonitor com scrape do /actuator/prometheus
  Recording rules para queries frequentes
  Dashboard Grafana:
    - RED method: Rate, Errors, Duration
    - JVM: Heap, GC, threads
    - Dependencies: connection pool, Kafka lag, circuit breaker state
    - Business: orders/min, revenue/hour, conversion rate

ALERTAS (SLO-based):
  SLO 99.9% availability:
    - Burn rate 14.4x em 1h → page (SEV1)
    - Burn rate 6x em 6h → ticket (SEV2)
    - Burn rate 1x em 3d → email (SEV3)

LOGS (Loki):
  Structured JSON: timestamp, level, message, traceId, spanId, service, userId
  Loki pipeline para parsing de campos
  Correlação com traces via traceId

TRACES (OpenTelemetry → Tempo):
  Auto-instrumentation para Spring Boot
  Propagação de contexto via W3C TraceContext
  Sampling: 100% em errors, 10% em success
```

## 6.6 Infra Drift (Terraform)

```
> "Terraform plan mostra drift — recursos foram alterados manualmente"

iac-engineer:

  # Detectar drift
  terraform plan -detailed-exitcode
  # Exit code 2 = changes detected

  # Identificar o que mudou
  terraform plan -no-color | grep "~"
  # ~ aws_security_group.main (1 changed attribute)
  # ~ ingress.0.cidr_blocks: ["10.0.0.0/8"] → ["0.0.0.0/0"]
  # ALERTA: Alguém abriu o SG para o mundo!

  OPÇÕES:
  1. terraform apply → Reverter para estado do código (recomendado)
  2. terraform import → Se a mudança manual é intencional, atualizar o código
  3. Investigar quem fez a mudança: aws cloudtrail lookup-events

  PREVENÇÃO:
  - AWS Config rule: detect-security-group-changes
  - SCP (Service Control Policy) bloqueando mudanças manuais em prod
  - Scheduled drift detection: terraform plan em CI rodando diariamente
```

---

# PARTE 7 — PLAYBOOKS OPERACIONAIS

## 7.1 Playbook: Produção Caiu (Incident Response)

**Trigger:** Alerta de indisponibilidade, error rate > 10%, latência > SLO.

```
MINUTO 0-2: TRIAGE
  ┌─────────────────────────────────────────────────────┐
  │ 1. Qual a severidade?                                │
  │    SEV1: Outage completo / data loss / security breach│
  │    SEV2: Parcial / >10% errors / feature crítica down │
  │    SEV3: Degradado / latência alta / feature menor    │
  │    SEV4: Minor / cosmético / single user              │
  │                                                       │
  │ 2. Abrir war room (SEV1/SEV2):                       │
  │    Slack: #incident-YYYYMMDD-sev1-description        │
  │    IC: quem lidera    Tech Lead: quem investiga       │
  │    Comms: quem comunica   Scribe: quem documenta      │
  └─────────────────────────────────────────────────────┘

MINUTO 2-5: SIGNAL GATHERING
  # O que mudou?
  kubectl rollout history deployment/{service} -n production
  helm history {service} -n production
  git log --oneline --since="2 hours ago" -- .

  # Estado dos pods
  kubectl get pods -n production -l app={service} -o wide
  kubectl top pods -n production -l app={service}
  kubectl get events -n production --sort-by=.lastTimestamp | head -20

  # Logs
  kubectl logs -l app={service} -n production --tail=200 | grep ERROR

  # Métricas
  # Grafana: error rate, latência p50/p95/p99, throughput
  # Dashboard de dependências: database, Kafka, Redis, external APIs

MINUTO 5-10: DIAGNÓSTICO E MITIGAÇÃO
  ┌─────────────────────────────────────────────────────┐
  │ REGRA: ESTABILIZAR PRIMEIRO, ENTENDER DEPOIS        │
  │                                                       │
  │ Opções de mitigação (mais rápido primeiro):          │
  │ 1. Rollback deploy: helm rollback {svc} -n prod     │
  │ 2. Scale up: kubectl scale deploy --replicas=10      │
  │ 3. Feature flag off: disable feature X               │
  │ 4. Bypass: redirect traffic, failover               │
  │ 5. Kill pod com problema: kubectl delete pod xxx     │
  └─────────────────────────────────────────────────────┘

MINUTO 10-15: VERIFICAÇÃO
  # Error rate voltou ao normal?
  # Latência dentro do SLO?
  # Pods estáveis?

MINUTO 15+: STATUS UPDATE
  Template:
    **Incident: [título]**
    **Severidade:** SEV2
    **Status:** Mitigado
    **Impacto:** Checkout indisponível por 8 minutos
    **Causa:** Deploy v3.2.0 com memory leak no endpoint de export
    **Ação:** Rollback para v3.1.9
    **Próximo update:** 30 minutos

POST-INCIDENTE (24-48h):
  Postmortem blameless:
    - Timeline detalhada
    - Root cause analysis (5 whys)
    - O que funcionou bem
    - O que poderia ter sido melhor
    - Action items com owner e deadline
```

## 7.2 Playbook: Pod CrashLoopBackOff

```
DIAGNÓSTICO RÁPIDO:
  kubectl describe pod {pod-name}
  kubectl logs {pod-name} --previous  # logs da instância anterior

ÁRVORE DE DECISÃO:
  ┌── Exit Code 137 (OOMKilled)
  │   └── Aumentar memory limits
  │       └── Investigar memory leak se recorrente
  │
  ├── Exit Code 1 (App error)
  │   └── Verificar logs: connection string? config? dependency?
  │       └── Verificar ConfigMap e Secrets montados corretamente
  │
  ├── Exit Code 0 (Success mas restarta)
  │   └── Probes com problema: liveness retornando 200 mas app não pronta
  │       └── Ajustar startup probe: failureThreshold * periodSeconds > tempo de boot
  │
  └── "Back-off restarting failed container"
      └── Image existe? Entrypoint correto? Permissões?

CORREÇÕES COMUNS:
  # OOMKilled
  resources:
    limits:
      memory: "1Gi"  # Aumentar de 512Mi para 1Gi
  env:
    - name: JAVA_OPTS
      value: "-XX:MaxRAMPercentage=75"

  # Startup lento (Spring Boot)
  startupProbe:
    httpGet: { path: /actuator/health/liveness, port: 8080 }
    failureThreshold: 60   # 60 * 2s = 120s para boot
    periodSeconds: 2

  # Connection string errada
  kubectl get configmap {svc}-config -o yaml
  kubectl get secret {svc}-secrets -o yaml  # Verificar se base64 está correto
```

## 7.3 Playbook: Latência Alta

```
DIAGNÓSTICO SISTÊMICO (de fora para dentro):
  ┌──────────────────────────────────────────────────┐
  │ 1. REDE: DNS resolve? TCP connect? TLS handshake?│
  │    dig api.example.com                            │
  │    curl -w "dns:%{time_namelookup} tcp:%{time_connect} tls:%{time_appconnect} total:%{time_total}" https://api.example.com/health │
  │                                                    │
  │ 2. LOAD BALANCER: targets healthy?                │
  │    aws elbv2 describe-target-health                │
  │    Request count vs queue depth                    │
  │                                                    │
  │ 3. POD: CPU/memory OK? GC pauses?                │
  │    kubectl top pods -l app={svc}                   │
  │    JFR: -XX:StartFlightRecording=duration=60s      │
  │                                                    │
  │ 4. DATABASE: Slow queries? Lock contention?       │
  │    pg_stat_activity: idle in transaction?           │
  │    pg_stat_user_tables: seq_scan em tabela grande? │
  │    Connection pool: active vs idle vs waiting?     │
  │                                                    │
  │ 5. DEPENDENCIES: Circuit breaker open?            │
  │    Kafka consumer lag alto?                        │
  │    Redis connection timeout?                       │
  └──────────────────────────────────────────────────┘

CAUSAS MAIS COMUNS:
  1. Query N+1 (80% dos casos de latência em Java)
     → EXPLAIN ANALYZE + índice + JOIN fetch
  2. Connection pool esgotado (HikariCP maxPoolSize muito baixo)
     → Aumentar pool + investigar queries lentas
  3. GC pauses (G1 com heap pequeno, ZGC resolve)
     → -XX:+UseZGC -XX:+ZGenerational
  4. External dependency timeout (payment-service lento)
     → Circuit breaker + timeout + fallback
  5. DNS resolution lento em K8s
     → ndots: 2 no dnsConfig do pod
```

## 7.4 Playbook: Deploy Falhou

```
DECISÃO: ROLLBACK vs ROLL FORWARD?

  Rollback quando:
    ✅ Bug está no deploy atual
    ✅ Versão anterior é known-good
    ✅ Rollback é mais rápido que hotfix
    ✅ Sem migration de dados irreversível

  Roll forward quando:
    ✅ Migration de dados já rodou (rollback causa inconsistência)
    ✅ Issue existe em ambas versões
    ✅ Hotfix pronto em < 15 minutos
    ✅ Rollback quebraria dependência de outro serviço

ROLLBACK KUBERNETES:
  # Via Helm (preferido — preserva histórico)
  helm history {service} -n production
  helm rollback {service} {revision} -n production

  # Via kubectl (se não usa Helm)
  kubectl rollout undo deployment/{service} -n production
  kubectl rollout status deployment/{service} -n production

ROLLBACK TERRAFORM:
  git revert HEAD --no-edit
  git push origin main
  # Pipeline roda terraform plan → apply com estado anterior

ROLLBACK DATABASE (se migration falhou):
  # PITR (Point-in-Time Recovery) — opção nuclear
  aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier prod-db \
    --target-db-instance-identifier prod-db-restored \
    --restore-time "2025-03-15T14:25:00Z"

  # Down migration (se preparada)
  flyway undo  # Requer Flyway Teams

  # Manual SQL rollback
  -- V16__rollback_add_discount.sql
  ALTER TABLE orders DROP COLUMN IF EXISTS discount_amount;
```

## 7.5 Playbook: Secret Rotation Zero-Downtime

```
ESTRATÉGIA: DUAL-CREDENTIAL (sem downtime)

  ┌─────────────────────────────────────────────────┐
  │ 1. Criar nova credencial (sem revogar a antiga) │
  │ 2. Atualizar aplicação para usar a nova         │
  │ 3. Verificar que tudo funciona com a nova        │
  │ 4. Revogar a credencial antiga                   │
  └─────────────────────────────────────────────────┘

EXEMPLO: Rotação de senha do banco
  # 1. Criar nova senha
  NEW_PASS=$(openssl rand -hex 24)

  # 2. Atualizar no banco
  ALTER USER app_user WITH PASSWORD 'nova_senha';

  # 3. Atualizar no Secrets Manager
  aws secretsmanager put-secret-value \
    --secret-id prod/order-service/db \
    --secret-string "{\"password\":\"${NEW_PASS}\"}"

  # 4. Restart pods (para pegar novo secret)
  kubectl rollout restart deployment/order-service -n production
  kubectl rollout status deployment/order-service -n production

  # 5. Verificar que pods estão conectando
  kubectl logs -l app=order-service --tail=10 | grep -i "database\|hikari\|connection"

  # 6. Revogar senha antiga (depois de confirmar)
  # (manter por 24h para safety — logs podem ter referência)
```

## 7.6 Playbook: Terraform Plan & Apply Seguro

```
PRE-FLIGHT:
  aws sts get-caller-identity  # Conta certa?
  terraform init               # Backend OK?
  terraform fmt -check         # Formatação?
  terraform validate           # Sintaxe?
  tflint --recursive           # Lint?
  checkov -d . --compact       # Security?

PLAN:
  terraform plan -out=tfplan -no-color 2>&1 | tee plan-output.txt

  # Análise automática:
  CREATES=$(grep "will be created" plan-output.txt | wc -l)
  UPDATES=$(grep "will be updated" plan-output.txt | wc -l)
  DESTROYS=$(grep "will be destroyed" plan-output.txt | wc -l)

  echo "Creates: $CREATES | Updates: $UPDATES | Destroys: $DESTROYS"

  # GATE: Se DESTROYS > 0 em produção, PARAR e revisar
  if [ "$DESTROYS" -gt 0 ]; then
    echo "⚠️ DESTROYS detectados em produção. Revisão manual obrigatória."
    exit 1
  fi

COST:
  infracost diff --path . --format table

APPLY (com aprovação):
  terraform apply tfplan

POST-APPLY:
  terraform output  # Verificar outputs
  # Testar recursos criados (connectivity, health check)
```

---

# PARTE 8 — NÍVEIS DE MATURIDADE

## Nível 1: Iniciante (Semana 1-2)

**Objetivo:** Usar IA como assistente de código.

**Comandos para dominar:**
```
claude --agent marcus              # Ponto de entrada
/dev-feature "descrição"           # Implementar feature
/dev-review path/                  # Code review
/qa-generate Class                 # Gerar testes
```

**Mentalidade:** "A IA escreve código, eu reviso."

**Erros comuns neste nível:**
- Aceitar código gerado sem review
- Não fornecer contexto suficiente no prompt
- Usar prompts genéricos ("crie um serviço")

## Nível 2: Intermediário (Semana 3-6)

**Objetivo:** Usar IA como par de programação inteligente.

**Comandos para dominar:**
```
/full-bootstrap service aws        # Criar serviço completo
/devops-provision service aws      # Provisionar infra
/devops-incident "descrição"       # Responder incidentes
/data-optimize "query"             # Otimizar queries
/qa-audit                          # Auditoria de qualidade
```

**Mentalidade:** "A IA e eu co-criamos. Eu direciono a arquitetura."

**Evolução:**
- Usar versões completas (não lite) dos comandos
- Combinar comandos em sequência lógica
- Começar a referenciar playbooks

## Nível 3: Avançado (Mês 2-3)

**Objetivo:** Orquestrar IA como time virtual.

**Comandos para dominar:**
```
/migration-discovery → /migration-extract  # Migração completa
/devops-audit + /devops-finops            # Auditoria holística
/qa-security + /qa-contract               # Quality gates avançados
Playbooks completos                       # Incident, DR, terraform
```

**Mentalidade:** "Eu sou o tech lead. A IA é meu time de 36 especialistas."

**Evolução:**
- Criar seus próprios agents personalizados
- Criar seus próprios commands
- Adaptar playbooks para seu contexto
- Combinar agentes de diferentes packs

## Nível 4: Expert (Mês 4+)

**Objetivo:** Criar e evoluir o próprio ecossistema.

**Capabilities:**
```
- Criar agents customizados para domínio específico
- Criar commands que orquestram agentes em patterns inéditos
- Criar skills passivas para convenções do time
- Criar playbooks para operações recorrentes
- Integrar com MCP connectors (Slack, Jira, etc.)
- Automatizar fluxos com hooks do Claude Code
```

**Mentalidade:** "Eu projeto o sistema operacional do meu time."

**Indicadores de maturidade:**
```
Nível 1: 1 agent, prompts ad-hoc
Nível 2: 5-10 agents, commands regulares
Nível 3: 20+ agents, workflows multi-pack, playbooks
Nível 4: Ecossistema customizado, agents próprios, CI/CD integrado
```

---

# PARTE 9 — ERROS REAIS + CORREÇÃO

## 9.1 Prompt Ruim vs Prompt Otimizado

### Erro #1: Prompt genérico

```
❌ RUIM:
"Crie um microsserviço"

✅ OTIMIZADO:
"/dev-bootstrap notification-service"
OU
"Crie microsserviço notification-service com:
- Arquitetura hexagonal (domain/application/adapter)
- Spring Boot 3.2, Java 21
- PostgreSQL com Flyway
- Kafka consumer para OrderCreatedEvent
- Endpoint REST GET /api/v1/notifications
- Docker multi-stage + Helm chart"
```

### Erro #2: Aceitar primeira resposta sem contexto

```
❌ RUIM:
"Otimize esta query" (cola query sem EXPLAIN)

✅ OTIMIZADO:
"/data-optimize 'SELECT ... FROM orders WHERE ...' postgres"
OU
"Otimize esta query. Contexto:
- Tabela orders: 2M rows, PostgreSQL 16, RDS db.r6g.large
- Query roda no endpoint de listagem, chamado 500x/min
- Latência atual: 800ms, SLO: < 200ms
- Índices existentes: PK (id), idx_customer_id
- EXPLAIN ANALYZE: [colar output]"
```

### Erro #3: Ignorar segurança

```
❌ RUIM:
"Crie endpoint de login" (sem mencionar auth)

✅ OTIMIZADO:
"Crie endpoint de autenticação com:
- JWT com refresh token (access 15min, refresh 7 days)
- Bcrypt para hash de senha (cost factor 12)
- Rate limiting: 5 tentativas / 15 minutos por IP
- Audit log de login attempts
- Headers: Strict-Transport-Security, X-Content-Type-Options"
```

### Erro #4: Terraform sem proteção

```
❌ RUIM:
"Crie RDS PostgreSQL" (sem lifecycle, sem backup, sem encryption)

✅ OTIMIZADO:
"/devops-provision order-service aws"
OU
"Crie módulo Terraform para RDS PostgreSQL com:
- Multi-AZ habilitado
- Encryption at rest (KMS)
- Automated backups (7 days retention)
- lifecycle { prevent_destroy = true }
- Parameter group com shared_preload_libraries = 'pg_stat_statements'
- Security group restrito a VPC
- Estimated cost included"
```

## 9.2 Problemas Comuns em DevOps/K8s

### Problema: Deploy sexta à noite

```
ANTI-PATTERN:
  Deploy de feature grande em sexta às 17h sem canary

CORREÇÃO:
  1. Sync windows no ArgoCD: bloquear sexta 15:00 - segunda 09:00
  2. Deploy com canary: 5% → monitor 30min → 50% → monitor 1h → 100%
  3. Feature flags: deploy código inativo, ativar flag segunda-feira
  4. Playbook: rollback-strategy.md sempre à mão
```

### Problema: Sem probes → deploy "verde" mas morto

```
ANTI-PATTERN:
  Deployment sem livenessProbe e readinessProbe
  Pod roda mas app travou → K8s não sabe, não reinicia

CORREÇÃO:
  startupProbe:   # App boot completo
    httpGet: { path: /actuator/health/liveness, port: 8080 }
    failureThreshold: 30
    periodSeconds: 2
  livenessProbe:  # App viva (reinicia se falhar)
    httpGet: { path: /actuator/health/liveness, port: 8080 }
    periodSeconds: 10
    failureThreshold: 3
  readinessProbe: # App pronta para tráfego (remove do LB se falhar)
    httpGet: { path: /actuator/health/readiness, port: 8080 }
    periodSeconds: 5
    failureThreshold: 2
```

### Problema: Sem resource limits → noisy neighbor

```
ANTI-PATTERN:
  Pod sem requests/limits → um pod consome todo o node
  Outros pods são evicted

CORREÇÃO:
  resources:
    requests:        # Scheduling: "preciso de pelo menos isso"
      cpu: 500m
      memory: 512Mi
    limits:          # Hard limit: "máximo que pode usar"
      cpu: "1"
      memory: 1Gi

  REGRA: requests = uso médio, limits = 2x requests (ou pico medido)
  NUNCA: limits sem requests (scheduling errado)
  NUNCA: memory limit muito próximo de requests (OOM frequente)
```

### Problema: Secret hardcoded

```
ANTI-PATTERN:
  application.yml com password: "admin123"

CORREÇÃO:
  # 1. External secret (Kubernetes)
  apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  metadata:
    name: order-service-db
  spec:
    refreshInterval: 1h
    secretStoreRef: { name: aws-secrets, kind: ClusterSecretStore }
    target: { name: order-service-db }
    data:
      - secretKey: password
        remoteRef: { key: prod/order-service/db, property: password }

  # 2. application.yml referencia env var
  spring:
    datasource:
      password: ${DB_PASSWORD}

  # 3. Pod monta secret como env
  env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef: { name: order-service-db, key: password }
```

## 9.3 Anti-Patterns de Terraform

```
ANTI-PATTERN                          CORREÇÃO
───────────────────────────────────── ──────────────────────────────
terraform apply sem plan              Sempre: plan -out=tfplan → apply tfplan
State local                           Remote state S3 + DynamoDB locking
Prod e dev no mesmo state             Directory-per-environment
count para recursos condicionais      for_each com map (chave estável)
Módulo sem version                    source = "...?ref=v1.2.0"
Secrets em terraform.tfvars           Variáveis de ambiente ou Secrets Manager
Sem prevent_destroy em RDS/S3         lifecycle { prevent_destroy = true }
terraform taint                       terraform apply -replace=resource.name
Todos os recursos em 1 state         Separar por componente: vpc, ecs, rds
```

---

# PARTE 10 — HACKS AVANÇADOS

## 10.1 Engenharia de Prompt Avançada para Agentes

### Técnica: Context Loading

Antes de pedir algo complexo, carregue contexto:
```
"Antes de implementar, leia:
- pom.xml (versão Java, dependências)
- CLAUDE.md (convenções do projeto)
- src/main/java/.../domain/ (modelo existente)
- src/main/resources/db/migration/ (schema atual)
Depois implemente [feature]."
```

### Técnica: Chain of Agents

Para tarefas complexas, defina a cadeia explicitamente:
```
"Execute nesta ordem:
1. Como architect: avalie se precisamos de CQRS
2. Como dba: projete o schema de leitura otimizado
3. Como backend-dev: implemente a projeção de eventos
4. Como code-reviewer: revise a implementação"
```

### Técnica: Constraint-Driven Prompt

Force constraints para output melhor:
```
"Implemente o endpoint com estas restrições:
- ZERO imports de Spring no domain/model
- MÁXIMO 20 linhas por método
- TODOS os edge cases como testes separados
- SEM comentários (código autoexplicativo)
- NAMING: em inglês, descritivo, sem abreviações"
```

### Técnica: Anti-Pattern Guard

```
"Implemente mas NUNCA faça:
- ❌ H2 em testes (use Testcontainers)
- ❌ Thread.sleep em testes (use Awaitility)
- ❌ @DirtiesContext (use @Transactional com rollback)
- ❌ catch genérico (catch Exception)
- ❌ SELECT * (listar campos explicitamente)"
```

## 10.2 Orquestração de Agentes Avançada

### Pattern: Fan-out/Fan-in (paralelo)

Use quando múltiplos agents podem trabalhar independentemente:
```
/dev-review usa este pattern:
  Fan-out: code-reviewer, architect, dba (em paralelo)
  Fan-in: consolidar reviews em relatório único
```

### Pattern: Pipeline (sequencial)

Use quando cada step depende do anterior:
```
/dev-feature usa este pattern:
  architect → api-designer → dba → backend-dev → code-reviewer
  Cada step recebe output do anterior como input
```

### Pattern: Specialist + Generalist

Use quando precisa de profundidade e visão:
```
kubernetes-engineer (specialist) analisa o manifesto
devops-lead (generalist) consolida com visão de custo, segurança e SLOs
```

### Pattern: Criar seu próprio Command

```markdown
# ~/.claude/commands/my-deploy-check.md
---
name: my-deploy-check
description: "Verificação pré-deploy customizada"
argument-hint: "[serviço]"
---

# Pre-Deploy Check: $ARGUMENTS

## Instruções

### Step 1: Qualidade
Use **qa-lead** para verificar cobertura > 80% e 0 critical issues.

### Step 2: Segurança
Use **security-ops** para verificar NetworkPolicy e secrets.

### Step 3: Infra
Use **kubernetes-engineer** para verificar probes, resources, PDB.

### Step 4: Apresentar
Go/No-Go com justificativa para cada área.
```

## 10.3 Como Pensar Como Arquiteto com IA

### Framework de Decisão

Para cada decisão arquitetural, passe por:
```
1. CONTEXTO
   "Estamos migrando o módulo de pagamentos do monólito"

2. DRIVERS
   "SLA de 99.99%, latência < 200ms, LGPD compliance"

3. OPÇÕES
   Pedir ao architect para listar 2-3 opções com trade-offs

4. CONSEQUÊNCIAS
   Para cada opção: custo, complexidade, risco, reversibilidade

5. DECISÃO
   Documentar em ADR com justificativa

6. VALIDAÇÃO
   Usar /devops-provision para validar viabilidade técnica
   Usar /devops-finops para validar custo
```

### Thinking Modes

```
🔍 ZOOM IN  — "Detalhe a implementação do circuit breaker"
🔭 ZOOM OUT — "Como isso afeta a arquitetura geral?"
⚡ FAST      — Versão lite do comando para decisão rápida
🔬 DEEP     — Versão completa com todos os agents
🔄 ITERATE  — "Melhore o output anterior com este feedback"
```

## 10.4 Acelerar Evolução em Microsserviços

### Template de Novo Serviço (30 minutos)

```bash
# 1. Design (5 min)
/design-service {name}

# 2. Scaffold (10 min)
/full-bootstrap {name} aws

# 3. Review (5 min)
/dev-review src/

# 4. Deploy staging (5 min)
git push  # Pipeline automático

# 5. Validate (5 min)
/qa-e2e "smoke {name}"
```

### Checklist de Readiness (pré-produção)

```
CODE
  □ Cobertura > 80%
  □ Contract tests passando
  □ Security scan sem critical
  □ Code review aprovado

INFRA
  □ Probes configuradas (startup + liveness + readiness)
  □ Resources com requests e limits
  □ PDB configurado (minAvailable >= 2)
  □ NetworkPolicy restritiva
  □ Secrets via External Secrets (não hardcoded)
  □ HPA configurado

OBSERVABILITY
  □ ServiceMonitor para Prometheus
  □ Dashboard Grafana (RED + JVM)
  □ Alertas SLO-based com burn rate
  □ Structured logging (JSON + traceId)
  □ Distributed tracing (OpenTelemetry)

OPERATIONS
  □ Runbook operacional documentado
  □ SLOs definidos
  □ DR plan com RTO/RPO
  □ Rollback testado em staging
  □ Pipeline CI/CD completo com quality gates

SECURITY
  □ RBAC com least privilege
  □ mTLS entre serviços (Istio)
  □ Image scan sem critical CVEs
  □ OWASP Top 10 validado
```

### Métricas do Ecossistema

Para medir o valor do sistema de agentes:

```
VELOCIDADE
  - Tempo médio de bootstrap de serviço: < 1h (era 2-3 dias)
  - Tempo médio de feature end-to-end: < 4h (era 2-3 dias)
  - Tempo médio de incident response: < 15min (era 1h)

QUALIDADE
  - Cobertura de testes: > 80% (era 40%)
  - Bugs em produção: -60% (contract tests + review automático)
  - MTTR (Mean Time to Recovery): < 10min (rollback + postmortem)

CUSTO
  - Redução de custo cloud: 20-30% (FinOps recorrente)
  - Redução de retrabalho: 50% (review + testes automatizados)
  - Token cost: ~4-7x mais por sessão multi-agent (compensado por velocidade)
```

---

# APÊNDICE A — Referência Rápida de Todos os Comandos

```
DEV
  /dev-feature "desc"           Implementar feature completa
  /dev-bootstrap service        Bootstrap de microsserviço
  /full-bootstrap service aws   Bootstrap completo (3 packs)
  /dev-review path/             Code review multi-perspectiva
  /dev-refactor Class           Refatoração segura
  /dev-api resource             Design de API/OpenAPI

QA
  /qa-audit                     Auditoria de qualidade
  /qa-generate Class            Gerar testes (unit + integration)
  /qa-review path/              Review de testes existentes
  /qa-performance service       Load/stress test (Gatling/k6)
  /qa-flaky TestClass           Diagnosticar flaky test
  /qa-contract service          Testes de contrato (Pact/SCC)
  /qa-security service          Testes OWASP Top 10
  /qa-e2e "fluxo"              Testes end-to-end

DEVOPS
  /devops-provision svc aws     Provisionar infra completa
  /devops-pipeline svc          CI/CD pipeline
  /devops-observe svc           Observabilidade (métricas/alertas/logs)
  /devops-incident "desc"       Gestão de incidentes
  /devops-audit                 Auditoria de infra
  /devops-dr svc                Disaster recovery
  /devops-finops                Otimização de custos
  /devops-gitops svc            ArgoCD/GitOps
  /devops-cloud svc             Arquitetura AWS
  /devops-mesh svc              Service mesh (Istio/Linkerd)

DATA
  /data-optimize "query"        Otimização de query/índices
  /data-migrate "desc"          Migration SQL segura

MIGRATION
  /migration-discovery          Mapear bounded contexts
  /migration-prepare ctx        Preparar monólito (seams)
  /migration-extract ctx        Extrair microsserviço
  /migration-decommission ctx   Desativar legado

NOVOS (EXPANSÃO)
  /k8s-debug svc ns             Debug de pods/K8s
  /terraform-apply env comp     Apply seguro com gates
  /analyze-logs svc ns period   Análise de logs com correlação
  /design-service svc           Design completo de microsserviço
```

# APÊNDICE B — Cheat Sheet de Diagnóstico K8s

```bash
# Pod status
kubectl get pods -n NAMESPACE -l app=SERVICE -o wide

# Pod details (events, probes, resources)
kubectl describe pod POD_NAME -n NAMESPACE

# Logs atuais
kubectl logs -l app=SERVICE -n NAMESPACE --tail=100

# Logs da instância anterior (crashed)
kubectl logs POD_NAME -n NAMESPACE --previous

# Resource usage
kubectl top pods -n NAMESPACE -l app=SERVICE
kubectl top nodes

# Events do namespace
kubectl get events -n NAMESPACE --sort-by=.lastTimestamp | tail -20

# HPA status
kubectl get hpa -n NAMESPACE

# Network debug (run ephemeral container)
kubectl run debug --rm -it --image=nicolaka/netshoot -- bash

# Rollback
helm rollback SERVICE -n NAMESPACE
kubectl rollout undo deployment/SERVICE -n NAMESPACE
```

# APÊNDICE C — Cheat Sheet Terraform

```bash
# Workflow seguro
terraform init
terraform fmt -check
terraform validate
tflint --recursive
checkov -d . --compact
terraform plan -out=tfplan
infracost diff --path .
terraform apply tfplan

# State management
terraform state list
terraform state show RESOURCE
terraform state mv OLD NEW
terraform state rm RESOURCE
terraform import RESOURCE ID
terraform force-unlock LOCK_ID

# Debugging
TF_LOG=DEBUG terraform plan
terraform graph | dot -Tpng > graph.png
terraform console  # REPL interativo
```

---

**FIM DO MANUAL**

*Este documento é um sistema operacional pessoal vivo — deve ser atualizado conforme novos agents, commands e playbooks forem criados. A evolução é contínua.*
