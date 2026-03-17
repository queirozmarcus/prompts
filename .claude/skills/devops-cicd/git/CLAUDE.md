# Skill: Git

## Scope

Gestão de repositórios com Git: branching, commits, rebase, merge, hooks, debugging de histórico e fluxos de trabalho colaborativos. Assume trunk-based development no GitHub com Conventional Commits. Aplicável quando trabalhando com qualquer operação Git — branches, commits, resolução de conflitos, bisect, cherry-pick.

## Core Principles

- **Trunk-based development** — `main` é sempre deployável; feature branches vivem no máximo 2 dias
- **Conventional Commits** — `type(scope): description`; habilita changelogs automáticos e semver
- **Histórico é documentação** — histórico limpo e linear é um artefato de primeira classe; squash ruído, preserva significado
- **Nunca reescrever histórico público** — `--force` para `main` ou branches compartilhadas destrói trabalho alheio
- **Segredos nunca entram no Git** — pre-commit hooks são última linha de defesa, não a única

## Branching Strategy

```
main                     # sempre deployável, protegida
├── feat/nome-curto      # feature branches (< 2 dias)
├── fix/descricao-bug    # bugfix branches
├── hotfix/fix-critico   # hotfixes de produção (branch de main, merge para main)
└── release/v1.2.0       # opcional: para projetos com versões release
```

**Regras:**
- Branch de `main`, merge de volta via PR
- Hotfixes: branch de `main`, fix, PR para `main`, tag de release
- Deletar branches imediatamente após merge

```bash
# Criar e rastrear feature branch
git checkout -b feat/user-auth
git push -u origin feat/user-auth

# Deletar após merge
git branch -d feat/user-auth
git push origin --delete feat/user-auth
```

## Commit Best Practices

```bash
# Stage arquivos específicos — NUNCA git add . sem revisar
git add src/auth/login.ts tests/auth/login.test.ts

# Revisar antes de commitar
git diff
git diff --staged

# Conventional Commits
git commit -m "feat(auth): add JWT token refresh before expiration"
git commit -m "fix(docker): enforce LF endings on all text files"
git commit -m "chore(deps): bump axios from 1.4.0 to 1.6.2"
```

**Commits atômicos:** Uma mudança lógica por commit. Se não consegue descrever em 50 chars, provavelmente são dois commits.

**Corpo quando necessário:**
```
feat(billing): add proration on mid-cycle plan upgrades

Calculates remaining days in billing period and applies credit
to the next invoice. Avoids double-charging on same-day upgrades.

Closes #412
```

## Rebase vs Merge

| Situação | Use |
|----------|-----|
| Atualizar feature branch com `main` | `git rebase origin/main` |
| Merge de PR para `main` | Squash-and-merge (histórico linear) |
| Limpar commits WIP antes de PR | `git rebase -i HEAD~N` |
| Preservar histórico completo para auditoria | `git merge --no-ff` |
| **Nunca** | `git rebase` em branches públicas/compartilhadas |

```bash
# Atualizar feature branch (rebase sobre main)
git fetch origin
git rebase origin/main

# Se houver conflitos durante rebase
git status                    # ver arquivos conflitando
# resolver conflitos no editor
git add <arquivos-resolvidos>
git rebase --continue         # ou --abort para cancelar

# Force push APENAS em sua própria feature branch após rebase
git push --force-with-lease origin feat/user-auth
# --force-with-lease falha se o remote mudou inesperadamente
```

## Interactive History Management

```bash
# Limpar últimos N commits antes de abrir PR
git rebase -i HEAD~5

# Ações do rebase -i:
# pick   — manter commit como está
# reword — manter commit, editar mensagem
# squash — combinar com commit anterior, mesclar mensagens
# fixup  — combinar com anterior, descartar esta mensagem
# drop   — remover commit completamente

# Amend apenas o último commit
git commit --amend --no-edit      # adicionar staged changes, manter mensagem
git commit --amend -m "fix: ..."  # reescrever mensagem
# Force push se já foi pushed:
git push --force-with-lease origin feat/my-feature
```

**Stash para trocar de contexto:**
```bash
git stash push -m "wip: refactor parcial de auth"
git stash list
git stash pop                         # aplicar stash mais recente e remover
git stash apply stash@{2}             # aplicar sem remover
git stash branch feat/recovered stash@{0}  # transformar stash em branch
```

## Hooks (pre-commit, commit-msg, pre-push)

Armazenar hooks em `.githooks/` (versionado) e configurar:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

