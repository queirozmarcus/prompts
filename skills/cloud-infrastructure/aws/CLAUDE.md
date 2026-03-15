# Skill: AWS

## Scope

Arquitetura, operação e otimização de recursos na AWS. Cobre o ciclo completo: design de solução, provisionamento, segurança, custo e observabilidade. Aplicável quando trabalhando com qualquer serviço AWS — EC2, ECS, EKS, S3, RDS, IAM, VPC, Lambda, Step Functions, EventBridge, CloudWatch, ALB/NLB.

## Core Principles

- **Production-first** — toda decisão considera impacto em produção antes de implementar
- **Least privilege** — IAM roles, security groups, bucket policies: negar por padrão, permitir explicitamente
- **Cost-aware architecture** — cada serviço tem custo; design considera TCO, não só funcionalidade
- **Immutable infrastructure** — substituir instâncias, não mutá-las; use AMIs, ECS tasks, não SSH para mudanças
- **Multi-AZ by default** — single-AZ é anti-padrão para cargas de produção
- **Tag everything** — billing, ownership, environment: tags são auditáveis e obrigatórias

## IAM & Security

**Hierarquia de identidades (preferir nesta ordem):**
1. **IAM Roles** — para EC2, ECS tasks, Lambda, EKS pods (IRSA) — nunca armazena credenciais
2. **IAM Identity Center** — para acesso humano (SSO, federação)
3. **IAM Users com MFA** — apenas quando roles não são viáveis
4. **Root account** — apenas para billing e bootstrap; MFA obrigatório, sem access keys

