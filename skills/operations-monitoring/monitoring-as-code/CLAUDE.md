# Skill: Monitoring as Code

## Scope

Gerenciamento declarativo de configurações de monitoring: Prometheus alerting rules, recording rules, Alertmanager config, SLO-based alerting, Grafana dashboards como código (Jsonnet/Grafonnet), provisionamento via GitOps e testes de regras. Aplicável quando criando ou modificando configurações de observabilidade como código versionável.

## Core Principles

- **Config em Git** — alertas e dashboards devem ser versionados, code-reviewed e auditáveis
- **Alert on symptoms, not causes** — CPU > 80% não é um sintoma; error rate > 1% é
- **SLO-driven alerts** — alertas baseados em error budget burn rate são mais confiáveis que thresholds fixos
- **Runbook links obrigatórios** — cada alerta deve ter um link de runbook; sem runbook = não escalar
- **Testar regras** — `promtool` permite unit testing de alerting rules; escrever testes antes de aplicar

## Prometheus Alerting Rules

**Estrutura de PrometheusRule (Kubernetes CRD):**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: myapp-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
    - name: myapp.rules
      interval: 30s
      rules:
        - alert: MyAppHighErrorRate
          expr: |
            (
              sum(rate(http_requests_total{job="myapp", status=~"5.."}[5m]))
              /
              sum(rate(http_requests_total{job="myapp"}[5m]))
            ) > 0.05
          for: 5m
          labels:
            severity: critical
            team: backend
            service: myapp
          annotations:
            summary: "High error rate on {{ $labels.service }}"
            description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
            runbook_url: "https://runbooks.example.com/myapp/high-error-rate"
            dashboard_url: "https://grafana.example.com/d/myapp-overview"
```

**Severidades padronizadas:**
```
critical  — precisa de ação imediata, acorda on-call (SEV1/SEV2)
warning   — degradação detectada, ação nas próximas horas (SEV3)
info      — informacional, não acorda on-call
```

**Labels obrigatórios em todo alerta:**
```yaml
labels:
  severity: critical|warning|info
  team: backend|platform|data       # Para routing no Alertmanager
  service: myapp                    # Para silencing seletivo
```

**Expressões PromQL — padrões comuns:**
```promql
# Error rate ratio (> 1% por 5min = warning, > 5% = critical)
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
/ sum(rate(http_requests_total[5m])) by (service)

# P99 latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))

# Pod restarts recentes
increase(kube_pod_container_status_restarts_total{namespace="production"}[15m]) > 3

# Job failing (CronJob)
kube_job_failed{namespace="production"} > 0

# Certificate expiring soon
certmanager_certificate_expiration_timestamp_seconds - time() < 7 * 24 * 3600
```

## Recording Rules

Recording rules pre-computam queries caras, melhorando performance de alertas e dashboards.

**Naming convention:** `level:metric:operation`
```yaml
groups:
  - name: myapp.recording_rules
    rules:
      # job:http_requests_total:rate5m
      - record: job:http_requests_total:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job, status)

      # job:http_error_rate:ratio5m
      - record: job:http_error_rate:ratio5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
          /
          sum(rate(http_requests_total[5m])) by (job)

      # job:http_request_duration_p99:rate5m
      - record: job:http_request_duration_p99:rate5m
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le)
          )
```

**Usar recording rules quando:**
- Query aparece em múltiplos alertas ou dashboards
- Query é cara e executada frequentemente
- Range vector > 5 minutos (sub-queries podem ser lentas)

## SLO-Based Alerting

**Definição de SLO:**
```yaml
# SLI: % de requests bem-sucedidos (não 5xx)
# SLO: 99.9% de disponibilidade (permite 43.8 min/mês de erros)
# Error budget: 0.1% = 43.2 min/mês
```

**Multi-window, multi-burn-rate alerts (Google SRE approach):**
```yaml
# Fast burn: consumindo budget muito rápido (alerta crítico)
- alert: ErrorBudgetFastBurn
  expr: |
    (
      job:http_error_rate:ratio1h{job="myapp"} > (14.4 * 0.001)
    ) and (
      job:http_error_rate:ratio5m{job="myapp"} > (14.4 * 0.001)
    )
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Fast burn rate — consuming monthly error budget too quickly"
    description: "Current burn rate: {{ $value | humanizePercentage }}"
    runbook_url: "https://runbooks.example.com/error-budget-burn"

