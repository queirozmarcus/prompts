# AI-OS Executable Kit — Backend, Microservices & DevOps

Kit operacional inspirado no ecossistema encontrado no ZIP (`agents/`, `commands/`, `playbooks/`, `skills/`) e expandido para uso diário em backend, microserviços, Kubernetes e Terraform.

## O que vem aqui

- `bin/aios`: CLI Bash simples para usar comandos padronizados
- `commands/registry.json`: catálogo de comandos full/lite
- `prompts/*.md`: prompts plugáveis para uso direto no Claude/LLM
- `playbooks/*.md`: runbooks rápidos para incidentes e delivery
- `docs/COMMANDS-CHEATSHEET.md`: visão rápida de uso
- `examples/`: exemplos reais de invocação

## Comandos incluídos

Baseados e expandidos a partir do ZIP original:
- Herdados conceitualmente: `dev-feature`, `dev-bootstrap`, `devops-incident`, `devops-provision`, `devops-observe`, `qa-*`, `data-*`, `migration-*`
- Novos comandos plugáveis: `design-service`, `k8s-debug`, `terraform-apply`, `analyze-logs`, `deploy-debug`, `analyze-performance`

## Instalação rápida

```bash
chmod +x ./bin/aios
./bin/aios list
```

## Uso

```bash
./bin/aios list
./bin/aios show k8s-debug
./bin/aios show k8s-debug lite
./bin/aios run k8s-debug full --context ./examples/k8s-crashloop-context.txt
```
