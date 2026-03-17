# CLAUDE.md – NODE.JS Skill

## Scope
This skill defines best practices and behavior for **Node.js/Express** backend development.

## Core Principles
- **Production-first mindset:** Code should be production-ready
- **Security by default:** Validate input, sanitize output, protect routes
- **Async/await over callbacks:** Modern async patterns, never callback hell
- **Error handling:** Centralized error middleware, structured error responses
- **Dependency injection:** Testable, decoupled components
- **Type safety:** Prefer TypeScript; when using JS, use JSDoc type annotations

## Code Style
- **Indentation:** 2 spaces
- **Quotes:** Single quotes for strings
- **Semicolons:** Required
- **Naming:** camelCase for variables/functions, PascalCase for classes
- **Async:** Always use async/await, avoid callback hell
- **Exports:** Use ES modules (`import/export`) if project supports it, otherwise CommonJS

## Project Structure
Prefer clean architecture with separation of concerns:

```
src/
├── controllers/    # Request handlers (thin layer)
├── services/       # Business logic
├── models/         # Data models (Mongoose, Sequelize, Prisma)
├── routes/         # Route definitions
├── middleware/     # Custom middleware (auth, validation, error)
├── utils/          # Helper functions
├── config/         # Configuration (env-based)
└── server.js       # Entry point
```

## Security Best Practices
- **Input validation:** Use libraries like `joi`, `zod`, or `express-validator`
- **Authentication:** JWT with refresh tokens, or session-based with secure cookies
- **Authorization:** Middleware to check roles/permissions before route access
- **Rate limiting:** Use `express-rate-limit` to prevent abuse
- **Helmet:** Always use `helmet()` middleware for security headers
- **CORS:** Configure explicitly, never use `*` in production
- **Secrets:** Use environment variables, never hardcode
- **SQL Injection:** Use parameterized queries or ORM
- **XSS:** Sanitize user input, escape output
- **Dependencies:** Run `npm audit` regularly, keep packages updated

## Error Handling
- Use centralized error middleware:

```javascript
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message
  })
})
```

- Create custom error classes for different error types
- Use `try/catch` in async route handlers or use `express-async-errors`

## Environment Configuration
- Use `dotenv` for local development
- Required vars in `.env.example`:
  - `NODE_ENV` (development, production, test)
  - `PORT`
  - `DATABASE_URL`
  - `JWT_SECRET`
  - API keys (if applicable)

## Testing
- **Framework:** Jest or Vitest
- **API testing:** Supertest for integration tests
- **Coverage:** Aim for 80%+ on services and controllers
- **Mocking:** Mock external APIs and databases in unit tests
- **Run tests before commit:** `npm test`

## Performance
- **Caching:** Use Redis for session storage and caching
- **Compression:** Enable gzip with `compression()` middleware
- **Database:** Use connection pooling, indexes, and avoid N+1 queries
- **Logging:** Use structured logging with `winston` or `pino`
- **Monitoring:** Integrate APM (New Relic, Datadog) if available

## Dependencies
- **Production deps:** Only what runs in production
- **Dev deps:** Linters, test tools, build tools go in `devDependencies`
- **Keep minimal:** Avoid dependency bloat
- **Audit regularly:** `npm audit fix`

## Common Patterns

### Async route handler wrapper
```javascript
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next)
}

router.get('/users', asyncHandler(async (req, res) => {
  const users = await userService.getAll()
  res.json(users)
}))
```

### Middleware for authentication
```javascript
const authenticateToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) return res.status(401).json({ error: 'Unauthorized' })

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden' })
    req.user = user
    next()
  })
}
```

### Service pattern (business logic)
```javascript
class UserService {
  async getById(id) {
    const user = await User.findByPk(id)
    if (!user) throw new NotFoundError('User not found')
    return user
  }

  async create(data) {
    // Validation
    const schema = joi.object({ name: joi.string().required(), email: joi.string().email().required() })
    const { error, value } = schema.validate(data)
    if (error) throw new ValidationError(error.message)

    // Business logic
    const user = await User.create(value)
    return user
  }
}
```

## What to Avoid
- **Blocking operations:** Never use synchronous file operations in routes
- **Callback hell:** Use async/await instead
- **Global state:** Avoid global variables; use dependency injection
- **console.log in production:** Use proper logging library
- **Unhandled promises:** Always catch errors in async code
- **Exposing stack traces:** Sanitize errors in production
- **Missing input validation:** Validate all user input
- **Hardcoded secrets:** Always use environment variables

