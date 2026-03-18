
# Pipeline CI/CD: $ARGUMENTS

Crie ou otimize o pipeline CI/CD para **$ARGUMENTS**.

## Instruções

### Step 1: Analisar — Use **cicd-engineer** para:
- Se pipeline existe: analisar tempo, quality gates, gaps
- Se não existe: definir estágios necessários

### Step 2: Security gates — Use **security-ops** para:
- Definir scans necessários (dependency, image, SAST)
- Configurar thresholds que bloqueiam deploy

### Step 3: Implementar — Use **cicd-engineer** para:
- Criar/atualizar pipeline completo
- Configurar GitOps (ArgoCD) se aplicável
- Otimizar: cache, paralelismo, incremental build
- Target: pipeline total < 10 minutos
