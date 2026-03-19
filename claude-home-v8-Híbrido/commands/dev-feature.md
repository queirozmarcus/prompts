---
name: dev-feature
description: "Implementar feature completa: API → use case → persistence. Orquestra Architect, API Designer, Backend Dev, DBA e Code Reviewer."
argument-hint: "[descrição-da-feature]"
---

# Implementar Feature: $ARGUMENTS

Implemente a feature **$ARGUMENTS** de ponta a ponta seguindo arquitetura hexagonal.

## Instruções

### Step 1: Design

Use o sub-agente **architect** para:
- Avaliar impacto da feature na arquitetura existente
- Definir componentes necessários (domain, use case, adapters)
- Identificar dependências com outros serviços/módulos
- Se houver decisão relevante, gerar ADR

### Step 2: API

Use o sub-agente **api-designer** para:
- Projetar os endpoints REST necessários
- Definir request/response schemas
- Definir status codes e erros
- Documentar com OpenAPI annotations

### Step 3: Schema

Use o sub-agente **dba** para:
- Modelar tabelas/colunas necessárias
- Criar migration Flyway (zero-downtime se possível)
- Definir índices para queries esperadas

### Step 4: Implementação

Use o sub-agente **backend-dev** para:
- Implementar domain model (entidades, VOs, regras)
- Implementar ports (in + out)
- Implementar use cases
- Implementar adapters (controller, repository, mapper)
- Configurar beans e properties

### Step 5: Code Review

Use o sub-agente **code-reviewer** para:
- Revisar todo o código gerado
- Verificar aderência à hexagonal
- Verificar segurança e performance
- Apontar melhorias

### Step 6: Apresentar

1. Lista de arquivos criados/modificados
2. Resumo da feature implementada
3. Resultado do code review
4. Instrução: "Use `/qa-generate {classe}` para gerar testes" (integração com QA team)
5. Próximos passos
