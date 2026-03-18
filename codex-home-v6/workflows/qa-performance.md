
# Testes de Performance: $ARGUMENTS

Projete e crie testes de performance para **$ARGUMENTS**.

## Instruções

Use o subagente **performance-engineer** para:

1. **Analisar o alvo**: Ler controllers, endpoints, fluxos do serviço
2. **Definir cenários**: Load, stress, soak — quais fazem sentido para $ARGUMENTS
3. **Definir SLOs**: Latência p50/p95/p99, throughput, error rate
4. **Criar scripts**: Gatling ou k6 com cenários completos
5. **Definir thresholds**: Critérios de aprovação/reprovação automáticos
6. **Instrução de execução**: Como rodar local e no CI

Salve os scripts em `src/test/performance/` e o plano em `docs/qa/strategies/performance-$ARGUMENTS.md`.
