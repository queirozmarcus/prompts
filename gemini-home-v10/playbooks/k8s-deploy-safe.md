# Playbook: Safe Kubernetes Deployment

## Inputs Required

Before starting, confirm:
- [ ] `IMAGE` — full image reference with immutable tag (e.g., `123.dkr.ecr.us-east-1.amazonaws.com/myapp:abc12345`)
- [ ] `NAMESPACE` — target Kubernetes namespace
- [ ] `DEPLOYMENT` — deployment name
- [ ] `ENVIRONMENT` — production/staging/dev
- [ ] `APPROVED_BY` — who approved this deployment? (required for production)

## Pre-Deploy Checklist

**Image validation:**
- [ ] Image uses immutable tag (SHA or semantic version), not `latest`
- [ ] Image has passed CI security scan (Trivy: no CRITICAL CVEs)
- [ ] Image was tested in staging environment

**Manifest validation:**
```bash
# Validate manifest against live cluster API (server-side validation)
kubectl apply -f deployment.yaml --dry-run=server -n ${NAMESPACE}

# Verify resource limits defined (will fail if not)
kubectl apply -f deployment.yaml --dry-run=server -n ${NAMESPACE} 2>&1 \
  | grep -E "(cpu|memory)" || echo "WARNING: Check that resource limits are set"
```

**Checklist:**
- [ ] `resources.requests` and `resources.limits` defined for all containers
- [ ] `livenessProbe` configured with appropriate `initialDelaySeconds`
- [ ] `readinessProbe` configured (removes pod from Service if failing)
- [ ] `PodDisruptionBudget` exists for this deployment (`kubectl get pdb -n ${NAMESPACE}`)
- [ ] `ServiceAccount` is not `default` (use dedicated SA)
- [ ] `securityContext.runAsNonRoot: true` set
- [ ] No hardcoded secrets (use `secretKeyRef` or External Secrets Operator)

## Namespace & Context Verification

```bash
# CRITICAL: Verify you're in the right cluster and namespace
kubectl config current-context
kubectl config view --minify --output 'jsonpath={.clusters[0].cluster.server}'

# Confirm namespace exists with correct labels
kubectl get namespace ${NAMESPACE} -o yaml | grep -E "(name|environment|team)"

# Check current resource usage vs quota
kubectl describe resourcequota -n ${NAMESPACE}
kubectl top pods -n ${NAMESPACE} | head -20

# PDB status (must exist and be healthy before deploy)
kubectl get pdb -n ${NAMESPACE}
# Expected: ALLOWED-DISRUPTIONS > 0 (if 0, a node drain will block)
```

## Dry Run

```bash
# Server-side dry run — validates against live API, admission controllers, and webhooks
kubectl apply -f deployment.yaml --dry-run=server -n ${NAMESPACE}

# If using Helm:
helm diff upgrade ${DEPLOYMENT} ./chart \
  --values values-${ENVIRONMENT}.yaml \
  --namespace ${NAMESPACE}

# Review the diff carefully:
# - Image tag change (expected)
# - Resource limit changes (review)
# - New environment variables (verify no secrets exposed)
# - Probe changes (verify new timing is appropriate)
```

## Apply with Rollout Monitoring

```bash
# Apply manifest
kubectl apply -f deployment.yaml -n ${NAMESPACE}

# Watch rollout in real-time (blocks until complete or timeout)
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=10m

# Monitor pod replacement
kubectl get pods -n ${NAMESPACE} -w --field-selector metadata.name!=""

# If rollout is slow, check events
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -20
kubectl describe deployment/${DEPLOYMENT} -n ${NAMESPACE} | tail -20
```

## Health Check Validation

```bash
# 1. All pods in Running state
kubectl get pods -n ${NAMESPACE} -l app=${DEPLOYMENT}
# Expected: All pods READY and Running; 0 restarts

# 2. Endpoints populated (traffic can reach pods)
kubectl get endpoints ${DEPLOYMENT} -n ${NAMESPACE}
# Expected: ENDPOINTS column shows pod IPs, not "<none>"

# 3. Service responding
kubectl port-forward svc/${DEPLOYMENT} 8080:80 -n ${NAMESPACE} &
curl -f http://localhost:8080/health
# Cleanup:
kill %1

# 4. Check for error logs immediately after deploy
kubectl logs deployment/${DEPLOYMENT} -n ${NAMESPACE} --tail=50 --since=5m \
  | grep -E "(ERROR|WARN|exception|panic)" | head -20

# 5. Check for OOMKills or CPU throttling
kubectl top pods -n ${NAMESPACE} -l app=${DEPLOYMENT}
kubectl get events -n ${NAMESPACE} --field-selector reason=OOMKilling
```

## SLO Monitoring During Rollout

**Prometheus queries to watch during deploy (5-min window):**
```promql
# Error rate — should stay < 1% for healthy services
sum(rate(http_requests_total{status=~"5..",namespace="NAMESPACE"}[5m]))
/ sum(rate(http_requests_total{namespace="NAMESPACE"}[5m]))

# P99 latency — should not exceed baseline + 20%
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket{namespace="NAMESPACE"}[5m])) by (le)
)

# Restart rate — should be 0 for stable deploy
increase(kube_pod_container_status_restarts_total{namespace="NAMESPACE"}[10m])
```

**Rollback trigger criteria:**
- Error rate > 1% sustained for 3+ minutes after deploy completes
- P99 latency > 2x baseline sustained for 3+ minutes
- Any pod restart loop (> 2 restarts in 5 minutes)
- Readiness probe failures persisting 2+ minutes

## Rollback

**Immediate rollback (if triggered):**
```bash
# Kubernetes rollback to previous ReplicaSet
kubectl rollout undo deployment/${DEPLOYMENT} -n ${NAMESPACE}
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=5m

# Verify rollback to expected version
kubectl get deployment/${DEPLOYMENT} -n ${NAMESPACE} \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# If using ArgoCD: rollback via ArgoCD (preserves GitOps flow)
argocd app rollback ${APP_NAME}-${ENVIRONMENT}
argocd app get ${APP_NAME}-${ENVIRONMENT}
```

**Rollback verification:**
```bash
# Confirm error rate returned to baseline
# Confirm pods are running with old image
# Send rollback notification to incident channel
```

## Post-Deploy Verification

```bash
# 1. Run smoke tests if available
./scripts/smoke-test.sh ${ENVIRONMENT}

# 2. Confirm desired replica count achieved
kubectl get deployment/${DEPLOYMENT} -n ${NAMESPACE} \
  -o jsonpath='{.status.availableReplicas}'

# 3. Verify HPA is not immediately scaling (would indicate resource pressure)
kubectl get hpa -n ${NAMESPACE}

# 4. Check deployment history (useful for future rollbacks)
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}

# 5. Tag successful deployment in observability (optional but recommended)
echo "Deploy ${IMAGE} to ${ENVIRONMENT} by ${APPROVED_BY} at $(date -u)"
```

---
**Used by:** kubernetes-engineer (DevOps pack), gitops-engineer (DevOps pack)
**Related playbooks:** rollback-strategy.md, incident-response.md
