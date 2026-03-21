---
name: devops-incident
description: "Guiar resposta a incidente e gerar postmortem. Orquestra SRE Engineer e Observability Engineer."
argument-hint: "[descrição-do-problema]"
---

# Incident Response: $ARGUMENTS

Guie a resposta ao incidente: **$ARGUMENTS**

## Instruções

### Step 1: Diagnóstico — Use **sre-engineer** para:
- Triage: severidade, impacto, serviços afetados
- Diagnóstico rápido: deploy recente? pods saudáveis? dependências?
- Checar métricas, logs, traces

### Step 2: Dados — Use **observability-engineer** para:
- Coletar métricas relevantes (error rate, latência, throughput)
- Correlacionar logs e traces do período
- Identificar anomalias

### Step 3: Mitigar — Use **sre-engineer** para:
- Propor ação imediata (rollback, scale, feature flag, bypass)
- Verificar se mitigação resolveu

### Step 4: Postmortem — Use **sre-engineer** para:
- Gerar postmortem blameless com timeline
- Identificar root cause
- Definir action items preventivos
- Salvar em `docs/devops/postmortems/`
