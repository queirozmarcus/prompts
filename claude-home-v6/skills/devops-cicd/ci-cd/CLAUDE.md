# Skill: CI/CD

## Scope

Design e operação de pipelines CI/CD end-to-end. Cobre sequenciamento de stages, quality gates, imutabilidade de artifacts, promoção entre ambientes, estratégias de deployment (rolling, blue-green, canary), rollback, integração de segurança, observabilidade e feature flags. Assume GitHub Actions como plataforma CI, workloads em AWS/Kubernetes.

## Core Principles

- **Build once, promote everywhere** — artifact construído no CI é exatamente o que roda em produção
- **Every stage is a gate** — se um stage falha, o pipeline para; sem exceções "desta vez"
- **Shift security left** — SAST, SCA e image scanning rodam no CI, não como afterthought pós-merge
- **Fail fast** — stages mais baratos/rápidos primeiro; não pagar por jobs lentos em código quebrado
- **Rollback deve ser mais rápido que redeploy** — se rollback leva mais de 5 min, a estratégia está errada
- **Environments não são simétricos** — staging espelha produção em config, não em custo

## Pipeline Stages & Gates

**Ordem canônica:**
```
1. lint / typecheck      — segundos, sem dependências, mata falhas óbvias
2. unit tests            — rápido, isolado, sem rede
3. build artifact        — produz artifact imutável (Docker image, binary, zip)
4. security scan         — SAST, SCA, image scan no artifact construído
5. integration tests     — contra serviços reais usando o artifact
6. publish artifact      — push para registry (ECR, GHCR, S3) com tag git SHA
7. deploy para staging   — automático, sem aprovação
8. smoke tests           — verificações leves contra staging
9. deploy para produção  — gate de aprovação ou automático de trunk
10. post-deploy checks   — verificar saúde, métricas, sintéticos
```

**Gates por stage:**

| Stage | Condição de gate | Em falha |
|-------|-----------------|---------|
| Lint | Zero erros | Bloquear PR merge |
| Unit tests | 100% pass, cobertura ≥ threshold | Bloquear PR merge |
| Security scan | Sem CVEs CRITICAL; HIGH revisados | Bloquear deploy |
| Integration tests | 100% pass | Bloquear promoção |
| Smoke tests | Todos endpoints retornam status esperado | Trigger rollback |
| Post-deploy checks | Error rate < 1%, p99 latência < SLO | Trigger rollback |

## Artifact Management

**Tag strategy — sempre SHA, nunca `latest`:**
```bash
IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app"
TAG="${GITHUB_SHA:0:8}"       # SHA curto: 8 chars é suficiente para unicidade
FULL_IMAGE="${IMAGE}:${TAG}"

docker build -t "${FULL_IMAGE}" .
docker push "${FULL_IMAGE}"
```

**Promoção por re-tag, não por rebuild:**
```bash
# Promover SHA validado em staging para tag de produção
STAGING_IMAGE="${IMAGE}:${SHA}"
PROD_TAG="${IMAGE}:prod-${SHA}"

docker manifest inspect "${STAGING_IMAGE}"  # Verificar que existe
docker tag "${STAGING_IMAGE}" "${PROD_TAG}"
docker push "${PROD_TAG}"
```

**Retenção de artifacts:**
- Docker images: manter últimas 10 tags + todas referenciadas por deployments ativos (ECR lifecycle policy)
- Build artifacts (zips): manter 30 dias ou últimas 10 releases
- Test reports: 7 dias (apenas diagnóstico)
- Usar ECR Lifecycle Policies ou S3 Lifecycle Rules — nunca limpeza manual

## Environment Promotion Strategy

```
feat/* branch  ->  PR checks (lint, test, scan)
                       | merge
main           ->  CI constrói artifact, deploy automático para staging
                       | smoke tests passam automaticamente
                  deploy para produção (manual approval ou automático de trunk)
```

