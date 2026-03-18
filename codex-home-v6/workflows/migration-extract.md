
# Fase 3 — Extração do Bounded Context: $ARGUMENTS

Extraia o bounded context **$ARGUMENTS** do monólito como microsserviço independente.

## Pré-requisitos

Antes de iniciar, verifique se existem:
- `docs/migration/context-maps/bounded-contexts.md` (Fase 0)
- `docs/migration/extraction-cards/$ARGUMENTS.md` (Fase 1)
- Seams criados no monólito para este contexto (Fase 2)

Se não existirem, informe o usuário que as fases anteriores precisam ser executadas primeiro.

## Instruções

### Step 1: Análise do contexto a extrair

Use o subagente **domain-analyst** para:
- Revisar o bounded context $ARGUMENTS no mapa existente
- Listar todas as dependências de entrada (quem chama)
- Listar todas as dependências de saída (o que chama)
- Listar tabelas que pertencem a este contexto
- Identificar tabelas compartilhadas com outros contextos

### Step 2: Implementar microsserviço

Use o subagente **backend-engineer** para:
- Criar estrutura hexagonal do serviço `$ARGUMENTS-service`
- Portar regras de negócio do monólito (paridade funcional)
- Implementar adapters: REST controllers, Kafka consumers/producers, JPA repositories
- Configurar Outbox Pattern para eventos
- Criar application.yml com profiles (local, staging, prod)
- Criar Flyway migration V1__init_schema.sql

### Step 3: Planejar migração de dados

Use o subagente **data-engineer** para:
- Definir estratégia de split para as tabelas do contexto
- Criar migration scripts
- Planejar dual-write ou CDC se necessário
- Definir plano de validação de integridade
- Resolver foreign keys cross-context

### Step 4: Infraestrutura e deploy

Use o subagente **platform-engineer** para:
- Criar Dockerfile otimizado
- Criar Helm chart com probes, HPA, PDB
- Criar docker-compose.yml para dev local
- Configurar pipeline CI/CD
- Configurar roteamento progressivo (feature flag)
- Configurar observabilidade (métricas, logs, alertas)

### Step 5: Testes

Use o subagente **qa-engineer** para:
- Criar testes unitários dos use cases (>80%)
- Criar testes de integração com Testcontainers
- Criar contract tests da API REST
- Planejar teste de paridade com golden dataset
- Definir chaos tests para validar resiliência

### Step 6: Revisão de segurança

Use o subagente **security-engineer** para:
- Auditar endpoints do novo serviço
- Validar auth e autorização
- Verificar exposição de dados sensíveis
- Revisar comunicação entre serviços

### Step 7: Consolidar e entregar

Assuma o papel de **Tech Lead** e:

1. Gere ADR para decisões específicas desta extração
2. Gere runbook operacional em `docs/migration/runbooks/$ARGUMENTS-service.md`
3. Atualize o mapa de bounded contexts
4. Crie a ficha de extração completa

Apresente ao usuário:
1. Resumo dos arquivos criados/modificados
2. Plano de roteamento progressivo (shadow → canary → full)
3. Critérios de sucesso e rollback
4. Riscos identificados
5. Próximos passos
