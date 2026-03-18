# Skill: Observability

## Scope

Implementação e operação dos três pilares de observabilidade: logs, métricas e traces. Cobre Prometheus, Grafana, alerting, distributed tracing (Jaeger/Tempo), log aggregation (Loki/ELK), SLOs/error budgets, CloudWatch, e design de sistemas observáveis desde o início.

## Core Principles

- **Observable by default** — instrumentação é responsabilidade do time de desenvolvimento, não afterthought
- **Alert on symptoms, not causes** — alerte no que o usuário sente (latência, erros), não em indicadores internos
- **SLOs over vanity metrics** — error budgets guiam decisões de confiabilidade vs velocidade de entrega
- **Cardinality matters** — labels de alta cardinalidade destroem Prometheus; design com cuidado
- **Correlation over silos** — logs, métricas e traces devem ser correlacionáveis via trace_id/request_id
- **Cost-aware** — CloudWatch Logs, métricas de alta frequência e traces 100% têm custo real

## The Three Pillars

| Pillar  | "When"               | Tool                          | Use for                                    |
|---------|----------------------|-------------------------------|--------------------------------------------|
| Metrics | Aggregated over time | Prometheus, CloudWatch        | Dashboards, alerting, trending             |
| Logs    | Discrete events      | Loki, CloudWatch Logs, ELK    | Debugging, audit trail                     |
| Traces  | Request flow         | Jaeger, Tempo, X-Ray          | Latency root cause, dependency map         |

**Correlation:** Inject `trace_id` e `request_id` em todos os logs. Vincule métricas por `service` e `instance`.

## Metrics (Prometheus)

**Metric Types:**
- `Counter` — only goes up (requests total, errors total)
- `Gauge` — can go up/down (active connections, queue depth, memory usage)
- `Histogram` — distribution with buckets (request duration, response size)
- `Summary` — pre-computed quantiles (avoid; prefer Histogram for aggregation)

**Naming Conventions:**
```
# Format: <namespace>_<subsystem>_<name>_<unit>
http_server_requests_total           # Counter
http_server_request_duration_seconds # Histogram (base unit: seconds)
process_resident_memory_bytes        # Gauge
job_queue_depth                      # Gauge (no unit needed, dimensionless)
```

**Instrumentation in Node.js:**
```javascript
const client = require('prom-client');
const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
});
```

**Kubernetes PodMonitor / ServiceMonitor:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

## PromQL Patterns

```promql
# Request rate (per second over 5m window)
rate(http_requests_total{status=~"5.."}[5m])

# Error ratio
sum(rate(http_requests_total{status=~"5.."}[5m]))
/ sum(rate(http_requests_total[5m]))

# P99 latency
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))

# CPU throttling ratio
sum(rate(container_cpu_cfs_throttled_seconds_total[5m])) by (pod)
/ sum(rate(container_cpu_cfs_periods_total[5m])) by (pod)

# Memory usage vs limit
container_memory_working_set_bytes{container!=""}
/ container_spec_memory_limit_bytes{container!=""}
```

## Grafana Best Practices

**Dashboard Design:**
- Use variables for environment, namespace, service (dropdowns)
- Top panel: RED metrics (Rate, Errors, Duration) as stat/gauge panels
- Second row: time-series panels for trends
- Third row: drill-down panels (per-pod, per-endpoint)
- Link to related dashboards and runbooks in panel descriptions

**Panel Tips:**
- Use `$__rate_interval` instead of hardcoded `[5m]` for rate queries
- Add thresholds (yellow/red) to gauge panels
- Use table panels for top-N views
- Add template links to runbooks in panel descriptions

**Provisioning (GitOps):**
```yaml
# grafana/provisioning/dashboards/dashboard.yaml
apiVersion: 1
providers:
  - name: default
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

## Distributed Tracing

**Trace Instrumentation:**
- Use OpenTelemetry SDK (vendor-neutral)
- Propagate context via W3C TraceContext headers (`traceparent`)
- Sample strategically: 100% for errors, 10% for normal traffic, 1% for high-volume
- Add business context as span attributes (user_id, order_id, tenant)

**Jaeger / Tempo:**
- Tempo for cost-effective storage (object storage backend)
- Jaeger for UI and advanced querying
- Grafana Tempo datasource + TraceQL for correlation

**Key Spans to Instrument:**
- HTTP incoming requests
- Database queries (include query hash, not full query)
- External API calls
- Message queue publish/consume
- Cache hits/misses

## Log Management

**Structured Logging (JSON):**
```javascript
// Use pino, not console.log
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: { service: 'api', version: process.env.APP_VERSION },
});
logger.info({ trace_id, user_id, duration_ms }, 'Request completed');
```

**Log Levels:**
- `DEBUG` — desenvolvimento local apenas (desabilitar em prod)
- `INFO` — eventos de negócio importantes
- `WARN` — situações anômalas mas recuperáveis
- `ERROR` — falhas que requerem atenção
- `FATAL` — serviço não pode continuar

**Loki Query Patterns:**
```logql
# Error rate by service
sum(rate({namespace="production"} |= "error" [5m])) by (app)