**Config por ambiente:**
- Diferenças de config entre ambientes ficam em environment-specific secrets ou SSM Parameter Store
- Nunca em Dockerfiles separados ou build arguments
- `DATABASE_URL`, `API_KEY`, `NODE_ENV` injetados em runtime, não baked na imagem

**Approval gates (GitHub Environments):**
```yaml
jobs:
  deploy-production:
    environment: production  # Requer aprovação configurada nas repo settings
    needs: [smoke-tests]
    steps:
      - run: ./deploy.sh production ${{ env.IMAGE_TAG }}
```

## Deployment Strategies

**Rolling deployment (padrão para maioria dos serviços):**
```yaml
# Kubernetes — substituir pods gradualmente
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Criar 1 pod extra durante rollout
      maxUnavailable: 0  # Zero-downtime: nunca reduzir abaixo do desejado
```

**Blue/green (mudanças de alto risco, zero-downtime estrito):**
```bash
# Criar environment green com nova versão
# Smoke test em green
# Swap de tráfego via ALB target group
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG_ARN

# Rollback: restaurar blue instantaneamente
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG_ARN
```

**Custo:** Paga por dois ambientes durante a janela de switch — justificável para serviços críticos.

**Canary deployment (validar sob tráfego real):**
```yaml
# Argo Rollouts
spec:
  strategy:
    canary:
      steps:
        - setWeight: 10          # 10% para nova versão
        - pause: {duration: 5m}  # Observar métricas
        - analysis:              # Gate automático por métricas
            templates:
              - templateName: success-rate
        - setWeight: 50
        - pause: {duration: 5m}
        - setWeight: 100
      analysis:
        successCondition: result[0] >= 0.99  # 99% success rate
```

## Rollback Strategy

**Rollback = um comando, menos de 5 minutos:**

```bash
# Kubernetes
kubectl rollout undo deployment/my-app -n production
kubectl rollout status deployment/my-app -n production --timeout=3m

# Rollback para revisão específica
kubectl rollout history deployment/my-app -n production
kubectl rollout undo deployment/my-app --to-revision=3 -n production
```

**Rollback automático em CI:**
```yaml
- name: Deploy
  id: deploy
  run: kubectl set image deployment/my-app app=${{ env.NEW_IMAGE }} -n production

- name: Wait for rollout
  run: kubectl rollout status deployment/my-app -n production --timeout=5m

- name: Smoke test
  id: smoke
  run: ./scripts/smoke-test.sh
  continue-on-error: true

- name: Rollback on smoke failure
  if: steps.smoke.outcome == 'failure'
  run: |
    kubectl rollout undo deployment/my-app -n production
    echo "::error::Smoke tests failed — rolled back to previous version"
    exit 1
```

**Rollback triggers:**
- Smoke tests falham → redeploy SHA anterior imediatamente
- Alert de error rate dispara dentro de 10 min do deploy → auto-rollback (Argo Rollouts analysis)
- Health checks retornam não-200 após deploy → controller faz rollback

## Security Integration (SAST, SCA, Image Scanning)

**SAST:**
```yaml
- uses: github/codeql-action/analyze@v3
  with:
    languages: javascript, python
```

**SCA — vulnerabilidades de dependências:**
```bash
npm audit --audit-level=high    # Falha em high/critical
```

**Container image scanning:**
```yaml
- name: Build image
  run: docker build -t $IMAGE .

- uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE }}
    format: sarif
    output: trivy-results.sarif
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
    ignore-unfixed: false

- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: trivy-results.sarif

- name: Push image (apenas se scan passou)
  run: docker push $IMAGE
```

**Secrets scanning:**
```yaml
- name: Secrets scan
  run: |
    pip install detect-secrets
    detect-secrets scan --baseline .secrets.baseline
    detect-secrets audit .secrets.baseline
```

**Política de CVEs:**
- CRITICAL: bloquear deploy sempre, sem exceções
- HIGH: bloquear deploy; exceção documentada com expiry date obrigatória
- MEDIUM/LOW: security backlog; não bloqueia