**Políticas — boas práticas:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/prefix/*",
    "Condition": {
      "StringEquals": {"aws:RequestedRegion": "us-east-1"},
      "Bool": {"aws:SecureTransport": "true"}
    }
  }]
}
```

**IRSA para EKS (IAM Roles for Service Accounts):**
```bash
eksctl create iamserviceaccount \
  --name myapp \
  --namespace production \
  --cluster my-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
```

**Guardrails com SCPs (Organization level):**
- Deny sem MFA para ações destrutivas
- Deny fora das regiões aprovadas (`aws:RequestedRegion`)
- Deny criação de IAM Users (força IAM Identity Center)
- Deny desabilitação de CloudTrail e GuardDuty

## Compute (EC2 / ECS / EKS)

**Escolha de serviço:**

| Cenário | Serviço | Motivo |
|---------|---------|--------|
| Workload containerizada, sem gerenciar K8s | ECS Fargate | Simplicidade, sem node management |
| Microserviços complexos, K8s ecosystem | EKS | Flexibilidade, ecosystem |
| Controle total do OS, performance tuning | EC2 + ASG | Customização |
| Batch/jobs esporádicos | Lambda, Fargate Spot | Custo, serverless |
| Workloads tolerantes a interrupção | EC2 Spot Fleet | 70-90% de economia |

**EC2 Sizing — preferir Graviton:**
- `t4g`/`t3` para workloads burstáveis (dev, low-traffic)
- `m7g`/`m6i` para uso geral em produção (m7g é Graviton3, 20-40% mais barato)
- `c7g`/`c6i` para compute-intensive
- `r7g`/`r6i` para memory-intensive (databases, cache)

**Auto Scaling — Target Tracking (preferir sobre Step):**
```hcl
resource "aws_autoscaling_policy" "cpu" {
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0  # Alvo 60% deixa headroom para picos
  }
}
```

## Storage (S3 / EBS / EFS)

**S3 — Security baseline:**
```bash
# Bloquear acesso público (obrigatório em nível de conta)
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**S3 Storage Classes (custo decrescente):**
- **Standard** — acesso frequente (~$0.023/GB/mês us-east-1)
- **Intelligent-Tiering** — acesso imprevisível, auto-tier
- **Standard-IA** — acesso infrequente ($0.0125/GB)
- **Glacier Instant Retrieval** — archives, recuperação em milissegundos
- **Glacier Flexible** — acesso em 3-5h, muito mais barato ($0.004/GB)

**Lifecycle Policy (logs padrão):**
```json
{
  "Rules": [{
    "Status": "Enabled",
    "Transitions": [
      {"Days": 30, "StorageClass": "STANDARD_IA"},
      {"Days": 90, "StorageClass": "GLACIER_IR"}
    ],
    "Expiration": {"Days": 365}
  }]
}
```

**EBS:**
- `gp3` é 20% mais barato que `gp2` e com IOPS configurável independente do tamanho
- `io2` para databases de alta performance (RDS Provisioned IOPS)
- Snapshots incrementais — fazer antes de mudanças destrutivas

## Networking (VPC / ALB / Route53)

**VPC Design — 3 camadas:**
```
Public Subnets   (10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24)   — ALB, NAT GW, Bastion
Private Subnets  (10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24) — EC2, ECS, EKS nodes
Data Subnets     (10.0.20.0/24, 10.0.21.0/24, 10.0.22.0/24) — RDS, ElastiCache
```

**CIDR Planning:**
- VPC: `/16` (65.536 IPs) — planeja para crescimento e peering
- Subnets: `/24` (256 IPs) por AZ por tier — 3 AZs × 3 tiers = 9 subnets
- Reserve blocos distintos por VPC para evitar conflito em peering

**NAT Gateway — alto custo:**
- $0.045/hora por NAT GW + $0.045/GB processado
- Uma NAT GW por AZ para HA (~$33/mês/AZ, mais tráfego)
- **Otimização:** VPC Endpoints para S3 e DynamoDB (gratuitos, Gateway type)
- Para workloads com alto egress: avaliar NAT Instance (mais barato, menos HA)

**ALB vs NLB:**
- **ALB** (Layer 7): HTTP/HTTPS routing, path/host-based, autenticação, WAF — padrão para APIs REST
- **NLB** (Layer 4): TCP/UDP, ultra-baixa latência, IPs estáticos, TLS passthrough — para gRPC, WebSockets

## Database (RDS / DynamoDB / ElastiCache)

**RDS:**
- Multi-AZ para produção (failover automático ~1-2 min, standby em outra AZ)
- Read Replicas para escalar leituras (não é failover automático)
- Aurora: storage auto-scale, multi-region, serverless v2 — considerar para produção crítica
- RDS Proxy: pooling de conexões para Lambda e workloads com muitas conexões curtas
- Encryption at rest com customer-managed KMS key (não default AWS managed)

**DynamoDB:**
- Partition key: alta cardinalidade, distribuição uniforme de acesso
- Sort key: permite queries de range eficientes (timestamp, ID ordenável)
- **On-Demand**: tráfego imprevisível; **Provisioned + Auto Scaling**: tráfego estável e previsível
- TTL: expirar itens automaticamente sem custo de delete

**ElastiCache:**
- Redis para session store, pub/sub, rate limiting, leaderboards
- `cache.r7g` (Graviton3) para melhor custo-performance
- Cluster mode com sharding para escala horizontal

## Cost Awareness

**Purchasing Options:**

| Tipo | Desconto | Melhor para |
|------|----------|-------------|
| On-Demand | baseline | Tráfego imprevisível, picos temporários |
| Compute Savings Plans | até 66% | EC2 + Fargate, qualquer região/família |
| EC2 Savings Plans | até 72% | Comprometido com região + família específica |
| Reserved Instances | até 72% | RDS, ElastiCache, OpenSearch (sem Savings Plans) |
| Spot | 70-90% | Batch, CI/CD, stateless, tolerante a interrupção |

**Regra prática:** Compute Savings Plans para 70% do baseline EC2/Fargate; On-Demand para pico; Spot para batch.

**Custos "surpresa" comuns:**
- **NAT Gateway tráfego inter-AZ:** tráfego entre AZs passando por NAT cobra duas vezes
- **Data Transfer out:** AWS → internet $0.09/GB (primeiros 10TB us-east-1)
- **CloudWatch Logs:** ingestão $0.50/GB + armazenamento + queries Logs Insights
- **ALB:** por hora (~$0.008) + por LCU processado
- **Snapshots EBS/RDS:** cobrado por GB armazenado (incremental mas acumula)

**Tagging obrigatório (habilitar Cost Allocation Tags):**
```
Environment: production|staging|dev
Team:        platform|backend|data
CostCenter:  eng-platform
Project:     myapp
ManagedBy:   terraform
```

## Observability (CloudWatch / X-Ray)

**Métricas críticas por serviço:**
```
EC2:  CPUUtilization, NetworkIn/Out, StatusCheckFailed
ECS:  CPUUtilization, MemoryUtilization, RunningTaskCount
ALB:  HTTPCode_Target_5XX_Count, TargetResponseTime, HealthyHostCount
RDS:  CPUUtilization, DatabaseConnections, FreeableMemory, ReadLatency
EKS:  cluster_failed_node_count, node_cpu_utilization, node_memory_utilization
```

**CloudWatch Logs Insights — queries úteis:**
```sql
-- Top erros por hora
fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as count by bin(1h)
| sort count desc

-- ALB 5xx por target
fields @timestamp, targetProcessingTime, requestUri, targetStatusCode
| filter targetStatusCode >= 500
| stats count(*) as errors by targetStatusCode, requestUri
| sort errors desc | limit 20
```

**Alarms de produção — exemplos:**
```bash
# CPU alto
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-ecs-cpu-high" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 --evaluation-periods 2 \
  --threshold 85 --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:123:prod-alerts
```

## Security Best Practices

**Checklist de conta AWS:**
- [ ] Root MFA habilitado, zero access keys de root
- [ ] CloudTrail habilitado em todas as regiões, logs encriptados em S3
- [ ] GuardDuty habilitado (detecção de ameaças com ML)
- [ ] SecurityHub habilitado (CIS Benchmark, AWS Foundational Security)
- [ ] AWS Config habilitado com rules de conformidade
- [ ] IAM Access Analyzer (identifica recursos expostos externamente)
- [ ] S3 Block Public Access em nível de conta (não só por bucket)
- [ ] Password policy forte para IAM Users (se usados)
- [ ] VPC Flow Logs habilitado para auditoria de tráfego
- [ ] IMDSv2 obrigatório em todas as instâncias EC2 (bloqueia SSRF → metadata)

## Common Mistakes / Anti-Patterns

- **Wildcard `*` em IAM** — "temporário" vira permanente; ARNs específicos são a regra
- **Single-AZ para produção** — um AZ down = outage completo
- **Não usar VPC Endpoints** — paga NAT Gateway para acessar S3/DynamoDB dentro da AWS
- **EBS gp2 ao invés de gp3** — gp3 é mais barato e IOPS é independente do tamanho
- **CloudWatch Logs sem retention** — armazena para sempre, custo crescente e contínuo
- **Security groups egress 0.0.0.0/0** — padrão permissivo demais; restringir por workload
- **On-Demand para workloads 24/7 estáveis** — Savings Plans pagam em 12-18 meses
- **Sem tags de billing** — impossível alocar custos por time/projeto; débito técnico
- **IMDSv1 habilitado** — vulnerável a SSRF (atacante pode roubar role credentials)
- **Acesso direto via SSH para mudanças** — use SSM Session Manager; sem portas 22 abertas

## Communication Style

Quando esta skill está ativa:
- Mencionar o serviço AWS específico (não "load balancer" mas "ALB" ou "NLB")
- Incluir estimativas de custo quando a decisão envolve trade-offs financeiros
- Citar limites de serviço quando relevante (ex: ALB: 100 regras por listener)
- Preferir exemplos em Terraform/IaC ao invés de console steps
- Alertar sobre operações que afetam produção (plan antes de apply, snapshot antes de migração)

## Expected Output Quality

- Terraform resource blocks ou AWS CLI commands quando implementação é solicitada
- Referência a serviços com nomes exatos da AWS (não abreviações inventadas)
- Estimativa de custo quando relevante ("~$X/mês com traffic Y GB")
- Análise de trade-offs ao recomendar serviços (custo vs complexidade vs performance)
- Listagem de pre-requisites (VPC existente, IAM permissions, subnets tags para EKS)

---
**Skill type:** Passive
**Applies with:** terraform, kubernetes, security, finops, observability, networking
**Pairs well with:** personal-engineering-agent, aws-platform-agent
