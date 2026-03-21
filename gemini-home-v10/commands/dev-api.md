---
name: dev-api
description: "Projetar API REST completa com OpenAPI spec. Orquestra API Designer e Architect."
argument-hint: "[recurso-ou-serviço]"
---

# Projetar API: $ARGUMENTS

Projete a API REST para **$ARGUMENTS** com spec OpenAPI completa.

## Instruções

### Step 1: Design

Use o sub-agente **architect** para:
- Definir os recursos e suas relações
- Decidir operações necessárias (CRUD + ações de negócio)
- Definir comunicação (sync/async) se houver dependência

### Step 2: Spec

Use o sub-agente **api-designer** para:
- Gerar OpenAPI 3.1 spec completa
- Definir schemas (request, response, erros)
- Definir paginação e filtros
- Documentar status codes e Problem Details
- Salvar em `docs/api/$ARGUMENTS-api-v1.yaml`

### Step 3: Apresentar

1. Lista de endpoints com verbos e status codes
2. Link para spec OpenAPI gerada
3. Exemplos de request/response
4. Instrução: "Use `/dev-feature` para implementar estes endpoints"
