
# Code Review: $ARGUMENTS

Execute code review completo em **$ARGUMENTS** com múltiplas perspectivas.

## Instruções

### Step 1: Reviews em paralelo

Se a delegação por subagentes estiver disponível no runtime, lance estes especialistas em paralelo. Caso contrário, execute as análises na mesma sessão e preserve a separação de perspectivas:

1. **Code Reviewer** (subagent: code-reviewer)
   - Revisão geral: correção, design, legibilidade, padrões
   - Produzir: review com classificação (crítico, importante, sugestão)

2. **Architect** (subagent: architect)
   - Revisar aderência à arquitetura hexagonal
   - Verificar limites entre camadas
   - Identificar violações de SRP, DIP

3. **DBA** (subagent: dba)
   - Se houver queries/JPA: revisar performance, N+1, índices
   - Se houver migrations: revisar segurança e zero-downtime

### Step 2: Consolidar

Combine os reviews em um relatório único:

```
## Veredicto: ✅ Aprovado | 🟡 Ressalvas | 🔴 Bloquear

### 🔴 Crítico (N items)
### 🟡 Importante (N items)
### 💡 Sugestões (N items)
### ✅ Pontos Positivos
```

Se aprovado com ressalvas, indique: "Execute o workflow `qa-generate $ARGUMENTS` para gerar testes que validem as correções."