# Specific trace ID
{app="api"} | json | trace_id="abc123"

# Slow requests
{app="api"} | json | duration_ms > 1000
```

## SLIs, SLOs & Error Budgets

**SLI Types:**
- **Availability:** `good_requests / total_requests` (HTTP 5xx are bad)
- **Latency:** `requests_under_threshold / total_requests` (e.g., p99 < 500ms)
- **Throughput:** `successful_writes / total_writes`

**SLO Example:**
```
Service: Payment API
SLI: Success rate (non-5xx / total requests over 28 days)
SLO: 99.9% (allows 43.8 minutes downtime/month)
Error Budget: 0.1% = 43.8 min/month
```

**Error Budget Burn Rate Alerts (Multi-window):**
```yaml
# Fast burn: consuming budget too quickly
- alert: ErrorBudgetFastBurn
  expr: |
    (
      rate(http_requests_total{status=~"5.."}[1h])
      / rate(http_requests_total[1h])
      > 14.4 * (1 - 0.999)
    ) and (
      rate(http_requests_total{status=~"5.."}[5m])
      / rate(http_requests_total[5m])
      > 14.4 * (1 - 0.999)
    )
  labels:
    severity: critical
```

## Alerting Philosophy & Design

**Alert Checklist:**
- Does this alert represent user impact?
- Is it actionable? (Can the on-call do something?)
- Is the runbook linked?
- Has the threshold been calibrated (not too noisy)?

**Alert Fatigue Prevention:**
- Never alert on what isn't actionable
- Group related alerts (Alertmanager)
- Use inhibition rules (if cluster is down, don't fire per-service alerts)
- Review silences regularly — they mask problems

**Alert Template:**
```yaml
- alert: HighErrorRate
  expr: job:http_error_rate:ratio5m > 0.05
  for: 5m
  labels:
    severity: critical
    team: backend
  annotations:
    summary: "High error rate on {{ $labels.service }}"
    description: "Error rate is {{ $value | humanizePercentage }}"
    runbook_url: "https://runbooks.example.com/high-error-rate"
    dashboard_url: "https://grafana.example.com/d/xxx"
```

## AWS CloudWatch

**Key Metrics to Monitor:**
```
# EC2
CPUUtilization, NetworkIn/Out, StatusCheckFailed

# RDS
CPUUtilization, FreeableMemory, DatabaseConnections,
ReadLatency, WriteLatency

# ALB
HTTPCode_Target_5XX_Count, TargetResponseTime, HealthyHostCount

# EKS
cluster_failed_node_count, node_cpu_utilization, node_memory_utilization
```

**CloudWatch Logs Insights Query:**
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as errorCount by bin(5m)
| sort errorCount desc
```

