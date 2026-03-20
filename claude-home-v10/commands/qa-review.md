---
name: qa-review
description: "Revisar testes existentes e identificar gaps. Orquestra QA Lead e Test Automation Engineer."
argument-hint: "[classe-ou-pacote-de-teste]"
---

# Revisão de Testes: $ARGUMENTS

Revise os testes existentes em **$ARGUMENTS** e identifique gaps, problemas e melhorias.

## Instruções

### Step 1: Analisar testes existentes

Use o sub-agente **test-automation-engineer** para:
- Ler todos os testes em $ARGUMENTS
- Verificar: assertions reais (não apenas verify sem assert), completude, edge cases
- Detectar anti-patterns: mock excessivo, Thread.sleep, @DirtiesContext, testes sem assertion
- Verificar independência entre testes (shared state?)
- Medir: quantos testes, quais cenários cobrem

### Step 2: Comparar com código fonte

Use o sub-agente **qa-lead** para:
- Identificar o código fonte correspondente aos testes
- Mapear regras de negócio não testadas
- Mapear edge cases não cobertos
- Mapear exceções não testadas
- Classificar gaps por risco

### Step 3: Apresentar

1. **Qualidade dos testes existentes** — score e problemas encontrados
2. **Gaps críticos** — o que deveria estar testado e não está
3. **Anti-patterns** — problemas que afetam confiabilidade
4. **Sugestões de melhoria** — refatorações e testes adicionais
5. **Testes a gerar** — lista priorizada de testes faltantes
