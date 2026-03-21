---
name: qa-security
description: "Testes de segurança OWASP, auth bypass, IDOR, fuzzing. Orquestra Security Test Engineer."
argument-hint: "[serviço-ou-endpoint]"
---

# Testes de Segurança: $ARGUMENTS

Execute análise e testes de segurança em **$ARGUMENTS**.

## Instruções

### Step 1: Superfície de ataque

Use o sub-agente **security-test-engineer** para:
- Mapear endpoints expostos e seus métodos de autenticação
- Identificar inputs de usuário (headers, query params, body, uploads)
- Listar roles e permissões (RBAC/ABAC)
- Verificar dependências com vulnerabilidades conhecidas

### Step 2: Testes OWASP Top 10

Ainda com **security-test-engineer**:
- **Injection:** SQL, NoSQL, command injection nos inputs
- **Broken Auth:** Token manipulation, session fixation, brute force
- **IDOR:** Acesso a recursos de outros tenants/users alterando IDs
- **XSS:** Reflected e stored em outputs que renderizam HTML
- **Security Misconfiguration:** Headers (CORS, CSP, HSTS), verbose errors
- **Broken Access Control:** Vertical (role escalation) e horizontal (tenant leak)
- **Cryptographic Failures:** Secrets em logs, weak hashing, HTTP sem TLS

### Step 3: Criar testes automatizados

Ainda com **security-test-engineer**:
- Testes de auth bypass (acesso sem token, token expirado, token de outro user)
- Testes de IDOR (acessar order de outro customer)
- Testes de input validation (payloads maliciosos)
- Integrar no CI como quality gate

### Step 4: Apresentar

1. Vulnerabilidades encontradas com severidade (Critical/High/Medium/Low)
2. Testes automatizados criados
3. Recomendações de fix priorizadas
4. Checklist de segurança para PR review
