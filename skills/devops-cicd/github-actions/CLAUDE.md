# Skill: GitHub Actions

## Scope

Design e operação de pipelines CI/CD com GitHub Actions. Cobre estrutura de workflows, triggers, jobs, caching, matrix builds, reusable workflows, composite actions, secrets, autenticação OIDC (AWS), armazenamento de artifacts, segurança e otimização de custo. Aplicável a qualquer task envolvendo `.github/workflows/`.

## Related Agent: ci-agent
## Related Playbook: (use security-audit.md as CI security gate reference)

## Core Principles

- **Least privilege** — definir `permissions` em cada workflow; nunca usar permissões default
- **Pinnar actions a SHA** — `actions/checkout@v4` é mutável; `actions/checkout@11bd71901bbe...` não é
- **Fail fast** — lint e testes rápidos primeiro; não pagar por jobs lentos em código obviamente quebrado
- **Build once** — construir artifact uma vez, promover o mesmo entre ambientes; nunca rebuild por ambiente
- **Secrets não hardcoded** — todas as credenciais via GitHub Secrets, OIDC ou variáveis de ambiente
- **Concurrency control** — prevenir deploys simultâneos que causam race conditions

## Workflow Structure & Triggers

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:        # Permite runs manuais (emergências, reruns)

# Cancelar runs em andamento do mesmo PR/branch
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Permissões mínimas no nível do workflow
permissions:
  contents: read
```

**Trigger best practices:**
- `pull_request` roda no merge commit (não HEAD da branch) — segredos de ambiente não acessíveis
- PRs de forks NÃO têm acesso a secrets; usar `pull_request_target` com extremo cuidado
- `paths:` filters para pular CI em mudanças de docs/config:
  ```yaml
  on:
    push:
      paths: ['src/**', 'package.json', '.github/workflows/**']
  ```

## Job & Step Design

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10        # SEMPRE definir timeout
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af  # v4.1.0
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint              # Gate: só roda se lint passou
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        if: failure()          # Upload apenas em falha (não desperdiça storage)
        with:
          name: test-results-${{ github.sha }}
          path: test-results/
          retention-days: 7
```

**Regras de design:**
- `needs:` para forçar ordering e evitar computação desperdiçada
- `timeout-minutes` em todos os jobs que fazem chamadas de rede
- Scripts complexos em `.github/scripts/` para testabilidade (não inline)
- `continue-on-error: true` apenas para steps diagnósticos, nunca para security gates

## Secrets & Environment Management

```yaml
jobs:
  deploy:
    environment: production      # Requer aprovação se configurado nas repo settings
    env:
      NODE_ENV: production
    steps:
      - run: ./deploy.sh
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
```

**Regras:**
- **Environment secrets** (production, staging) são mais restritos que repo secrets
- Configurar **Required reviewers** no environment `production` nas repo settings
- Nunca `echo` um secret — GitHub mascara valores conhecidos, mas structured secrets podem vazar como substrings
- `${{ secrets.NAME }}` apenas nos steps que precisam; não exportar para env global sem necessidade

## OIDC Authentication (AWS — sem access keys)

OIDC elimina credenciais estáticas de longa duração. GitHub troca um JWT por credenciais de curta duração.

**Setup AWS (uma vez por conta):**
```bash
# Criar OIDC provider no IAM (uma vez por conta AWS)
# Trust policy do IAM Role:
```
```json
{
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:org/repo:environment:production"
      }
    }
  }]
}
```

**Uso no workflow:**
```yaml
permissions:
  id-token: write        # Obrigatório para OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502  # v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
          aws-region: us-east-1
      - run: aws s3 sync dist/ s3://my-bucket/
```

**Importante:** Restringir a claim `sub` a um environment específico — impede que um PR workflow assuma role de produção.

## Caching Strategies

```yaml
# Node.js — usar setup-node built-in cache (preferido)
- uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af
  with:
    node-version: '20'
    cache: 'npm'            # chave automática no package-lock.json

# Cache manual (pip, Go modules, etc.)
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-

# Docker layer caching com buildx
- uses: docker/build-push-action@v6
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Regras de cache:**
- Chave no hash do lockfile (`hashFiles`), nunca timestamp
- `restore-keys` para fallback em cache parcial (ex: nova branch usa cache de main)
- Cache entries expiram após 7 dias sem acesso; máximo 10GB por repo

## Matrix Builds

```yaml
jobs:
  test:
    strategy:
      fail-fast: false           # Não cancela todos se um falhar
      matrix:
        node: [18, 20, 22]
        os: [ubuntu-latest, windows-latest]
        exclude:
          - os: windows-latest
            node: 18
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af
        with:
          node-version: ${{ matrix.node }}
