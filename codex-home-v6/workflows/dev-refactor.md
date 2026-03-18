
# Refatorar: $ARGUMENTS

Refatore **$ARGUMENTS** de forma segura, preservando comportamento existente.

## Instruções

### Step 1: Analisar e planejar

Use o subagente **refactoring-engineer** para:
- Ler e entender o código atual
- Medir complexidade, tamanho, acoplamento
- Identificar problemas (god class, anemic domain, duplicação, dead code)
- Planejar passos de refatoração (pequenos, incrementais, testáveis)
- Verificar se há testes existentes (se não, criar antes de refatorar)

### Step 2: Executar refatoração

Ainda com **refactoring-engineer**:
- Executar cada passo da refatoração
- Após cada passo, indicar quais testes validam

### Step 3: Revisar resultado

Use o subagente **code-reviewer** para:
- Comparar antes vs depois
- Validar que comportamento foi preservado
- Verificar que complexidade reduziu

### Step 4: Apresentar

1. Métricas antes vs depois
2. Passos executados
3. Resultado do review
4. Instrução: "Execute o workflow `qa-review` para verificar que testes continuam passando"