**Cost Optimization:**
- Use log retention policies (don't keep logs forever)
- Prefer Prometheus + Grafana over CloudWatch Dashboards for Kubernetes
- Use Metric Filters instead of custom metrics where possible

## Cardinality & Cost

**High Cardinality Anti-Patterns:**
```
# BAD: user_id as label (millions of series)
http_requests_total{user_id="12345"}

# BAD: request path with IDs
http_requests_total{path="/users/12345/orders"}

# GOOD: route pattern
http_requests_total{route="/users/:id/orders"}
```

**Cardinality Budget:** Keep total time series < 1M per Prometheus instance. Monitor with:
```promql
# Top 10 metrics by cardinality
topk(10, count({__name__=~".+"}) by (__name__))
```

## SLO Templates (SLOTH / Pyrra)

**SLOTH** generates multi-window burn rate alerting rules from a simple YAML spec:

```yaml
# sloth.yaml — define SLOs, SLOTH generates all alerting rules
version: "prometheus/v1"
service: "payments-api"
labels:
  team: backend
  tier: critical

slos:
  - name: "availability"
    objective: 99.9
    description: "99.9% of payment API requests should succeed (non-5xx)"
    sli:
      events:
        error_query: sum(rate(http_requests_total{service="payments-api",status=~"5.."}[{{.window}}]))
        total_query: sum(rate(http_requests_total{service="payments-api"}[{{.window}}]))
    alerting:
      name: PaymentsAPIHighErrorRate
      labels: {severity: critical}
      annotations:
        summary: "Payments API error budget burning fast"
        runbook_url: "https://runbooks.example.com/payments-high-error-rate"

  - name: "latency"
    objective: 95
    description: "95% of requests complete in < 500ms"
    sli:
      events:
        error_query: sum(rate(http_request_duration_seconds_bucket{service="payments-api",le="0.5"}[{{.window}}]))
        total_query: sum(rate(http_request_duration_seconds_bucket{service="payments-api",le="+Inf"}[{{.window}}]))
    alerting:
      name: PaymentsAPIHighLatency
      labels: {severity: warning}
```

```bash
# Generate multi-window burn rate rules from SLOTH spec
sloth generate -i sloth.yaml -o generated-slo-rules.yaml

# Apply to Prometheus via K8s PrometheusRule or direct config
kubectl apply -f generated-slo-rules.yaml
```

**Pyrra** (alternative — generates PrometheusRule CRDs directly):
```yaml
apiVersion: pyrra.dev/v1alpha1
kind: ServiceLevelObjective
metadata:
  name: payments-api-availability
  namespace: monitoring
spec:
  description: "99.9% availability"
  target: "99.9"
  window: 28d
  indicator:
    ratio:
      errors:
        metric: http_requests_total{service="payments-api",status=~"5.."}
      total:
        metric: http_requests_total{service="payments-api"}
  alerting:
    burnRateAlerts: true
```

## Trace-Log Correlation

**Rule:** Every log line in production should include `trace_id` and `span_id`. This enables jumping directly from a log entry to the trace in Grafana Tempo/Jaeger.

**Node.js (pino + OpenTelemetry):**
```javascript
import pino from 'pino';
import { trace } from '@opentelemetry/api';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  mixin() {
    const span = trace.getActiveSpan();
    if (!span?.isRecording()) return {};
    const { traceId, spanId } = span.spanContext();
    return { trace_id: traceId, span_id: spanId };
  },
});

// Result: every log line includes trace_id + span_id
// {"level":"info","trace_id":"abc123...","span_id":"def456...","msg":"Request completed"}
```

**Python (structlog + OpenTelemetry):**
```python
import structlog
from opentelemetry import trace as otel_trace

def add_otel_context(logger, method, event_dict):
    span = otel_trace.get_current_span()
    if span and span.is_recording():
        ctx = span.get_span_context()
        event_dict["trace_id"] = format(ctx.trace_id, "032x")
        event_dict["span_id"] = format(ctx.span_id, "016x")
    return event_dict

structlog.configure(processors=[add_otel_context, structlog.processors.JSONRenderer()])
```

**Grafana: query logs by trace_id (Loki datasource):**
```logql
{service="payments-api"} | json | trace_id="abc123def456..."
```

**Grafana: configure Loki → Tempo derived field (automatic trace link in logs):**
```yaml
# In Grafana Loki datasource config
derivedFields:
  - name: TraceID
    matcherRegex: '"trace_id":"(\w+)"'
    url: "$${__value.raw}"
    datasourceUid: tempo-uid  # Your Tempo datasource UID
```

## Common Mistakes / Anti-Patterns

- Alerting on CPU > 80% (not a symptom, often not actionable)
- Using `summary` quantiles instead of `histogram` (can't aggregate across instances)
- High-cardinality labels (user_id, IP address, request_id in metric labels)
- 100% trace sampling in production (cost + performance)
- No correlation between logs and traces (trace_id not in logs)
- Dashboards without variable templates (hardcoded env/namespace)
- Never testing alerts (expressions that never fire when they should)

## Communication Style

When this skill is active:
- Provide PromQL examples, not just describe the query
- Recommend specific tools with trade-offs (Loki vs ELK for logs)
- Highlight cost implications of observability choices
- Connect observability to SLOs and user experience

## Expected Output Quality

- Complete PromQL/LogQL queries that can be copy-pasted
- Grafana panel JSON or configuration examples
- Alert rule YAML ready to apply
- Correlation of metrics/logs/traces in analysis

---
**Skill type:** Passive
**Applies with:** kubernetes, aws, networking, incidents
**Pairs well with:** sre-engineer (DevOps pack), kubernetes-engineer (DevOps pack)
