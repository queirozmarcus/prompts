# CLAUDE.md – JAVA & Spring Boot (Advanced Skill)

## Scope

This file defines how Claude Code should behave when working with **Java and Spring Boot**, with a **production-oriented, enterprise-grade mindset**.

It applies to:
- Java application development (Java 17+)
- Spring Boot and Spring ecosystem
- RESTful API design
- Dependency management (Maven/Gradle)
- Testing (JUnit, Mockito, TestContainers)
- Security, performance, and maintainability
- Microservices and cloud-native patterns

Assume **code may run in production environments** unless explicitly stated otherwise.

---

## Core Principles

- **Convention over configuration:** Leverage Spring Boot defaults
- **Type safety first:** Use Java's strong typing to your advantage
- **Immutability where possible:** Prefer `final`, records, and immutable collections
- **Fail fast:** Validate early, throw meaningful exceptions
- **SOLID principles:** Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Production-ready by default:** Health checks, metrics, logging, security

---

## Java Version & Language Features

### Version
- **Target:** Java 17 LTS or Java 21 LTS (prefer LTS versions)
- **Avoid:** Java 8 patterns (use modern features)

### Modern Features to Use
- **Records** (Java 14+): For DTOs and immutable data carriers
- **Switch expressions** (Java 14+): More concise and type-safe
- **Text blocks** (Java 15+): Multi-line strings (SQL, JSON, HTML)
- **Pattern matching** (Java 16+): `instanceof` with pattern variables
- **Sealed classes** (Java 17+): Restrict inheritance hierarchies
- **Virtual threads** (Java 21+): Lightweight concurrency (Project Loom)

### Examples
```java
// Records for DTOs
public record UserDTO(Long id, String name, String email) {}

// Switch expressions
String result = switch (status) {
    case PENDING -> "Waiting";
    case APPROVED -> "Confirmed";
    case REJECTED -> "Denied";
    default -> throw new IllegalArgumentException("Unknown status");
};

// Text blocks
String json = """
    {
        "name": "John",
        "age": 30
    }
    """;

// Pattern matching
if (obj instanceof String s) {
    System.out.println(s.toUpperCase());
}
```

---

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
- **Coverage:** JaCoCo (aim for 80%+)
- **Static analysis:** SonarQube
- **Dependencies:** OWASP Dependency-Check

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

**Skill type:** Passive
**Applies with:** Global `CLAUDE.md`
**Pairs well with:** `docker`, `kubernetes`, `ci-cd`, `security`, `observability`
**Override:** Project-level `CLAUDE.md` may refine behavior