# Slow burn: consumindo budget mais devagar (alerta warning para 6h/3d windows)
- alert: ErrorBudgetSlowBurn
  expr: |
    (
      job:http_error_rate:ratio6h{job="myapp"} > (6 * 0.001)
    ) and (
      job:http_error_rate:ratio30m{job="myapp"} > (6 * 0.001)
    )
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Slow burn rate — error budget degrading"
```

**Burn rate reference:**
| Burn Rate | Time to Exhaust Budget | Window |
|-----------|----------------------|--------|
| 1x | 30 days | Normal |
| 5x | 6 days | Slow burn |
| 14.4x | 2 days | Fast burn (critical) |
| 36x | 1 hour | Very fast (page immediately) |

## Alertmanager Configuration

```yaml
# alertmanager.yaml
global:
  resolve_timeout: 5m
  slack_api_url: ${SLACK_WEBHOOK_URL}

route:
  group_by: [alertname, service]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: default-receiver

  routes:
    # Critical alerts → PagerDuty
    - match:
        severity: critical
      receiver: pagerduty-critical
      continue: false

    # Platform team alerts
    - match:
        team: platform
      receiver: platform-slack
      continue: true

receivers:
  - name: default-receiver
    slack_configs:
      - channel: '#alerts-staging'
        title: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: pagerduty-critical
    pagerduty_configs:
      - routing_key: ${PAGERDUTY_KEY}
        description: '{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.summary }}'

inhibit_rules:
  # Se cluster inteiro está down, não disparar alertas de serviços individuais
  - source_match:
      alertname: ClusterDown
    target_match_re:
      alertname: '.*'
    equal: [cluster]
```

**Silences para manutenção:**
```bash
# Criar silence via CLI durante janela de manutenção
amtool silence add \
  --alertmanager.url http://alertmanager:9093 \
  --comment "Planned maintenance 2026-02-25 22:00-23:00 UTC" \
  --duration 1h \
  service=myapp
```

## Grafana Dashboards as Code

**Provisioning via ConfigMap (GitOps):**
```yaml
# grafana-dashboards-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  myapp-overview.json: |
    {
      "title": "MyApp Overview",
      "uid": "myapp-overview",
      "panels": [...]
    }
```

**Dashboard JSON — estrutura essencial:**
```json
{
  "title": "MyApp Overview",
  "uid": "myapp-overview",
  "refresh": "30s",
  "time": {"from": "now-1h", "to": "now"},
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "query",
        "query": "label_values(kube_pod_info, namespace)",
        "current": {"text": "production"}
      }
    ]
  },
  "panels": [
    {
      "title": "Error Rate",
      "type": "timeseries",
      "targets": [{
        "expr": "sum(rate(http_requests_total{status=~'5..',namespace='$namespace'}[$__rate_interval])) by (service)",
        "legendFormat": "{{service}}"
      }],
      "fieldConfig": {
        "defaults": {
          "unit": "percentunit",
          "thresholds": {
            "steps": [
              {"value": 0, "color": "green"},
              {"value": 0.01, "color": "yellow"},
              {"value": 0.05, "color": "red"}
            ]
          }
        }
      }
    }
  ]
}
```

**Práticas de dashboard:**
- Use `$__rate_interval` (não `[5m]` hardcoded) para adaptar à taxa de scrape
- Variáveis de template para namespace, service, cluster
- Top row: RED metrics (Rate, Errors, Duration) como stat panels
- Link para runbooks nas descriptions dos panels críticos

## Provisioning & GitOps

**Estrutura de repositório:**
```
monitoring/
├── alerts/
│   ├── myapp-alerts.yaml          # PrometheusRule
│   └── infrastructure-alerts.yaml
├── recording_rules/
│   └── myapp-recording.yaml
├── dashboards/
│   ├── myapp-overview.json
│   └── infrastructure.json
├── alertmanager/
│   └── alertmanager.yaml
└── tests/
    └── myapp-alerts.test.yaml     # promtool unit tests
