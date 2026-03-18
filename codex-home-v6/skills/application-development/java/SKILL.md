# SKILL.md – JAVA & Spring Boot (Advanced Skill)

## Scope

This file defines how Codex CLI should behave when working with **Java and Spring Boot**, with a **production-oriented, enterprise-grade mindset**.

**Related agents:** `backend-dev` (Dev pack — implementation), `architect` (Dev pack — design), `dba` (Data pack — schema/migrations)

It applies to:
- Java application development (Java 8 through 25+ — adapts to project version)
- Spring Boot 2.x (Java 8/11/17) and Spring Boot 3.x (Java 17+)
- Hexagonal architecture (domain, application, ports, adapters) — for Java 17+ projects
- RESTful API design with Problem Details (RFC 9457) and OpenAPI
- Dependency management (Maven/Gradle)
- Testing (JUnit 5, AssertJ, Mockito, Testcontainers)
- Flyway migrations, JPA/Hibernate
- Kafka messaging (Outbox Pattern, DLQ, idempotency)
- Redis caching (cache-aside, TTL, stampede protection)
- Security, performance, observability, and maintainability
- Microservices and cloud-native patterns

**Version strategy:** Always use the most modern features available for the project's Java version. Prefer LTS versions (8, 11, 17, 21, 25) for production. Never use features above the project's target version.

Assume **code may run in production environments** unless explicitly stated otherwise.

---

## Core Principles

- **Hexagonal architecture:** Domain at center, frameworks at edges. Domain model has zero framework imports.
- **Convention over configuration:** Leverage Spring Boot defaults
- **Type safety first:** Use Java's strong typing — records, sealed classes, value objects
- **Immutability where possible:** Prefer `final`, records, and immutable collections
- **Fail fast:** Validate early, throw meaningful exceptions with stable error codes (`{DOMAIN}-{NNN}`)
- **SOLID principles:** Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Production-ready by default:** Health checks (liveness + readiness), metrics (Prometheus), structured logging (JSON), security

### Hexagonal Package Structure
```
com.{org}.{service}/
  domain/model/          → Entities, Value Objects, Aggregates (ZERO framework deps)
  domain/port/in/        → Use case interfaces (inbound)
  domain/port/out/       → Repository, Publisher, Client interfaces (outbound)
  domain/exception/      → Domain exceptions with error codes
  application/usecase/   → Use case implementations
  application/service/   → Application services, orchestration
  adapter/in/web/        → REST Controllers + DTOs ({Entity}Request, {Entity}Response)
  adapter/in/messaging/  → Kafka Consumers
  adapter/out/persistence/ → JPA Entities + Repositories + Mappers
  adapter/out/messaging/ → Kafka Producers (Outbox Pattern)
  adapter/out/http/      → HTTP Clients (Resilience4j circuit breaker)
  config/                → Spring configuration, beans, security
```

---

## Java Version & Language Features

### Version Strategy

Três versões importam. O resto é stepping stone.

| Version | Status | Spring Boot | Postura |
|---------|--------|-------------|---------|
| **Java 8** | Legacy (EOL) | 2.x only | Manutenção de legado. Não iniciar projetos novos. Planejar migração para 21. |
| **Java 21** | LTS (recomendado) | 3.2+ | **Default para projetos novos e em migração.** Melhor equilíbrio features/estabilidade. |
| **Java 25+** | LTS (latest) | 3.4+ | Greenfield cutting-edge. Structured concurrency e scoped values estáveis. |

**Regra:** Detectar versão do projeto via `pom.xml` (`<java.version>`) ou `build.gradle` (`sourceCompatibility`). Usar apenas features disponíveis naquela versão. Sugerir upgrade quando benéfico, nunca quebrar compatibilidade silenciosamente.

**Spring Boot determina o piso:**
- Spring Boot 2.7.x → Java 8, 11 ou 17
- Spring Boot 3.0+ → Java 17 mínimo
- Spring Boot 3.2+ → Java 21 recomendado (virtual threads)
- Spring Boot 3.4+ → Java 21+ com compatibilidade total com 25

---

### Java 8 — Legacy Baseline

O mínimo em codebases existentes. Lambdas e streams foram a revolução.

