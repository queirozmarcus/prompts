
# Observabilidade: $ARGUMENTS

Configure observabilidade completa para **$ARGUMENTS**.

## Instruções

### Step 1: Métricas — Use **observability-engineer** para:
- ServiceMonitor para Prometheus
- Recording rules para queries frequentes
- Dashboard Grafana (RED method + JVM + dependencies)

### Step 2: Alertas — Use **observability-engineer** para:
- SLO-based alerts com burn rate
- Alertas de infraestrutura (restarts, OOM, CPU)
- Alertas de dependências (consumer lag, circuit breaker)

### Step 3: Logs e Traces — Use **observability-engineer** para:
- Configurar structured logging (JSON + correlationId + traceId)
- Loki pipeline para parsing
- OpenTelemetry tracing

### Step 4: SLOs — Use **devops-lead** para:
- Definir SLIs e SLOs do serviço
- Calcular error budget
- Salvar em `docs/devops/slos/`
