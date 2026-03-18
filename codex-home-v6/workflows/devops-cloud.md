
# Arquitetura Cloud AWS: $ARGUMENTS

Analise, projete ou otimize infraestrutura AWS para **$ARGUMENTS**.

## Instruções

### Step 1: Análise de contexto

Use o subagente **aws-cloud-engineer** para:
- Identificar serviços AWS envolvidos (EKS, ECS, RDS, ALB, etc.)
- Avaliar arquitetura atual (se existente)
- Mapear requisitos: disponibilidade, performance, custo, compliance

### Step 2: Design ou otimização

Ainda com **aws-cloud-engineer**:
- Propor arquitetura com diagrama textual (serviços, fluxos, networking)
- Avaliar trade-offs: EKS vs ECS, Aurora vs RDS, NAT Gateway vs VPC Endpoints
- Estimar custo mensal por componente
- Recomendar IAM policies (least privilege)

### Step 3: Segurança

Use o subagente **security-ops** para:
- Validar IAM roles e policies
- Verificar encryption at rest e in transit
- Avaliar VPC design (subnets, SGs, NACLs)
- Checklist de compliance (se aplicável)

### Step 4: Apresentar

1. Arquitetura proposta com justificativa
2. Estimativa de custo
3. Riscos e mitigações
4. Próximos passos (IaC com `/devops-provision`)
