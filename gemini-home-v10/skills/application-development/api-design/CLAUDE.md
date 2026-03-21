# Skill: API Design

## Scope

Design e documentação de APIs REST. Cobre nomenclatura de recursos, HTTP methods e status codes, paginação, versionamento, error responses (RFC 7807), autenticação/autorização, rate limiting, idempotência, OpenAPI specification e padrões de API Gateway. Aplicável ao criar ou revisar APIs HTTP.

## Core Principles

- **Resources over actions** — `/orders` é REST; `/getOrders` é RPC em HTTP; usar substantivos, não verbos
- **HTTP semantics importam** — GET é idempotente e cacheável; POST não é; usar o método correto
- **Backwards compatibility é sacral** — APIs públicas nunca quebram contratos existentes; apenas adicionam
- **Document-first** — escrever OpenAPI spec antes de implementar; API como contrato, não afterthought
- **Fail fast com errors claros** — 400 com corpo útil > 500 sem contexto; o cliente precisa saber o que corrigir

## REST Resource Design

**Nomenclatura:**
```
Coleções (plural, substantivo):   GET /orders
Item específico:                   GET /orders/{id}
Sub-recursos:                     GET /orders/{id}/items
Ações sobre recurso:              POST /orders/{id}/cancel (não /cancelOrder)
Relacionamentos:                  GET /users/{id}/orders
```

**Hierarquia de recursos (máximo 2-3 níveis de profundidade):**
```
GET /organizations/{orgId}/projects/{projectId}/tasks
# Mais profundo que isso → considerar resource separado com query params
GET /tasks?organizationId=X&projectId=Y
```

## HTTP Methods & Status Codes

**Methods:**
| Method | Semantics | Idempotent | Safe |
|--------|-----------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / non-idempotent action | No | No |
| PUT | Replace (full resource) | Yes | No |
| PATCH | Partial update | Depends | No |
| DELETE | Delete | Yes | No |

**Status codes — usar o correto:**
```
200 OK          — GET, PUT, PATCH success com body
201 Created     — POST que cria recurso (+ Location header)
202 Accepted    — Operação async aceita, processamento em background
204 No Content  — DELETE, PUT/PATCH sem body de resposta
400 Bad Request — Payload inválido, validation error
401 Unauthorized — Not authenticated (sem token ou token inválido)
403 Forbidden   — Authenticated but not authorized (token válido, sem permissão)
404 Not Found   — Resource não existe
409 Conflict    — Estado conflitante (ex: email duplicado, optimistic lock)
410 Gone        — Resource existia mas foi deletado permanentemente
422 Unprocessable — Sintaxe OK mas semanticamente inválido (bem-tipado mas logicamente errado)
429 Too Many Requests — Rate limit atingido
500 Internal Server Error — Erro inesperado (nunca expor stack trace)
503 Service Unavailable — Service down temporariamente
```

## Request & Response Design

**Request body:**
```json
// POST /orders
{
  "customerId": "cust_123",
  "items": [
    { "productId": "prod_456", "quantity": 2 }
  ],
  "shippingAddress": {
    "street": "123 Main St",
    "city": "Springfield"
  }
}
```

**Response body (consistent structure):**
```json
// GET /orders/ord_789
{
  "id": "ord_789",
  "status": "pending",
  "customerId": "cust_123",
  "items": [...],
  "total": 49.99,
  "currency": "USD",
  "createdAt": "2026-02-25T14:30:00Z",
  "updatedAt": "2026-02-25T14:30:00Z",
  "_links": {
    "self": { "href": "/orders/ord_789" },
    "customer": { "href": "/customers/cust_123" },
    "cancel": { "href": "/orders/ord_789/cancel", "method": "POST" }
  }
}
```

**Timestamps:** ISO 8601 em UTC: `2026-02-25T14:30:00Z`. Nunca Unix timestamps em APIs públicas.

**IDs:** Prefixed IDs (`ord_789`, `cust_123`) evitam confusão entre tipos. UUIDs para não adivinhar.

## Pagination, Filtering & Sorting

**Cursor-based pagination (preferível para grandes datasets):**
```
GET /orders?cursor=eyJpZCI6MTIzfQ==&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "hasNextPage": true,
    "nextCursor": "eyJpZCI6MTQ0fQ==",
    "limit": 20
  }
}
```

**Offset pagination (simples mas com limitações):**
```
GET /orders?page=2&pageSize=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "pageSize": 20,
    "totalItems": 1547,
    "totalPages": 78
  }
}
```

**Filtering:**
```
GET /orders?status=pending&customerId=cust_123
GET /orders?createdAfter=2026-01-01&createdBefore=2026-02-01
GET /orders?minTotal=100&maxTotal=500
```

**Sorting:**
```
GET /orders?sort=createdAt:desc,total:asc
# Or simpler:
GET /orders?sortBy=createdAt&sortOrder=desc
```

**Field selection (sparse fieldsets):**
```
GET /orders?fields=id,status,total  # Reduz payload para clientes mobile
```

## Error Handling (RFC 7807 Problem Details)

```json
// HTTP 400
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 400,
  "detail": "The request contains invalid parameters.",
  "instance": "/orders/create",
  "errors": [
    {
      "field": "items[0].quantity",
      "code": "INVALID_VALUE",
      "message": "Quantity must be between 1 and 100"
    },
    {
      "field": "shippingAddress.city",
      "code": "REQUIRED",
      "message": "City is required"
    }
  ],
  "traceId": "b7e23c1a-d5f4-4b93-8f2a-1c9e2d3f4a5b"
}
```