## Observability Integration

**Deployment markers:**
```bash
# Notificar plataforma de observabilidade sobre deploy
# (correlacionar deploys com spikes de métricas/logs)

# DataDog
curl -X POST "https://api.datadoghq.com/api/v1/events" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -d "{
    \"title\": \"Deploy: my-app ${SHA:0:8} to production\",
    \"tags\": [\"env:production\", \"service:my-app\", \"version:${SHA:0:8}\"]
  }"
```

**Post-deploy health check:**
```bash
# Aguardar rollout, depois verificar error rate via métricas
kubectl rollout status deployment/my-app --timeout=5m

# Verificar erro rate no Prometheus
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode "query=rate(http_requests_total{status=~'5..',service='my-app'}[5m]) / rate(http_requests_total{service='my-app'}[5m])" \
  | jq -r '.data.result[0].value[1]')

if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
  echo "Error rate ${ERROR_RATE} exceeds 1% threshold"
  exit 1
fi
```

## Feature Flags

Feature flags desacoplam deploy de release. Fazer merge e deploy de features incompletas atrás de uma flag; habilitar independente do pipeline.

**Quando usar:**
- Features de risco que precisam de rollout gradual
- A/B testing
- Kill switches para integrações de terceiros
- Separar deploy de backend de habilitação de UI

**Ferramentas:** LaunchDarkly, AWS AppConfig, Unleash (self-hosted), ou SSM Parameter Store simples.

**CI/CD integration:**
```bash
# Deploy com feature flag desabilitada
aws appconfig start-deployment \
  --application-id $APP_ID \
  --environment-id $ENV_ID \
  --deployment-strategy-id $STRATEGY_ID \
  --configuration-profile-id $PROFILE_ID

# Gradualmente habilitar após validar
# 5% → 25% → 50% → 100%
```

**Anti-padrão:** Usar feature flags como substituto para testes adequados. Flags reduzem blast radius; não substituem quality gates.

## Common Mistakes / Anti-Patterns

- **Rebuild por ambiente** — quebra imutabilidade; `npm install` em staging ≠ em produção se versões mudam
- **`latest` tag em produção** — sobrescrito a cada push; impossível rollback para "latest"
- **Sem procedimento de rollback** — se não está testado, não funciona quando necessário sob pressão
- **Security scans como informacionais** — scan que não bloqueia deploy é teatro, não segurança
- **Pipeline longa sem early exits** — se lint roda após build de 20 min, falhas são caras
- **Deploy direto de feature branches** — apenas `main` deploya para produção em trunk-based development
- **Build arguments por ambiente** — config em imagem = imagens diferentes por ambiente; usar env vars em runtime
- **Sem deployment markers em observabilidade** — impossível debugar incidente de produção sem saber quando ocorreram deploys
- **Aprovação manual como único trigger de rollback** — até humano aprovar rollback, incidente já escalou

## Communication Style

Quando esta skill está ativa:
- Ao revisar pipeline, identificar ordenação de stages e alertar sobre misordering
- Sempre perguntar sobre estratégia de rollback ao discutir nova abordagem de deployment
- Alertar sobre `continue-on-error: true` em security gates — desabilita o gate
- Sugerir deployment markers proativamente ao discutir observabilidade

## Expected Output Quality

- YAML de pipeline sintaticamente válido seguindo schema da ferramenta
- Estratégias de deployment incluem mecanismo de rollback, não apenas steps de rollout
- Exemplos de security incluem tanto o scan quanto o gate (exit code / falha do pipeline)
- Artifact tagging usa git SHA, não semver strings ou `latest`

---
**Skill type:** Passive
**Applies with:** github-actions, git, docker-ci, kubernetes, argocd, aws
**Pairs well with:** cicd-engineer (DevOps pack), gitops-engineer (DevOps pack)
