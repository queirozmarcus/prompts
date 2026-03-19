---
name: gen-prompt
description: "Gerar prompt otimizado para qualquer agent, skill, command ou CLAUDE.md do ecossistema. Também cria novos agents, skills, commands e playbooks."
argument-hint: "[tipo: prompt|agent|skill|command|playbook|claudemd] [descrição do que precisa]"
---

# Gerador de Prompt: $ARGUMENTS

Use o sub-agente **prompt-engineer** para gerar o artefato solicitado.

## Instruções

### Identificar o tipo de artefato

Analise o argumento e identifique o que o usuário precisa:

| Tipo | Exemplos de pedido |
|------|-------------------|
| **prompt** | "prompt para o backend-dev implementar X", "como pedir para o architect fazer Y" |
| **agent** | "crie um agent para Z", "preciso de um agente de Kafka" |
| **skill** | "crie uma skill de Redis", "melhore a skill de java" |
| **command** | "crie um command para orquestrar X", "preciso de um /devops-chaos" |
| **playbook** | "crie um playbook de canary deployment" |
| **claudemd** | "crie um CLAUDE.md para meu projeto", "otimize meu CLAUDE.md" |

### Gerar o artefato

Use o sub-agente **prompt-engineer** para:

1. **Se for prompt para agent existente:**
   - Identificar o agent correto do ecossistema
   - Gerar prompt otimizado usando vocabulário e patterns do agent
   - Incluir contexto do projeto, output esperado e constraints
   - Entregar pronto para copy-paste

2. **Se for novo agent/skill/command/playbook:**
   - Analisar o ecossistema existente para evitar duplicação
   - Verificar naming conventions e formato obrigatório
   - Gerar o artefato completo com YAML frontmatter
   - Validar contra as regras (seções obrigatórias, tools mínimos, etc.)
   - Entregar pronto para salvar em `~/.claude/`

3. **Se for CLAUDE.md:**
   - Analisar o projeto (se disponível)
   - Gerar alinhado com o CLAUDE.md global
   - Referenciar agents, skills e commands relevantes

### Entregar

Apresentar o artefato gerado em bloco de código, pronto para uso. Incluir:
- Onde salvar o arquivo
- Como testar/validar
- Nota sobre sinergia com o ecossistema