**.githooks/pre-commit** — lint, format, secrets scan:
```bash
#!/usr/bin/env bash
set -e
npm run lint --silent
# Scan por segredos acidentais (requer detect-secrets)
detect-secrets-hook --baseline .secrets.baseline
```

**.githooks/commit-msg** — enforce Conventional Commits:
```bash
#!/usr/bin/env bash
pattern='^(feat|fix|docs|refactor|perf|test|chore|ci|style)(\(.+\))?: .{1,72}'
if ! grep -qE "$pattern" "$1"; then
  echo "ERROR: Commit deve seguir Conventional Commits."
  echo "  Exemplo: feat(auth): add token refresh"
  echo "  Types: feat fix docs refactor perf test chore ci style"
  exit 1
fi
```

**.githooks/pre-push** — rodar testes antes de push:
```bash
#!/usr/bin/env bash
set -e
echo "Running tests before push..."
npm test -- --passWithNoTests
```

## Debugging with Git

**bisect — busca binária para regressões:**
```bash
git bisect start
git bisect bad                    # commit atual está quebrado
git bisect good v1.3.0            # último tag bom conhecido
# git faz checkout no meio; testar e marcar:
git bisect good                   # ou: git bisect bad
# repetir até git identificar o primeiro bad commit
git bisect reset                  # voltar para HEAD

# Automatizar com script (exit 0 = bom, exit 1 = ruim):
git bisect run npm test
```

**blame e log para rastrear mudanças:**
```bash
git blame -L 42,55 src/auth/login.ts       # quem mudou linhas 42-55
git log --follow -p -- src/auth/login.ts   # histórico completo incluindo renames
git log --all --grep="token refresh"       # buscar mensagens de commit
git log --oneline --graph --decorate --all # visualizar topologia de branches
git log -S "functionName" --source --all   # quando string foi adicionada/removida
```

**Recuperar trabalho perdido:**
```bash
git reflog                            # todos os movimentos de HEAD — rede de segurança
git checkout -b recover HEAD@{3}      # restaurar estado de 3 movimentos atrás
git cherry-pick <sha>                 # aplicar commit específico de outro branch
```

## Common Workflows

**Iniciar feature:**
```bash
git fetch origin && git checkout -b feat/my-feature origin/main
```

**Sincronizar com main durante desenvolvimento:**
```bash
git fetch origin && git rebase origin/main
```

**Preparar PR (histórico limpo):**
```bash
git rebase -i origin/main              # squash WIP commits
git push --force-with-lease origin feat/my-feature
```

**Hotfix:**
```bash
git checkout -b hotfix/null-ptr-crash main
# fix, test, commit: fix(component): description
git push -u origin hotfix/null-ptr-crash
# abrir PR -> squash merge -> tag release -> deletar branch
```

**Desfazer último commit (manter staged):**
```bash
git reset --soft HEAD~1
```

## Common Mistakes / Anti-Patterns

- **`git add .` sem revisar** — pode fazer stage de segredos, artefatos de build, `.env`
- **`git push --force` para `main`** — destrói histórico compartilhado; usar `--force-with-lease` em feature branches
- **Feature branches de longa vida** — criam conflitos massivos e divergência de `main`
- **Merge commits em feature branches** — polui histórico; usar `rebase` antes de PR
- **Commitar segredos** — rotação é cara; usar `detect-secrets` ou `gitleaks` em pre-commit
- **Mensagens vagas** — `fix`, `WIP`, `changes` são inúteis no `git log`; sempre usar Conventional Commits
- **`--no-verify` para pular hooks** — hooks existem por razão; corrigir a causa raiz, não bypassar
- **Não deletar branches após merge** — cria poluição e confusão sobre o que está ativo

## Communication Style

Quando esta skill está ativa:
- Fornecer comandos git exatos e copiáveis, não apenas conceitos
- Alertar sobre operações que reescrevem histórico (`reset --hard`, `push --force`)
- Sempre sugerir `--force-with-lease` ao invés de `--force`
- Para debugging de regressões em histórico longo, sugerir `git bisect`

## Expected Output Quality

- Comandos git sintaticamente corretos e prontos para uso
- Workflows de rebase incluem steps de resolução de conflitos
- Hook scripts usam bash POSIX-compatível com `set -e`
- Exemplos de mensagens seguem Conventional Commits exatamente

---
**Skill type:** Passive
**Applies with:** github-actions, ci-cd, workflows
**Pairs well with:** personal-engineering-agent
