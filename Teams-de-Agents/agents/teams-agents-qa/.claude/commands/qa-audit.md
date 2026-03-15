---
name: qa-audit
description: "Auditoria completa de qualidade do projeto. Orquestra QA Lead, todos os engenheiros de teste e Security Test Engineer."
---

# Auditoria de Qualidade — Análise Completa

Execute uma auditoria completa de qualidade do projeto Java/Spring Boot atual.

## Instruções

### Step 1: Análises em paralelo

Use o tool Task para lançar estes sub-agentes **em paralelo**:

1. **QA Lead** (subagent: qa-lead)
   - Mapear testes existentes por tipo e cobertura
   - Avaliar pirâmide de testes (proporção unit/integration/e2e)
   - Identificar classes sem testes (especialmente domain e application)
   - Classificar gaps por risco técnico e de negócio
   - Produzir: estratégia de testes com prioridades

2. **Test Automation Engineer** (subagent: test-automation-engineer)
   - Analisar tempo de execução da suíte de testes
   - Identificar testes flaky (se houver histórico)
   - Verificar uso de Thread.sleep, mocks excessivos, @DirtiesContext
   - Avaliar fixtures e reutilização de test utilities
   - Produzir: lista de otimizações e problemas

3. **Security Test Engineer** (subagent: security-test-engineer)
   - Buscar hardcoded secrets no código
   - Verificar endpoints sem autenticação
   - Verificar logs com dados sensíveis
   - Verificar @Query com concatenação (SQL injection risk)
   - Avaliar dependências com vulnerabilidades conhecidas
   - Produzir: assessment de segurança

### Step 2: Consolidar

Assuma o papel de **QA Lead** e consolide os resultados:

1. **Score de qualidade** (0-100) baseado em cobertura, pirâmide, segurança, velocidade
2. **Top 5 riscos** ordenados por impacto
3. **Plano de ação priorizado** com esforço estimado (S/M/L)
4. **Quick wins** — melhorias de alto impacto e baixo esforço

### Step 3: Salvar

- `docs/qa/reports/audit-{data}.md` — relatório completo
- `docs/qa/strategies/test-strategy.md` — estratégia recomendada

### Step 4: Apresentar resumo

Mostre ao usuário:
1. Score de qualidade com breakdown
2. Top 5 riscos com severidade
3. Quick wins implementáveis agora
4. Plano de ação completo
