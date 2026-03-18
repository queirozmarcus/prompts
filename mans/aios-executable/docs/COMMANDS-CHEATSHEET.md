# Commands Cheatsheet

| Comando | Quando usar | Próximo comando comum |
|---|---|---|
| `design-service` | criar ou redesenhar serviço | `terraform-apply` |
| `k8s-debug` | pod quebrando, scheduling, probe, rede | `analyze-logs` |
| `terraform-apply` | infra nova ou mudança crítica | `deploy-debug` |
| `analyze-logs` | logs confusos, stacktrace, erro sem causa clara | `k8s-debug` |
| `deploy-debug` | pipeline ou rollout falhou | `k8s-debug` |
| `analyze-performance` | latência alta, throughput ruim, saturação | `analyze-logs` |