**Regras:**
- Sempre retornar `traceId` (correlação com logs)
- `errors` array para múltiplos problemas de validação
- `type` URI deve ser documentado e estável
- Nunca expor stack traces, nomes de classes, ou detalhes de implementação

## API Versioning

**Estratégias:**

| Approach | Exemplo | Pros | Cons |
|----------|---------|------|------|
| URL versioning | `/v2/orders` | Visível, simples | URL polui resource |
| Header versioning | `API-Version: 2` | Limpo | Menos visível |
| Content negotiation | `Accept: application/vnd.api.v2+json` | RFC-compliant | Complexo |

**Recomendação:** URL versioning para APIs públicas (mais descobrível); header para APIs internas.

**Regras de versioning:**
```
v1 → v2: Mudanças breaking (remoção de campos, mudança de types)
v1 sempre deve funcionar enquanto houver clientes
Deprecation: header Deprecation: true + link para v2
Sunset: data de remoção via Sunset: Wed, 31 Dec 2026 00:00:00 GMT
```

## Authentication & Authorization

**JWT Bearer token (stateless):**
```http
GET /orders/ord_789
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
```

**OAuth2 flows:**
- **Client Credentials:** Machine-to-machine (service accounts, CI/CD)
- **Authorization Code + PKCE:** User-facing apps (web, mobile)
- **Device Code:** CLIs, TVs

**API Keys (simples, para integrações M2M):**
```http
X-API-Key: ak_prod_xxxxxxxxxxxxx
# Ou como query param para webhooks (mas headers são preferíveis para segurança)
```

**Autorização no response:**
```json
// Quando o usuário não tem acesso ao recurso específico:
// HTTP 403
{
  "type": "https://api.example.com/errors/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "You don't have permission to access order ord_789."
  // Não revelar se o recurso existe ou não (evitar enumeration)
}
```

## Rate Limiting & Throttling

**Headers padrão (RFC 6585 + draft RateLimit headers):**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 947
X-RateLimit-Reset: 1706745600
Retry-After: 3600  # Quando retornando 429
```

**Estratégias:**
- **Fixed window:** Simples mas com burst no início da janela
- **Sliding window:** Mais justo, sem burst
- **Token bucket:** Permite bursts controlados

**Response 429:**
```json
{
  "type": "https://api.example.com/errors/rate-limited",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded 1000 requests per hour. Retry after 3600 seconds.",
  "retryAfter": 3600
}
```

## Idempotency

**Operações POST com Idempotency-Key:**
```http
POST /payments
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{"amount": 49.99, "currency": "USD", "orderId": "ord_789"}
```

```
Primeira request: processo pagamento, store key → result
Segunda request (mesma key): retornar resultado cacheado (não processar novamente)
```

**Quando usar:** Criação de recursos críticos (pagamentos, ordens), qualquer POST que não deva ser duplicado.

## OpenAPI Specification

```yaml
openapi: 3.1.0
info:
  title: Orders API
  version: 2.0.0
  description: API para gerenciamento de pedidos

paths:
  /orders:
    post:
      summary: Create order
      operationId: createOrder
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateOrderRequest'
      responses:
        '201':
          description: Order created
          headers:
            Location:
              schema:
                type: string
              example: /orders/ord_789
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'

components:
  schemas:
    CreateOrderRequest:
      type: object
      required: [customerId, items]
      properties:
        customerId:
          type: string
          pattern: '^cust_[a-zA-Z0-9]+$'
        items:
          type: array
          minItems: 1
          items:
            $ref: '#/components/schemas/OrderItem'
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Backwards Compatibility Rules

**Mudanças seguras (não requerem nova versão):**
- Adicionar novos campos opcionais ao response
- Adicionar novos endpoints
- Adicionar novos valores a enums (se cliente ignora unknown)
- Relaxar validações de request

**Mudanças breaking (requerem nova versão):**
- Remover ou renomear campos do response
- Mudar tipo de dados (string → integer)
- Adicionar campos obrigatórios ao request
- Mudar semântica de endpoints existentes
- Remover endpoints

## Common Mistakes / Anti-Patterns

- **Verbos na URL** — `/getUser`, `/deleteOrder` é RPC; `/users/{id}` com DELETE method é REST
- **200 para tudo, error no body** — erro deve ser no HTTP status code, não no body com `{"success": false}`
- **Expor detalhes internos** — stack traces, IDs de banco de dados interno, nomes de tabelas
- **Sem rate limiting** — APIs sem throttling são vulneráveis a abuse
- **Timestamps sem timezone** — `2026-02-25 14:30:00` é ambíguo; sempre `2026-02-25T14:30:00Z`
- **Breaking changes sem versioning** — alterar response existente quebra clientes em produção
- **IDs sequenciais** — expõe volume de negócio e é enumerável; usar UUID ou prefixed IDs

## Communication Style

Quando esta skill está ativa:
- Questionar o design de URL se verbs estiverem presentes
- Sugerir RFC 7807 para error responses
- Alertar sobre mudanças breaking em APIs existentes
- Fornecer OpenAPI snippet para novos endpoints

## Expected Output Quality

- URL paths seguindo convenções REST
- HTTP status codes corretos para cada caso
- Error response em formato RFC 7807
- Idempotency-Key para operações críticas POST
- OpenAPI snippet para documentar o endpoint

---
**Skill type:** Passive
**Applies with:** nodejs, java, security, observability
**Pairs well with:** api-designer (Dev pack), architect (Dev pack)
