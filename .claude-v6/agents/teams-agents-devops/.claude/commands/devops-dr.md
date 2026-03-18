---
name: devops-dr
description: "Planejar e validar disaster recovery. Orquestra SRE Engineer, DevOps Lead e IaC Engineer."
argument-hint: "[nome-do-serviço]"
---

# Disaster Recovery: $ARGUMENTS

Planeje e valide DR para **$ARGUMENTS**.

## Instruções

### Step 1: DR Plan — Use **sre-engineer** para:
- Definir RTO/RPO por cenário (pod crash, node, AZ, region, DB)
- Criar procedimentos de recovery por cenário
- Definir critérios de failover e failback

### Step 2: IaC — Use **iac-engineer** para:
- Verificar que infra é reprodutível via Terraform (rebuild from scratch)
- Validar backups automatizados (RDS snapshots, PV backups)
- Cross-region replication se RTO < 30min

### Step 3: Game Day — Use **sre-engineer** para:
- Planejar game day para validar DR
- Definir hipóteses e experimentos
- Salvar plano em `docs/devops/disaster-recovery/`

### Step 4: Custo — Use **devops-lead** para:
- Estimar custo do DR (standby, cross-region, backups)
- Trade-off: RTO menor = custo maior