```java
// Lambdas e Streams (8)
List<String> activeNames = users.stream()
    .filter(u -> u.isActive())
    .map(User::getName)
    .sorted()
    .collect(Collectors.toList());

// Optional (8)
Optional<User> user = repository.findById(id);
user.ifPresent(u -> notify(u));
String name = user.map(User::getName).orElse("Unknown");

// CompletableFuture (8)
CompletableFuture.supplyAsync(() -> fetchOrder(id))
    .thenApply(order -> enrichWithPayment(order))
    .thenAccept(enriched -> cache.put(enriched))
    .exceptionally(ex -> { log.error("Failed", ex); return null; });

// Method references (8)
list.forEach(System.out::println);

// Default methods em interfaces (8)
public interface Auditable {
    default Instant getCreatedAt() { return Instant.now(); }
}

// java.time API (8) — SEMPRE em vez de Date/Calendar
Instant instant = Instant.now();
LocalDate today = LocalDate.now();
ZonedDateTime zoned = ZonedDateTime.now(ZoneId.of("America/Recife"));
Duration timeout = Duration.ofSeconds(30);
```

#### Anti-patterns do Java 8 → O que usar ao migrar

| Java 8 (legado) | Java 21+ (moderno) | Por quê |
|------------------|--------------------|---------|
| `new Date()` | `Instant.now()` | Imutável, thread-safe |
| `SimpleDateFormat` | `DateTimeFormatter` | Thread-safe |
| `Collectors.toList()` | `.toList()` | Mais limpo, lista imutável |
| Anonymous class SAM | Lambda | Menos verboso |
| `instanceof` + cast | `if (x instanceof Foo f)` | Sem cast separado |
| Classe + getters + equals | `record` | Imutável, tudo grátis |
| Herança aberta | `sealed` | Compilador garante exhaustiveness |
| `switch` com `break` | Switch expression | Retorna valor, sem fall-through |
| `"l1\n" + "l2"` | `"""text block"""` | Legibilidade |
| Thread pool para I/O | Virtual threads | 1M threads leves |
| `ThreadLocal` | `ScopedValue` (25) | Seguro com virtual threads |

#### Padrões comuns em Java 8

```java
// DTO verboso — vira record na migração
public class OrderDTO {
    private final UUID id;
    private final String status;
    private final BigDecimal total;
    public OrderDTO(UUID id, String status, BigDecimal total) {
        this.id = id; this.status = status; this.total = total;
    }
    public UUID getId() { return id; }
    public String getStatus() { return status; }
    public BigDecimal getTotal() { return total; }
    @Override public boolean equals(Object o) { /* 15 linhas */ }
    @Override public int hashCode() { return Objects.hash(id, status, total); }
}

// Switch com break
String label;
switch (status) {
    case CREATED: label = "Novo"; break;
    case PAID:    label = "Pago"; break;
    default:      label = "Desconhecido"; break;
}
```

---

### Java 21 — Recommended Default

Tudo do Java 8 + records, sealed classes, pattern matching, text blocks, virtual threads. O maior salto de produtividade desde Java 8.

