# SKILL.md – Testing (Advanced Skill)

## Scope

Best practices for software testing in Java/Spring Boot, Node.js, and Python projects. Covers test strategy, test pyramid, naming, patterns, frameworks, quality gates, and anti-patterns. This skill provides **passive context** for any work involving tests — complementing the QA pack agents when they are invoked, and providing baseline guidance when they are not.

**Related agents:** `qa-lead`, `qa-engineer` (Migration pack) (QA pack — strategy), `unit-test-engineer` (QA pack), `integration-test-engineer` (QA pack), `contract-test-engineer` (QA pack), `performance-engineer` (QA pack), `e2e-test-engineer` (QA pack), `test-automation-engineer` (QA pack), `security-test-engineer` (QA pack)

**Related commands:** `/qa-audit`, `/qa-generate`, `/qa-review`, `/qa-performance`, `/qa-flaky`, `/qa-contract`, `/qa-e2e`

## Core Principles

- **Test behavior, not implementation** — tests are documentation of what the system does, not how
- **Test pyramid proportions matter** — more unit tests, fewer E2E; inverting the pyramid is expensive and fragile
- **Fast, deterministic, independent** — every test runs in any order, any environment, with the same result
- **Real infrastructure over mocks when possible** — Testcontainers > H2, real Kafka > mock; mocks for external services only
- **Tests accompany code** — no feature merges without tests; no refactoring without safety net
- **Flaky tests are bugs** — fix immediately; a flaky test is worse than no test (false confidence)
- **Coverage is a guide, not a goal** — 80% coverage with meaningful tests > 95% coverage with trivial assertions

## Test Pyramid

```
         /  E2E / Smoke  \         ~5-10%  — critical business flows only
        /------------------\
       / Contract (Pact/SCC)\      ~5%     — API + event schemas between services
      /----------------------\
     /  Integration            \   ~20%    — real DB, Kafka, Redis via Testcontainers
    /--------------------------\
   /    Unit                     \ ~65-70% — domain model, use cases, validators
  /______________________________\
```

**Signs of an inverted pyramid (problems):**
- More E2E tests than unit tests → slow, flaky, expensive
- More mocks than real assertions → testing the mock, not the code
- Zero integration tests → infrastructure untested
- Zero contract tests → services break each other silently

## Naming Conventions

### Java (JUnit 5)
```java
// Pattern: should{Result}_when{Condition}
@Test void shouldReturnError_whenOrderHasNoItems() {}
@Test void shouldApplyDiscount_whenTotalExceedsThreshold() {}
@Test void shouldNotAllowCancellation_whenAlreadyShipped() {}

// Class names
CreateOrderUseCaseTest           // unit
OrderRepositoryIntegrationTest   // integration
OrderApiContractTest             // contract
OrderPaymentFlowE2ETest          // e2e
OrderCreationPerfTest            // performance
OrderApiSecurityTest             // security
```

### JavaScript / TypeScript (Jest / Vitest)
```javascript
test('should return error when input is invalid', () => {});
describe('OrderService', () => {
  it('should calculate total with discount for premium customers', () => {});
});
```

### Python (pytest)
```python
def test_should_return_error_when_order_has_no_items():
    pass

class TestOrderService:
    def test_should_apply_discount_when_total_exceeds_threshold(self):
        pass
```

## Test Patterns

### Given-When-Then (Arrange-Act-Assert)
```java
@Test
@DisplayName("Should calculate total with discount when order has 5+ items")
void shouldCalculateTotalWithDiscount_whenFiveOrMoreItems() {
    // Given (Arrange) — setup preconditions
    var items = List.of(
        new OrderItem("prod-1", 2, Money.of(10.00)),
        new OrderItem("prod-2", 3, Money.of(20.00))
    );
    var order = Order.create(TENANT_ID, CUSTOMER_ID, items);

    // When (Act) — execute the behavior
    var total = order.calculateTotal();

    // Then (Assert) — verify the outcome
    assertThat(total).isEqualTo(Money.of(76.00)); // 80 - 5% discount
}
```

### When to Mock vs When to Use Real

