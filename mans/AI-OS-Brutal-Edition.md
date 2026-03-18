# AI-OS Backend & DevOps — Brutalist Operational Edition

## 🎯 Filosofia
Um comando = uma ação clara.
Sem ambiguidade. Sem teoria desnecessária.

---

## 🔥 ÁRVORE DE DECISÃO RÁPIDA

Se o problema for:

- API não responde → /analyze-logs → /k8s-debug
- Pod reiniciando → /k8s-debug
- Deploy falhou → /deploy-debug
- Infra divergente → /terraform-drift
- Latência alta → /analyze-performance
- Novo serviço → /design-service

---

## ⚡ COMANDOS ESSENCIAIS

### /design-service
**Objetivo:** Criar microserviço production-ready

**Lite:**
"Crie um microserviço Spring Boot com Postgres, Redis e Docker"

**Full:**
"Crie um microserviço Spring Boot com:
- Clean Architecture
- PostgreSQL + Redis
- Observabilidade (Prometheus)
- Docker + K8s manifests
- Testcontainers
- Pronto para autoscaling em EKS com spot"

---

### /k8s-debug
**Objetivo:** Diagnosticar problema em pod

**Lite:**
"Analise esse erro de pod CrashLoopBackOff"

**Full:**
"Analise logs e eventos desse pod:
- Identifique causa raiz
- Sugira correção
- Valide readiness/liveness
- Avalie limites de CPU/memória"

---

### /terraform-apply
**Objetivo:** Infra segura e idempotente

**Lite:**
"Crie Terraform para ECS + ALB"

**Full:**
"Crie Terraform com:
- ECS Fargate
- ALB
- Auto scaling
- Logs no CloudWatch
- Tags FinOps
- Segurança IAM mínima"

---

### /analyze-logs
**Objetivo:** Entender falhas reais

**Lite:**
"Explique esse log"

**Full:**
"Analise esse log:
- Classifique erro
- Identifique causa raiz
- Sugira fix
- Sugira métricas para monitoramento"

---

## 🔁 WORKFLOW REAL — INCIDENTE EM PRODUÇÃO

1. /analyze-logs
2. /k8s-debug
3. /analyze-performance
4. /deploy-debug (se necessário)

---

## 🚨 PLAYBOOK — POD CRASHLOOP

Checklist:
- Ver logs → /analyze-logs
- Ver eventos → kubectl describe
- Validar env vars
- Validar DB connection
- Validar memória

---

## 🧠 NÍVEIS

### Iniciante
Usa comandos Lite

### Intermediário
Usa Full + valida respostas

### Avançado
Encadeia comandos

### Expert
Orquestra agentes + automatiza decisões

---

## ❌ ERRO REAL

Prompt ruim:
"não funciona"

Prompt correto:
"Pod em CrashLoopBackOff com erro de conexão PostgreSQL, logs abaixo:"

---

## ⚡ HACKS

- Sempre dar contexto
- Sempre pedir causa raiz
- Sempre pedir melhoria

---

## 🚀 REGRA FINAL

IA não substitui você.
Ela amplifica sua capacidade de decisão.