```java
// Records — substitui DTOs verbosos
public record OrderResponse(UUID id, String status, BigDecimal total,
                            List<OrderItemResponse> items, Instant createdAt) {}
// Gera: construtor, getters (id(), status()...), equals, hashCode, toString

// Record com validação
public record Money(BigDecimal amount, String currency) {
    public Money {
        Objects.requireNonNull(amount, "Amount required");
        Objects.requireNonNull(currency, "Currency required");
        if (amount.compareTo(BigDecimal.ZERO) < 0)
            throw new IllegalArgumentException("Amount must be non-negative");
    }
    public static final Money ZERO = new Money(BigDecimal.ZERO, "BRL");
    public Money add(Money other) {
        if (!this.currency.equals(other.currency))
            throw new IllegalArgumentException("Currency mismatch");
        return new Money(this.amount.add(other.amount), this.currency);
    }
}

// Sealed classes — restringir hierarquia, exhaustive no compilador
public sealed interface PaymentResult
    permits PaymentSuccess, PaymentFailure, PaymentPending {}
public record PaymentSuccess(String transactionId, Instant paidAt) implements PaymentResult {}
public record PaymentFailure(String errorCode, String message) implements PaymentResult {}
public record PaymentPending(String redirectUrl) implements PaymentResult {}

// Pattern matching em switch — exhaustivo, sem cast, sem break
String handle(PaymentResult result) {
    return switch (result) {
        case PaymentSuccess s  -> "Pago: " + s.transactionId();
        case PaymentFailure f  -> "Erro: " + f.errorCode() + " — " + f.message();
        case PaymentPending p  -> "Redirecionar: " + p.redirectUrl();
    };
}

// Pattern matching com guards
String classify(Order order) {
    return switch (order) {
        case Order o when o.total().amount().compareTo(new BigDecimal("1000")) > 0 -> "Alto valor";
        case Order o when o.items().isEmpty() -> "Pedido vazio";
        case Order o -> "Padrão: " + o.id();
    };
}

// Record patterns — destructuring
if (event instanceof OrderCreatedEvent(var orderId, var customerId, var items)) {
    log.info("Pedido {} para cliente {} com {} itens", orderId, customerId, items.size());
}

// Text blocks — SQL, JSON legíveis
String sql = """
    SELECT o.id, o.status, o.total_amount
    FROM orders o
    WHERE o.tenant_id = :tenantId AND o.status = :status
    ORDER BY o.created_at DESC
    """;

// Virtual threads — threads leves para I/O-bound
// application.yml: spring.threads.virtual.enabled: true
// Zero mudança de código — Tomcat usa virtual threads automaticamente

// Uso manual:
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    var futures = orders.stream()
        .map(order -> executor.submit(() -> processOrder(order)))
        .toList();
    futures.forEach(f -> { try { f.get(10, TimeUnit.SECONDS); } catch (Exception e) { handle(e); } });
}

// Sequenced collections
SequencedCollection<Order> orders = getRecentOrders();
Order first = orders.getFirst();
Order last = orders.getLast();

// Collection factories, var, Stream.toList(), String enhancements
var statuses = List.of("CREATED", "PAID", "SHIPPED");
var names = users.stream().map(User::getName).toList();
"  hello  ".strip();  // "hello"
"  ".isBlank();       // true
"ha".repeat(3);       // "hahaha"

// HttpClient built-in
var client = HttpClient.newHttpClient();
var request = HttpRequest.newBuilder()
    .uri(URI.create("https://api.example.com/orders"))
    .header("Authorization", "Bearer " + token)
    .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
    .build();
var response = client.send(request, HttpResponse.BodyHandlers.ofString());
```

**Impacto virtual threads:** Com `spring.threads.virtual.enabled=true`, serviços I/O-heavy podem precisar de menos réplicas. Reavaliar HPA e resource requests após profiling.

---

### Java 25+ — Cutting Edge

Tudo do Java 21 + structured concurrency, scoped values, stream gatherers, constructor bodies flexíveis, unnamed variables — todos estabilizados.

```java
// Structured concurrency — gerenciar virtual threads com segurança
// Se qualquer subtask falha, TODAS são canceladas. Zero thread leak.
OrderComplete fetchComplete(UUID orderId) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        var order    = scope.fork(() -> orderService.getOrder(orderId));
        var payment  = scope.fork(() -> paymentService.getStatus(orderId));
        var shipping = scope.fork(() -> shippingService.getTracking(orderId));
        scope.join().throwIfFailed();
        return new OrderComplete(order.get(), payment.get(), shipping.get());
    }
}

// ShutdownOnSuccess — primeiro que retornar, cancela o resto
String fetchFastest(List<URI> mirrors) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnSuccess<String>()) {
        for (URI mirror : mirrors)
            scope.fork(() -> httpClient.send(
                HttpRequest.newBuilder(mirror).build(),
                HttpResponse.BodyHandlers.ofString()).body());
        scope.join();
        return scope.result();
    }
}

// Scoped values — substitui ThreadLocal, seguro com virtual threads
// ThreadLocal tem memory leak com VT; ScopedValue não.
private static final ScopedValue<TenantId> TENANT = ScopedValue.newInstance();
private static final ScopedValue<String> CORRELATION_ID = ScopedValue.newInstance();

public void processRequest(TenantId tenant, String correlationId) {
    ScopedValue.where(TENANT, tenant).where(CORRELATION_ID, correlationId)
        .run(() -> orderService.createOrder(command));
    // todo código no escopo vê TENANT.get() e CORRELATION_ID.get()
    // incluindo virtual threads. Imutável. Auto-cleanup ao sair.
}

// Stream gatherers — operações intermediárias custom
List<List<Order>> batches = orders.stream()
    .gather(Gatherers.windowFixed(100)).toList();

List<List<Double>> windows = prices.stream()
    .gather(Gatherers.windowSliding(5)).toList();

// Flexible constructor bodies — validar antes de super()
public class ValidatedOrder extends Order {
    public ValidatedOrder(TenantId tenantId, List<OrderItem> items) {
        if (items == null || items.isEmpty())
            throw new ValidationException("ORDER-001", "Items required");
        super(tenantId, items);  // validação ANTES — finalmente permitido
    }
}

// Unnamed variables — ignorar explicitamente
try { riskyOperation(); }
catch (SpecificException _) { return fallback(); }

orders.forEach(_ -> count.incrementAndGet());

if (event instanceof OrderCreatedEvent(var orderId, _, _))
    log.info("Order created: {}", orderId);

// Primitive patterns
String classify(int qty) {
    return switch (qty) {
        case int q when q <= 0  -> "inválido";
        case int q when q < 10  -> "pequeno";
        case int q when q < 100 -> "médio";
        case int q              -> "grande";
    };
}
```

