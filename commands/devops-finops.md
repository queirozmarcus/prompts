---
name: devops-finops
description: "Análise de custo e otimização FinOps. Orquestra FinOps Engineer e DevOps Lead."
argument-hint: "[serviço-ou-conta (opcional)]"
---

# Análise FinOps: $ARGUMENTS

Analise custos e proponha otimizações para **$ARGUMENTS**.

## Instruções

### Step 1: Análise de custo

Use o sub-agente **finops-engineer** para:
- Mapear custo por categoria (compute, database, networking, storage)
- Identificar recursos over-provisioned (rightsizing candidates)
- Identificar waste (idle ELBs, unattached EBS, orphaned snapshots)
- Analisar cobertura de Savings Plans / Reserved Instances
- Calcular custo por serviço se possível

### Step 2: Recomendações

Use o sub-agente **devops-lead** para:
- Priorizar otimizações por economia estimada vs esforço
- Avaliar trade-offs (ex: spot vs on-demand, reserva 1yr vs 3yr)
- Definir quick wins vs investimentos de médio prazo

### Step 3: Apresentar

1. Custo atual por categoria
2. Top 5 oportunidades com economia estimada
3. Quick wins implementáveis imediatamente
4. Plano de ação priorizado
