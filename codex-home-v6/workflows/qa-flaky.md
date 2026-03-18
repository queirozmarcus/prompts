
# Diagnóstico de Flaky Test: $ARGUMENTS

Diagnostique e corrija o teste instável em **$ARGUMENTS**.

## Instruções

Use o subagente **test-automation-engineer** para:

1. **Ler o teste** e entender o que ele faz
2. **Identificar a causa** — verificar padrões comuns:
   - Dependência de tempo (Instant.now, LocalDate.now)
   - Dependência de ordem de execução (shared state)
   - Race condition em testes assíncronos (Thread.sleep)
   - Porta/recurso compartilhado
   - Dados residuais entre testes
   - Container lento para iniciar
3. **Reproduzir** — tentar reproduzir a instabilidade:
   ```bash
   # Rodar 10 vezes para verificar
   for i in $(seq 1 10); do ./mvnw test -Dtest="$ARGUMENTS" -q; done
   # Rodar em paralelo
   ./mvnw test -T 4 -Dtest="$ARGUMENTS"
   ```
4. **Corrigir** — aplicar a fix adequada
5. **Prevenir** — sugerir ArchUnit rule ou lint para evitar recorrência
6. **Verificar** — rodar 10x para confirmar estabilidade