| Component | Unit Test | Integration Test |
|-----------|-----------|-----------------|
| Domain model | ❌ Never mock — test real logic | N/A |
| Value objects | ❌ Never mock — immutable, pure | N/A |
| Use case dependencies (ports out) | ✅ Mock the interface | ❌ Use Testcontainers |
| Repository | ✅ Mock interface | ❌ Real DB (Testcontainers) |
| HTTP client (external) | ✅ Mock or WireMock | ✅ WireMock |
| Kafka producer/consumer | ✅ Mock in unit | ❌ Real Kafka (Testcontainers) |
| Redis cache | ✅ Mock in unit | ❌ Real Redis (Testcontainers) |
| Clock / time | ✅ `Clock.fixed()` | ✅ `Clock.fixed()` |

**Rule of thumb:** Mock at boundaries (ports out). Never mock domain logic.

### Testcontainers Base (Java)
```java
@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
public abstract class BaseIntegrationTest {
    @Container static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");
    @Container static KafkaContainer kafka =
        new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.6.0"));
    @Container static GenericContainer<?> redis =
        new GenericContainer<>("redis:7-alpine").withExposedPorts(6379);

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", postgres::getJdbcUrl);
        r.add("spring.datasource.username", postgres::getUsername);
        r.add("spring.datasource.password", postgres::getPassword);
        r.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        r.add("spring.data.redis.host", redis::getHost);
        r.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
    }
}
```

### Contract Testing
```yaml
# Spring Cloud Contract (provider side)
# src/test/resources/contracts/order/get_order_by_id.yml
request:
  method: GET
  url: /api/v1/orders/550e8400-e29b-41d4-a716-446655440000
response:
  status: 200
  body:
    id: "550e8400-e29b-41d4-a716-446655440000"
    status: "CREATED"
```

**Rule:** Contract tests run in CI. Failure blocks deploy. No exceptions.

### Async Testing (Kafka consumers)
```java
// NEVER use Thread.sleep — use Awaitility
await().atMost(Duration.ofSeconds(10))
    .pollInterval(Duration.ofMillis(200))
    .untilAsserted(() ->
        assertThat(repository.findById(id)).isPresent()
    );
```

## Quality Gates

```
Unit tests:        >80% coverage on domain + application, 0 failures
Integration:       Critical flows covered, 0 failures
Contract:          100% compliance, blocks deploy on failure
Performance:       p99 < SLO, no regression vs baseline
E2E:               Happy paths + critical error paths
Security:          0 critical/high vulnerabilities
Sonar:             0 critical, 0 blocker, debt ratio < 5%
Mutation (Pitest): >80% mutation score on domain + application
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Mock everything | Tests pass but code is broken | Mock only ports out; test domain with real logic |
| Test without assertion | Compiles, runs, validates nothing | Every test MUST have `assertThat` / `assertEquals` |
| `Thread.sleep(2000)` | Flaky, slow | Use `Awaitility` for async |
| `@SpringBootTest` for unit test | 30s startup for pure logic test | Use `@ExtendWith(MockitoExtension.class)` |
| Test depends on other test | Order-dependent execution | Cleanup in `@AfterEach`, no shared state |
| Test getters/setters | False coverage, zero value | Test behavior, not accessors |
| `@DirtiesContext` | Reloads entire Spring context | Cleanup data instead |
| H2 for integration | Different SQL dialect, false positives | Testcontainers with real DB |
| Ignoring flaky test | Erodes trust in suite | Fix immediately or delete |
| 100% coverage as goal | Trivial tests, false confidence | Cover risk, not lines |

## Communication Style

- Be specific about which test type to use for each scenario
- Explain why a pattern is preferred (not just "use X")
- Show executable code, not descriptions
- Flag when a test is testing the mock instead of the code
- Recommend proportional coverage — more tests where risk is higher

## Expected Output Quality

Responses should:
- Include complete, compilable test code with imports and fixtures
- Follow Given-When-Then structure with `@DisplayName`
- Use AssertJ (`assertThat`) over JUnit assertions for readability
- Include Testcontainers for integration tests, never H2
- Cover happy path + edge cases + error paths proportional to risk
- Name tests descriptively: `shouldX_whenY`
- Include cleanup (`@AfterEach`) when tests mutate state

---

**Skill type:** Passive
**Related agents:** `qa-lead`, `qa-engineer` (Migration pack), `unit-test-engineer`, `integration-test-engineer`, `contract-test-engineer`, `performance-engineer`, `e2e-test-engineer`, `test-automation-engineer`, `security-test-engineer` (QA pack)
**Applies with:** java, nodejs, python, ci-cd, docker
**Override:** Project-level `AGENTS.md` may refine coverage targets and framework choices
