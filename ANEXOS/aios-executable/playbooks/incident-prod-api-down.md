# Playbook — API fora do ar

1. `./bin/aios run analyze-logs full --context <arquivo>`
2. `./bin/aios run k8s-debug full --context <arquivo>`
3. `./bin/aios run deploy-debug lite --context <arquivo>` se houve deploy recente
4. `./bin/aios run analyze-performance lite --context <arquivo>` se houver degradação parcial