#### Patterns Java 25+ para Microsserviços

```java
// Multi-tenancy com ScopedValue (substitui ThreadLocal + Filter)
@Component
public class TenantFilter implements Filter {
    public static final ScopedValue<TenantId> CURRENT_TENANT = ScopedValue.newInstance();
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) {
        TenantId tenant = TenantId.of(((HttpServletRequest) req).getHeader("X-Tenant-Id"));
        ScopedValue.where(CURRENT_TENANT, tenant)
            .call(() -> { chain.doFilter(req, res); return null; });
    }
}
// Qualquer service na chain: TenantFilter.CURRENT_TENANT.get()

// Fan-out para múltiplos microsserviços
public OrderEnriched enrichOrder(Order order) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        var customer  = scope.fork(() -> customerClient.get(order.customerId()));
        var inventory = scope.fork(() -> inventoryClient.checkStock(order.items()));
        var pricing   = scope.fork(() -> pricingClient.calculate(order.items()));
        scope.join().throwIfFailed();
        return new OrderEnriched(order, customer.get(), inventory.get(), pricing.get());
    }
    // customerClient timeout → inventory e pricing cancelados automaticamente
}
```

---

### Migration Cheat Sheet

| De → Para | O que muda | Risco | Esforço |
|-----------|-----------|-------|---------|
| **8 → 21** | `javax.*` → `jakarta.*`, Spring Boot 2→3, records, sealed, virtual threads | **Alto** (SB migration é o trabalho) | L-XL |
| **21 → 25+** | Structured concurrency, scoped values, gatherers, unnamed vars | **Baixo** (aditivo) | S |

**Migração 8 → 21:**
1. Atualizar JDK para 21
2. Atualizar Spring Boot 2.7 → 3.x (`javax` → `jakarta`)
3. Atualizar dependências
4. Testar: Flyway, Testcontainers, integração
5. Modernizar incrementalmente (records, text blocks, switch)
6. Habilitar virtual threads
7. Reprofilar resources

### Feature Decision Matrix

| Necessidade | Java 8 | Java 21 | Java 25+ |
|-------------|--------|---------|----------|
| DTO / Value Object | Classe + Lombok | `record` | `record` |
| Null handling | `if (x != null)` | `Optional` + pattern matching | idem |
| String multiline | `"l1\n" + "l2"` | `"""text block"""` | idem |
| Type check + cast | `instanceof` + cast | `switch` com patterns | patterns + guards |
| Restringir hierarquia | docs only | `sealed` | `sealed` |
| Concurrency I/O | Thread pool | Virtual threads | Structured concurrency |
| Contexto por request | `ThreadLocal` | `ThreadLocal` (cuidado com VT) | `ScopedValue` |
| Collection factory | `Arrays.asList()` | `List.of()` | `List.of()` |
| HTTP client | Apache | `HttpClient` built-in | idem |
| Stream → List | `Collectors.toList()` | `.toList()` | idem |
| Stream windowing | Manual | Manual | `Gatherers.windowFixed()` |
| Ignorar variável | `@SuppressWarnings` | idem | `_` unnamed |