```

**Aplicar via ArgoCD:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-configs
spec:
  source:
    path: monitoring/
  destination:
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Testing Monitoring Configs

**promtool unit tests:**
```yaml
# tests/myapp-alerts.test.yaml
rule_files:
  - alerts/myapp-alerts.yaml
  - recording_rules/myapp-recording.yaml

tests:
  - interval: 1m
    input_series:
      - series: 'http_requests_total{job="myapp",status="200"}'
        values: '100+0x30'   # 100 req/s constante por 30 min
      - series: 'http_requests_total{job="myapp",status="500"}'
        values: '0+0x25 10+0x5'  # 0 por 25 min, depois 10 req/s erros

    alert_rule_test:
      - eval_time: 25m
        alertname: MyAppHighErrorRate
        exp_alerts: []  # Não deve disparar

      - eval_time: 30m
        alertname: MyAppHighErrorRate
        exp_alerts:
          - exp_labels:
              severity: critical
              service: myapp
            exp_annotations:
              summary: "High error rate on myapp"
```

**Executar testes:**
```bash
promtool test rules tests/myapp-alerts.test.yaml

# Validar sintaxe de alerting rules
promtool check rules alerts/myapp-alerts.yaml

# Validar alertmanager config
amtool check-config alertmanager/alertmanager.yaml
```

## Terraform for Monitoring

```hcl
# Grafana provider
provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_api_key
}

resource "grafana_dashboard" "myapp" {
  config_json = file("${path.module}/dashboards/myapp-overview.json")
  folder      = grafana_folder.production.id
  overwrite   = true
}

resource "grafana_alert_rule" "high_error_rate" {
  name           = "High Error Rate"
  folder_uid     = grafana_folder.production.uid
  condition      = "C"

  data {
    ref_id = "A"
    query {
      datasource_uid = var.prometheus_datasource_uid
      model = jsonencode({
        expr  = "job:http_error_rate:ratio5m{job='myapp'}"
        range = true
      })
    }
  }
}
```

## Common Mistakes / Anti-Patterns

- **Alertar em causas, não sintomas** — `CPUUtilization > 80%` raramente é acionável; `ErrorRate > 1%` é
- **Sem `for` duration** — alertas sem `for` disparam em spikes momentâneos; adicionar `for: 5m`
- **Runbook ausente** — alerta sem runbook = on-call não sabe o que fazer = escalada lenta
- **Thresholds hardcoded** — `> 0.05` pode estar correto hoje, errado amanhã; documentar baseado em SLO
- **Labels de alta cardinalidade em recording rules** — user_id, request_id como labels = Prometheus explode
- **Dashboards não versionados** — mudanças manuais no Grafana são perdidas; sempre via GitOps
- **Testar alertas nunca** — alert expression errada = alerta não dispara quando deveria
- **Inhibition rules ausentes** — alerta de componente individual dispara quando cluster inteiro está down

## Communication Style

Quando esta skill está ativa:
- Fornecer PrometheusRule YAML completo (não apenas a expressão PromQL)
- Incluir `runbook_url` em cada alerta proposto
- Recomendar promtool tests para regras novas
- Alertar sobre labels de alta cardinalidade em recording rules

## Expected Output Quality

- PrometheusRule YAML aplicável com CRD correto
- PromQL validada e testável com `promtool`
- promtool test YAML para novas regras
- Alertmanager routing config para novos alertas

---
**Skill type:** Passive
**Applies with:** observability, kubernetes, terraform, finops
**Pairs well with:** incident-agent, k8s-platform-agent, personal-engineering-agent