## Database
- **ORM/ODM:** Prefer Prisma (SQL), Mongoose (MongoDB), or Sequelize
- **Migrations:** Use database migration tools, never alter schema manually
- **Connection pooling:** Configure pool size based on load
- **Transactions:** Use for operations that must succeed or fail together
- **Indexing:** Add indexes for frequently queried fields

## Deployment
- **Process manager:** Use PM2 or systemd in production
- **Graceful shutdown:** Handle SIGTERM/SIGINT to close connections cleanly
- **Health checks:** Expose `/health` endpoint for load balancers
- **Environment:** Set `NODE_ENV=production` in production
- **Logs:** Stream logs to external service (CloudWatch, Datadog, etc.)

## TypeScript (when project uses TS)

**tsconfig.json baseline:**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "esModuleInterop": true,
    "skipLibCheck": false,
    "paths": {
      "@app/*": ["./src/*"],
      "@config/*": ["./src/config/*"]
    }
  }
}
```

**Type annotations:**
- Avoid `any` — use `unknown` for truly unknown values (force narrowing)
- Prefer generic types over `any` for functions working with multiple types
- Use type-only imports: `import type { User } from './types'`
- Typed environment variables:
  ```typescript
  const env = {
    DATABASE_URL: process.env.DATABASE_URL!,
    PORT: Number(process.env.PORT) || 3000,
    NODE_ENV: process.env.NODE_ENV as 'development' | 'production' | 'test',
  };
  ```

**Request/Response typing with Express:**
```typescript
import { Request, Response, NextFunction } from 'express';

interface CreateUserBody {
  name: string;
  email: string;
}

const createUser = async (
  req: Request<{}, {}, CreateUserBody>,
  res: Response,
  next: NextFunction
): Promise<void> => {
  // req.body is now typed
};
```

**Custom error types:**
```typescript
class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}
```

## Observability / APM

**Structured logging with pino (not console.log):**
```javascript
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: {
    service: process.env.SERVICE_NAME || 'api',
    version: process.env.APP_VERSION,
    env: process.env.NODE_ENV,
  },
  redact: ['req.headers.authorization', 'body.password'],  // Never log these
});

// Usage — structured context, not string interpolation
logger.info({ userId, action: 'login', duration_ms: elapsed }, 'User login successful');
logger.error({ err, requestId, userId }, 'Failed to process payment');
```

**Health check endpoints:**
```javascript
// /health — liveness probe (is the process alive?)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// /ready — readiness probe (can it handle traffic?)
app.get('/ready', async (req, res) => {
  try {
    await db.query('SELECT 1');  // Verify DB connectivity
    res.json({ status: 'ok' });
  } catch (err) {
    res.status(503).json({ status: 'error', message: 'Database unavailable' });
  }
});

// /metrics — Prometheus scrape endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

**Custom metrics with prom-client:**
```javascript
import { Counter, Histogram, register } from 'prom-client';

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
});

const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// Middleware to record metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || 'unknown';
    httpRequestDuration.observe({ method: req.method, route, status_code: res.statusCode }, duration);
    httpRequestsTotal.inc({ method: req.method, route, status_code: res.statusCode });
  });
  next();
});
```

**OpenTelemetry basics:**
```javascript
// At app startup (before any imports) — tracing.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { ExpressInstrumentation } from '@opentelemetry/instrumentation-express';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT }),
  instrumentations: [new HttpInstrumentation(), new ExpressInstrumentation()],
});
sdk.start();
```

---
**Skill type:** Passive
**Applies with:** ci-cd, docker, security, observability, api-design

---

## Communication Style

- Be concise and practical — show code, not theory
- Explain security implications of choices (middleware order, input validation)
- Prefer modern patterns (ES modules, async/await, optional chaining) over legacy
- When TypeScript is available, prefer it; explain type benefits when suggesting migration

---

## Expected Output Quality

Responses should:
- Include proper error handling (try/catch, centralized middleware)
- Use structured logging (pino) with correlation IDs
- Include input validation (zod/joi) on all route handlers
- Prefer `const` and immutable patterns
- Include health check endpoints (`/health`, `/ready`)
- Be deployable to production (no `console.log`, no hardcoded secrets)
- Include test examples (Jest/Vitest) with Arrange-Act-Assert pattern