```

**Custo:** Uma matrix 3×2 = 6 jobs × duração. Avaliar se matrix completa é necessária em cada PR, ou apenas em push para main:
```yaml
strategy:
  matrix:
    node: ${{ github.event_name == 'push' && fromJSON('[18, 20, 22]') || fromJSON('[20]') }}
```

## Reusable Workflows & Composite Actions

**Reusable workflow** (workflow chamado por outro workflow):
```yaml
# .github/workflows/deploy-reusable.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      DEPLOY_TOKEN:
        required: true
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - run: ./deploy.sh ${{ inputs.environment }}
        env:
          TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

**Chamando:**
```yaml
jobs:
  deploy-staging:
    uses: org/repo/.github/workflows/deploy-reusable.yml@main
    with:
      environment: staging
    secrets:
      DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

**Composite action** (steps reutilizáveis dentro de um job):
```yaml
# .github/actions/setup-app/action.yml
name: Setup App
runs:
  using: composite
  steps:
    - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af
      with:
        node-version: '20'
        cache: 'npm'
    - run: npm ci
      shell: bash
```

## Artifact Management

```yaml
# Upload artifact imutável com SHA
- uses: actions/upload-artifact@v4
  with:
    name: dist-${{ github.sha }}
    path: dist/
    retention-days: 30          # Reduzir do default de 90 dias para economizar

# Download em job posterior
- uses: actions/download-artifact@v4
  with:
    name: dist-${{ github.sha }}
    path: dist/
```

**Regras:**
- Nomear artifacts com `${{ github.sha }}` para rastreabilidade
- `retention-days` explícito — defaults são caros em escala
- Para promoção cross-run, usar registry (ECR, GHCR, S3) não artifacts

## Security Hardening

```yaml
# Permissões mínimas a nível de workflow
permissions:
  contents: read

jobs:
  build:
    permissions:
      contents: read
      packages: write        # Apenas se precisa fazer push para GHCR
```

**Checklist:**
- Pinnar todas as actions de terceiros a SHA completo
- Habilitar Dependabot para atualizações de actions (`/.github/dependabot.yml`)
- Nunca usar `pull_request_target` com código de forks sem entender o modelo de segurança
- Security scanning de imagens antes de push:
  ```yaml
  - uses: aquasecurity/trivy-action@master
    with:
      image-ref: ${{ env.IMAGE }}
      exit-code: '1'
      severity: 'CRITICAL,HIGH'
  ```

## Common Mistakes / Anti-Patterns

- **Tags mutáveis** (`@v4`) — tag pode ser força; sempre pinnar a SHA completo
- **`permissions: write-all`** — nunca usar; definir mínimo necessário
- **Secrets em `run: echo`** — GitHub mascara valores conhecidos, mas pode vazar em parsing
- **Sem concurrency control** — deploys paralelos para o mesmo ambiente causam race conditions
- **Rebuild por ambiente** — quebra imutabilidade; build uma vez, promover o artifact
- **Sem `timeout-minutes`** — job travado bloqueia queue e aumenta custo
- **Matrix completo em cada PR** — muito caro; restringir a push/schedule
- **`continue-on-error: true` em security gates** — desabilita o gate; SAST sem gate = teatro

## Communication Style

Quando esta skill está ativa:
- Fornecer YAML completo e funcional, não snippets parciais
- Incluir SHA pin em referências de actions novas
- Alertar sobre escalação de permissões e explicar por quê é necessário
- Proativamente sugerir caching e concurrency controls em novos workflows

## Expected Output Quality

- YAML sintaticamente válido seguindo o schema do GitHub Actions
- Actions de terceiros com SHA pin ou nota explícita de que é necessário pinnar
- Exemplos OIDC incluem tanto a trust policy AWS quanto a configuração do workflow
- Exemplos de reusable workflow mostram tanto definição quanto chamador

---
**Skill type:** Passive
**Applies with:** ci-cd, git, docker-ci, aws, terraform
**Pairs well with:** ci-agent, personal-engineering-agent
