# Skill: Terraform

## Scope

Infrastructure as Code com Terraform para provisionamento declarativo em AWS e multi-cloud. Cobre estrutura de código, gerenciamento de estado, módulos, backends, workspaces, segurança, estimativa de custo e integração com CI/CD. Aplicável a qualquer task de IaC com Terraform ou Terragrunt.

## Core Principles

- **Declarativo e idempotente** — estado desejado está no código; `apply` pode ser executado N vezes com o mesmo resultado
- **State is truth** — o state file é a fonte de verdade da infraestrutura; proteja-o como um banco de dados
- **Plan before apply** — nunca executar `apply` sem revisar o plan; destruições acidentais são irreversíveis
- **Blast radius awareness** — isolar ambientes em state files separados; prod e dev nunca no mesmo state
- **Code review for infrastructure** — mudanças de infra passam por PR com revisão e CI/CD checks
- **Modules for reuse** — código duplicado em Terraform é tão problemático quanto em software

## Code Organization & Structure

**Estrutura recomendada (flat, por ambiente):**
```
infrastructure/
├── environments/
│   ├── production/
│   │   ├── main.tf          # Resource instantiation, module calls
│   │   ├── variables.tf     # Input declarations com type + description
│   │   ├── outputs.tf       # Outputs para outros stacks referenciarem
│   │   ├── terraform.tf     # required_providers + backend config
│   │   ├── locals.tf        # Computed values, common tags
│   │   └── terraform.tfvars # Environment-specific values
│   └── staging/
│       └── ...
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecs-service/
        └── ...
```

**Com Terragrunt (DRY para múltiplos ambientes):**
```
infrastructure/
├── terragrunt.hcl              # Root: backend, provider defaults
├── _envcommon/
│   └── vpc.hcl                # Shared module config
├── production/
│   ├── account.hcl
│   ├── vpc/terragrunt.hcl
│   └── ecs/terragrunt.hcl
└── staging/
    └── ...
```

**Responsabilidade por arquivo:**
- `main.tf` — recursos principais e chamadas de módulos
- `variables.tf` — declarações com `description`, `type`, `validation`
- `outputs.tf` — outputs para cross-stack references
- `terraform.tf` — versões de providers + configuração de backend
- `locals.tf` — valores computados localmente (tags comuns, nomes padronizados)

## State Management

**Backend remoto obrigatório para produção (S3 + DynamoDB):**
```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "production/ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:key/mrk-xxx"
    dynamodb_table = "terraform-locks"
  }
}
```

**DynamoDB table para state locking:**
```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = { ManagedBy = "terraform" }
}
```

**Comandos de state (usar com cuidado):**
```bash
terraform state list                           # Listar todos os recursos
terraform state show aws_instance.web          # Inspecionar recurso específico
terraform state mv module.old module.new       # Renomear sem destruir (ANTES do apply)
terraform state rm aws_security_group.temp     # Remover do state (NÃO destrói recurso real)
terraform import aws_instance.web i-12345678   # Importar recurso existente
terraform force-unlock LOCK_ID                 # Liberar lock preso (cuidado: só se certeza)
```

**Nunca:** editar o `.tfstate` diretamente — JSON corrompido requer disaster recovery.

## Module Design

**Quando criar um módulo:**
- Conjunto de recursos usado em 3+ lugares
- Padrão com defaults opinionados que o time concorda
- Abstração de complexidade (VPC com subnets + routing + IGW como uma unidade)

**Boas práticas:**
```hcl
# variables.tf — sempre com type, description e validação
variable "instance_type" {
  description = "EC2 instance type. Only t3/t4g family allowed."
  type        = string
  default     = "t3.micro"
  validation {
    condition     = can(regex("^(t3|t4g)\\.", var.instance_type))
    error_message = "Only t3 or t4g instance families are allowed."
  }
}

# outputs.tf — expõe o que outros módulos precisam
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB for target group attachment"
  value       = aws_lb.main.arn
}
```

**Versionamento de módulos:**
```hcl
# Módulo público (Terraform Registry)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Tilde: minor OK, breaking changes não
}

# Módulo interno (Git + tag)
module "ecs_service" {
  source = "git::https://github.com/org/tf-modules.git//ecs-service?ref=v1.2.0"
}

# Módulo local (desenvolvimento)
module "my_module" {
  source = "../modules/my-module"
}
```

## Variable & Output Best Practices

```hcl
# Variáveis sensíveis — não aparecem em outputs/logs
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# Objetos tipados (mais seguro que `any`)
variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# Locals para padronização de nomes e tags
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Team        = var.team
    CostCenter  = var.cost_center
  })
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"
  tags   = local.common_tags
}
```

**`for_each` vs `count`:**
```hcl
# Ruim: count (índices mudam ao remover itens do meio)
resource "aws_subnet" "private" {
  count = length(var.private_cidrs)
  cidr_block = var.private_cidrs[count.index]
}

# Bom: for_each com map (chave estável)
resource "aws_subnet" "private" {
  for_each   = { for s in var.subnets : s.name => s }
  cidr_block = each.value.cidr
  tags       = { Name = each.key }
}
```

## Security in Terraform

**Secrets — nunca em código ou state sem criptografia:**
```hcl
# Nunca hardcoded
resource "aws_db_instance" "main" {
  password = "mysecretpassword"  # NUNCA FAZER ISSO
}

# Correto: referência ao Secrets Manager
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "${local.name_prefix}/db-password"
}
resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
  manage_master_user_password = false
}
```