## Code Style Standards

### Naming Conventions
- **Classes:** PascalCase (`UserService`, `OrderController`)
- **Methods/Variables:** camelCase (`getUserById`, `isValid`)
- **Constants:** UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`)
- **Packages:** lowercase, no underscores (`com.example.service`)

### Formatting
- **Indentation:** 4 spaces (never tabs)
- **Line length:** 120 characters max
- **Braces:** Always use braces, even for single-line blocks
- **Imports:** No wildcards (`import java.util.*` ❌), explicit imports only

### Code Organization
```
src/
├── main/
│   ├── java/
│   │   └── com/example/app/
│   │       ├── controller/    # REST endpoints (thin layer)
│   │       ├── service/       # Business logic
│   │       ├── repository/    # Data access (Spring Data JPA)
│   │       ├── model/         # Domain entities
│   │       ├── dto/           # Data Transfer Objects (records)
│   │       ├── mapper/        # Entity ↔ DTO conversion (MapStruct)
│   │       ├── config/        # Spring configuration classes
│   │       ├── exception/     # Custom exceptions and handlers
│   │       └── util/          # Utility classes
│   └── resources/
│       ├── application.yml    # Spring Boot configuration
│       ├── application-dev.yml
│       ├── application-prod.yml
│       └── db/migration/      # Flyway/Liquibase migrations
└── test/
    └── java/
        └── com/example/app/
            ├── controller/    # Controller tests (MockMvc)
            ├── service/       # Service unit tests
            ├── repository/    # Repository integration tests
            └── integration/   # Full integration tests (TestContainers)
```

---

## Spring Boot Best Practices

### Dependency Injection
- **Prefer constructor injection** (immutable, testable, clear dependencies)
- Avoid `@Autowired` on fields (hard to test, mutable)
- Use `@RequiredArgsConstructor` (Lombok) for constructor injection

```java
// ✅ Good: Constructor injection
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public User createUser(UserDTO dto) {
        // ...
    }
}

// ❌ Bad: Field injection
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
}
```

### Configuration
- **Use `application.yml`** over `application.properties` (more readable)
- **Profile-specific configs:** `application-{profile}.yml`
- **Type-safe config:** Use `@ConfigurationProperties` with records

```java
@ConfigurationProperties(prefix = "app.security")
public record SecurityConfig(
    String jwtSecret,
    long jwtExpirationMs,
    int maxLoginAttempts
) {}
```

### Exception Handling
- **Centralized error handling:** `@RestControllerAdvice`
- **Custom exceptions:** Extend `RuntimeException` for business exceptions
- **Standard responses:** Use RFC 7807 Problem Details or custom error DTO

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        // Log full stack trace
        log.error("Unexpected error", ex);

        // Return sanitized error to client
        ErrorResponse error = new ErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "An unexpected error occurred",
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
```

---

## REST API Design

### Controller Layer
- **Thin controllers:** Delegate to services, no business logic
- **Use DTOs:** Never expose entities directly
- **Validation:** Use Bean Validation (`@Valid`, `@NotNull`, `@Size`, etc.)
- **HTTP methods:** Correct semantics (GET, POST, PUT, PATCH, DELETE)

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
        UserDTO user = userService.findById(id);
        return ResponseEntity.ok(user);
    }

    @PostMapping
    public ResponseEntity<UserDTO> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserDTO user = userService.createUser(request);
        URI location = ServletUriComponentsBuilder
            .fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(user.id())
            .toUri();
        return ResponseEntity.created(location).body(user);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        UserDTO user = userService.updateUser(id, request);
        return ResponseEntity.ok(user);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
    }
}
```

### Response Standards
- **Success:** 200 OK (GET, PUT), 201 Created (POST), 204 No Content (DELETE)
- **Client errors:** 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found
- **Server errors:** 500 Internal Server Error
- **Include Location header** for 201 Created

---

## Data Access Layer

### Spring Data JPA
- **Prefer derived queries** for simple queries
- **Use `@Query`** for complex queries
- **Projections:** Return only needed fields (DTOs, interfaces)
- **Pagination:** Use `Pageable` and `Page<T>` for large datasets
- **Avoid N+1 queries:** Use `@EntityGraph` or `JOIN FETCH`

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.status = :status AND u.createdAt > :date")
    List<User> findActiveUsersSince(@Param("status") UserStatus status, @Param("date") LocalDateTime date);

    @EntityGraph(attributePaths = {"roles", "profile"})
    Optional<User> findWithRolesById(Long id);

    Page<User> findByNameContaining(String name, Pageable pageable);
}
```

