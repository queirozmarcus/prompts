---
name: migration-discovery
description: "Fase 0 — Discovery completo do monólito. Orquestra Domain Analyst, Data Engineer, Security Engineer e Tech Lead para análise completa."
argument-hint: "[módulo-ou-pacote-base (opcional)]"
---

# Fase 0 — Discovery e Assessment do Monólito

Conduza uma análise completa do monólito para preparar a decomposição em microsserviços.

## Instruções

Execute as análises abaixo em paralelo usando sub-agentes especializados, depois consolide os resultados.

### Step 1: Lançar análises em paralelo

Use o tool Task para lançar estes sub-agentes **em paralelo**:

1. **Domain Analyst** (subagent: domain-analyst)
   - Mapear estrutura de pacotes e classes
   - Identificar bounded contexts implícitos no código
   - Mapear dependências entre módulos (chamadas diretas, imports cruzados)
   - Detectar side effects (listeners, schedulers, interceptors)
   - Detectar transações cruzadas entre módulos
   - Produzir: mapa de bounded contexts + dependências

2. **Data Engineer** (subagent: data-engineer)
   - Inventariar schema: entidades JPA, tabelas, relações, FKs
   - Mapear ownership de dados por módulo/contexto
   - Identificar tabelas compartilhadas entre módulos
   - Estimar volume de dados por tabela
   - Identificar queries cross-module (JOINs)
   - Produzir: mapa de ownership de dados

3. **Security Engineer** (subagent: security-engineer)
   - Mapear modelo de autenticação/autorização atual
   - Identificar permissões por módulo
   - Classificar dados sensíveis (PII, financeiro)
   - Identificar compliance requirements
   - Produzir: assessment de segurança

### Step 2: Consolidar resultados

Depois que os sub-agentes retornarem, assuma o papel de **Tech Lead** e:

1. Crie a **matriz de acoplamento** (módulo × módulo com tipo de dependência)
2. Avalie **risco por módulo**: complexidade, acoplamento, criticidade, volume
3. Produza **ranking de candidatos à extração**: valor vs risco vs acoplamento
4. Estime **esforço por bounded context** (T-shirt sizing: S/M/L/XL)
5. Gere **ADR-000**: Decisão de migrar — motivação, riscos, estratégia macro

### Step 3: Salvar entregáveis

Salve os artefatos em `docs/migration/`:

- `docs/migration/context-maps/bounded-contexts.md`
- `docs/migration/context-maps/data-ownership.md`
- `docs/migration/context-maps/dependency-matrix.md`
- `docs/migration/adr/ADR-000-decision-to-migrate.md`
- `docs/migration/extraction-ranking.md`
- `docs/migration/security-assessment.md`

### Step 4: Resumo executivo

Apresente ao usuário:
1. Quantos bounded contexts foram identificados
2. Top 3 candidatos à extração (menor risco, maior valor)
3. Maiores riscos e pontos de atenção
4. Próximos passos recomendados