**OIDC para CI/CD (sem access keys):**
```hcl
data "aws_iam_policy_document" "terraform_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:my-org/infra:ref:refs/heads/main"]
    }
  }
}
```

**Recursos críticos — proteger contra destruição acidental:**
```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

## Cost Management (Infracost)

**Infracost is a mandatory pre-flight gate** — run before every plan, fail the CI pipeline if monthly cost increases > threshold.

```bash
# Instalar
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Estimativa do diretório atual
infracost breakdown --path .

# Diff de custo entre branches (uso em PRs) — OBRIGATÓRIO antes de apply
infracost diff --path . --compare-to origin/main --format table

# Output JSON para integração com CI
infracost diff --path . --compare-to origin/main --format json --out-file infracost.json

# Verificar custo absoluto do ambiente
infracost breakdown --path . --format table

# Threshold gate: falhar se custo mensal aumentar > $100
COST_DELTA=$(infracost diff --path . --compare-to origin/main --format json | jq '.diffTotalMonthlyCost' -r | cut -d. -f1)
if [ "${COST_DELTA}" -gt 100 ]; then
  echo "❌ Cost increase ${COST_DELTA}/month exceeds $100 threshold. Review required."
  exit 1
fi
```

**GitHub Actions — comentário de custo em PRs:**
```yaml
- uses: infracost/actions/setup@v3
  with:
    api-key: ${{ secrets.INFRACOST_API_KEY }}
- run: infracost diff --path . --format json --out-file infracost.json
- uses: infracost/actions/comment@v3
  with:
    path: infracost.json
    behavior: update
```

## Module Patterns: Workspaces vs Directory per Environment

**Workspaces** (use for testing, NOT for production separation):
```hcl
# Workspaces share state backend — risky for prod/dev separation
# Good for: ephemeral environments, feature branch testing
terraform workspace new feature-xyz
terraform workspace select feature-xyz
terraform plan  # Uses workspace-scoped state
terraform workspace delete feature-xyz
```

**Directory per environment** (preferred for prod/staging isolation):
```
environments/
├── production/    # Separate state, separate apply command, separate IAM role
├── staging/       # Independent state file
└── sandbox/       # Dev/test environments
```

**Rule:** Production and staging/dev must NEVER share a Terraform state file. Directory-per-environment is the only safe pattern for production workloads.

**When workspaces are acceptable:**
- Ephemeral review environments created and destroyed per PR
- Test infrastructure that mirrors a single config with small variations
- Never for production vs staging separation

## Testing (fmt, validate, tflint, checkov)

**Pipeline de validação obrigatório:**
```bash
# 1. Formatação
terraform fmt -check -recursive

# 2. Validação de sintaxe e referências
terraform init -backend=false
terraform validate

# 3. Lint de boas práticas e tipos
tflint --recursive --config .tflint.hcl

# 4. Security scan de IaC
checkov -d . --framework terraform --compact --quiet \
  --skip-check CKV_AWS_123  # Documentar cada skip com justificativa

# 5. Custo (opcional mas recomendado)
infracost diff --path . --format table
```

**tflint config com ruleset AWS:**
```hcl
# .tflint.hcl
plugin "aws" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
  version = "~> 0.30"
}
```

## CI/CD Integration

**GitHub Actions — plan em PR, apply em main:**
```yaml
on:
  pull_request:
    paths: ['infrastructure/**']
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write    # Para OIDC
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/terraform-ci
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.7"
      - run: terraform init
      - run: terraform fmt -check
      - run: terraform validate
      - run: terraform plan -out=tfplan -no-color
        if: github.event_name == 'pull_request'
      - run: terraform apply -auto-approve
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

## Common Mistakes / Anti-Patterns

- **`terraform apply` sem revisar `plan`** — destruições passam despercebidas
- **State local** — impossível colaborar, sem locking, sem histórico
- **Credentials hardcoded** — use OIDC/roles, nunca access keys no CI
- **Módulos sem `version`** — `source = "module/vpc"` sem versão quebra builds futuramente
- **Tudo em um state** — prod e dev no mesmo state = blast radius enorme
- **`count` para recursos condicionais** — índices se re-ordenam ao remover items; use `for_each`
- **`depends_on` excessivo** — geralmente indica módulo mal estruturado ou referência implícita
- **Sem `lifecycle { prevent_destroy = true }`** em RDS, S3 com dados, volumes críticos
- **`terraform taint`** — deprecado desde v0.15; usar `terraform apply -replace=resource.name`
- **Segredos em `terraform.tfvars`** — commitar por acidente expõe credenciais; use variáveis de ambiente

## Communication Style

Quando esta skill está ativa:
- Fornecer HCL completo e funcional, não pseudocódigo
- Incluir `description` em todas as variáveis e outputs
- Mencionar impacto no state quando renomear/mover recursos
- Alertar sobre mudanças destrutivas (`-/+ destroy and recreate`)
- Recomendar `lifecycle` blocks para recursos com dados persistentes
- Indicar se mudança exige `terraform init` (novo provider/backend/módulo)

## Expected Output Quality

- Blocos HCL completos com tipos, descriptions e validações
- Distinguish between `plan` (safe, read-only) e `apply` (executa mudanças)
- Listar pre-requisites (state bucket, DynamoDB table, OIDC provider para CI)
- Análise de blast radius antes de mudanças destrutivas

---
**Skill type:** Passive
**Applies with:** aws, kubernetes, security, finops, github-actions, ci-cd
**Pairs well with:** architect (Dev pack), iac-engineer (DevOps pack)