### Transactions
- **Use `@Transactional`** on service layer methods
- **Read-only transactions:** `@Transactional(readOnly = true)` for queries
- **Rollback:** Automatic for unchecked exceptions, explicit for checked

```java
@Service
@RequiredArgsConstructor
@Transactional
public class OrderService {

    private final OrderRepository orderRepository;
    private final InventoryService inventoryService;

    public Order createOrder(CreateOrderRequest request) {
        // Validate inventory
        inventoryService.reserve(request.items());

        // Create order
        Order order = new Order(request);
        return orderRepository.save(order);

        // Auto-rollback if any exception occurs
    }

    @Transactional(readOnly = true)
    public List<OrderDTO> findUserOrders(Long userId) {
        return orderRepository.findByUserId(userId)
            .stream()
            .map(OrderMapper::toDTO)
            .toList();
    }
}
```

---

## Security

### Spring Security
- **Prefer JWT** for stateless APIs
- **Role-based access control (RBAC):** Use `@PreAuthorize`, `@Secured`
- **Password encoding:** Use `BCryptPasswordEncoder`
- **CSRF protection:** Disable for stateless APIs, enable for session-based
- **CORS:** Configure explicitly, avoid `allowedOrigins("*")` in production

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### Input Validation
- **Bean Validation:** `@NotNull`, `@NotBlank`, `@Size`, `@Email`, `@Pattern`
- **Custom validators:** Implement `ConstraintValidator` for complex rules
- **Sanitization:** Validate and sanitize all user input

```java
public record CreateUserRequest(
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    String name,

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email,

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    @Pattern(regexp = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).*$",
             message = "Password must contain uppercase, lowercase, and digit")
    String password
) {}
```

---

## Testing

### Unit Tests (JUnit 5 + Mockito)
- **Test business logic:** Focus on service layer
- **Mock dependencies:** Use `@Mock` and `@InjectMocks`
- **Naming:** `methodName_condition_expectedResult`
- **Coverage:** Aim for 80%+ on service and util classes

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Test
    void createUser_validInput_returnsUserDTO() {
        // Arrange
        CreateUserRequest request = new CreateUserRequest("John", "john@example.com", "Pass123");
        User savedUser = new User(1L, "John", "john@example.com", "encoded");

        when(passwordEncoder.encode(request.password())).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        // Act
        UserDTO result = userService.createUser(request);

        // Assert
        assertNotNull(result);
        assertEquals("John", result.name());
        assertEquals("john@example.com", result.email());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void findById_nonExistentUser_throwsException() {
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> userService.findById(999L));
    }
}
```

### Integration Tests (Spring Boot Test)
- **Use `@SpringBootTest`** for full context
- **TestContainers:** Real database for repository tests
- **MockMvc:** Test REST endpoints without HTTP server

```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Test
    void createUser_validRequest_returns201() throws Exception {
        CreateUserRequest request = new CreateUserRequest("Jane", "jane@example.com", "Pass123");

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Jane"))
            .andExpect(jsonPath("$.email").value("jane@example.com"))
            .andExpect(header().exists("Location"));
    }
}
```

---

## Performance & Optimization

### Database
- **Connection pooling:** Use HikariCP (Spring Boot default)
- **Indexes:** Add indexes for frequently queried columns
- **Lazy loading:** Be aware of N+1 queries, use eager fetching when needed
- **Caching:** Use Spring Cache abstraction (`@Cacheable`, `@CacheEvict`)

### JVM Tuning
- **Heap size:** Set `-Xms` and `-Xmx` to same value (avoid resizing)
- **GC:** Use G1GC for most cases (Java 9+ default)
- **Monitor:** Use JMX, Micrometer, or APM tools

### Asynchronous Processing
- **`@Async`:** For fire-and-forget tasks
- **CompletableFuture:** For composable async operations
- **Virtual threads:** Consider for IO-bound tasks (Java 21+)

```java
@Service
public class EmailService {

