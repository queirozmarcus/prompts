---
name: devops-audit
description: "Auditoria completa de infraestrutura: segurança, custo, resiliência, compliance. Opcionalmente focada em um serviço."
argument-hint: "[serviço-ou-namespace (opcional)]"
---

# Auditoria de Infraestrutura

Execute auditoria completa da infraestrutura do projeto.

## Instruções

### Step 1: Análises em paralelo

1. **Security Ops** (subagent: security-ops)
   - Hardening checklist (pods, network, secrets, RBAC, images)
   - Vulnerabilidades em images e dependências
   - Network policies adequadas?
   - Secrets gerenciados corretamente?

2. **DevOps Lead** (subagent: devops-lead)
   - FinOps: custo por serviço, rightsizing, waste
   - Recursos over/under-provisioned
   - Oportunidades de spot, reserved, scale-to-zero

3. **Kubernetes Engineer** (subagent: kubernetes-engineer)
   - Resources requests vs limits vs uso real
   - Probes configuradas corretamente?
   - PDB, topology spread, graceful shutdown
   - HPA configurado e respondendo?

4. **SRE Engineer** (subagent: sre-engineer)
   - SLOs definidos e monitorados?
   - Runbooks existem e estão atualizados?
   - DR plan validado?
   - Último game day?

### Step 2: Consolidar como **devops-lead**:
- Score por área (segurança, custo, resiliência, observabilidade)
- Top 10 riscos ordenados por impacto
- Quick wins (alto impacto, baixo esforço)
- Plano de ação priorizado