    @Async
    public CompletableFuture<Void> sendWelcomeEmail(String email) {
        // Simulate email sending
        log.info("Sending email to {}", email);
        return CompletableFuture.completedFuture(null);
    }
}
```

---

## Logging & Observability

### Logging
- **Use SLF4J** with Logback (Spring Boot default)
- **Levels:** ERROR (fix immediately), WARN (investigate), INFO (important events), DEBUG (dev only)
- **Structured logging:** Use JSON format in production
- **Correlation IDs:** Track requests across services

```java
@Slf4j
@Service
public class OrderService {

    public Order createOrder(CreateOrderRequest request) {
        log.info("Creating order for user: {}", request.userId());

        try {
            Order order = processOrder(request);
            log.info("Order created successfully: {}", order.getId());
            return order;
        } catch (Exception e) {
            log.error("Failed to create order for user: {}", request.userId(), e);
            throw e;
        }
    }
}
```

### Actuator
- **Enable Spring Boot Actuator:** `/actuator/health`, `/actuator/metrics`
- **Custom health indicators:** Implement `HealthIndicator`
- **Secure endpoints:** Don't expose all actuator endpoints publicly

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when-authorized
```

---

## Build Tools

### Maven
```xml
<properties>
    <java.version>17</java.version>
    <spring-boot.version>3.2.0</spring-boot.version>
</properties>

<dependencies>
    <!-- Spring Boot Starters -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>

    <!-- Testing -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Gradle (Kotlin DSL)
```kotlin
plugins {
    java
    id("org.springframework.boot") version "3.2.0"
    id("io.spring.dependency-management") version "1.1.4"
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}
```

---

## Anti-Patterns to Avoid

- **God classes:** Classes with too many responsibilities
- **Anemic domain model:** Entities with no behavior, only getters/setters
- **Service layer bypass:** Controllers calling repositories directly
- **Checked exceptions:** Prefer unchecked exceptions for business logic
- **Static utility classes:** Hard to test, prefer dependency injection
- **Mutable DTOs:** Use records or immutable classes
- **Hardcoded values:** Use configuration properties
- **Ignoring exceptions:** Always log or rethrow

---

## Code Quality Tools

- **Formatter:** Use IntelliJ formatter or Google Java Format
- **Linter:** Checkstyle, PMD, SpotBugs
- **Coverage:** JaCoCo (aim for 80%+, 100% for security/auth paths)
- **Static analysis:** SonarQube
- **Dependencies:** OWASP Dependency-Check
- **Architecture tests:** ArchUnit (enforce hexagonal boundaries)
- **Mutation testing:** Pitest (80%+ mutation score for domain)

---

## Communication Style (Java Context)

- Be concise by default
- Expand when:
  - Security, performance, or thread-safety is involved
  - Design patterns or architecture decisions are needed
- Always explain:
  - Trade-offs between approaches
  - Why Spring Boot conventions are recommended
- Think like a **Senior Java Engineer**

---

## Expected Output Quality

Responses should:
- Follow hexagonal architecture (domain → application → adapters) with zero framework imports in domain
- Use Java 21+ modern features (records, sealed classes, pattern matching, virtual threads) when they improve clarity
- Include Problem Details (RFC 9457) for error responses
- Include Bean Validation annotations on all DTOs
- Produce Flyway migrations with `V{n}__{description}.sql` naming
- Separate JPA entities from domain entities (mapper between layers)
- Name Kafka topics as `{domain}.{entity}.{action}.v{n}`
- Name error codes as `{DOMAIN}-{NNN}` (stable, documented)
- Include Testcontainers for integration tests, not H2
- Be production-ready: probes, graceful shutdown, structured logs

---

**Skill type:** Passive
**Related agents:** `backend-dev` (Dev pack), `architect` (Dev pack), `refactoring-engineer` (Dev pack), `backend-engineer` (Migration pack), `dba` (Data pack)
**Applies with:** Root `AGENTS.md`
**Pairs well with:** `docker`, `kubernetes`, `ci-cd`, `security`, `observability`
**Override:** Project-level `AGENTS.md` may refine behavior
