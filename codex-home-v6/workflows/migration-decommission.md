
# Fase 5 — Decommission do Módulo: $ARGUMENTS

Remova com segurança o módulo **$ARGUMENTS** do monólito após migração bem-sucedida.

## Pré-requisitos

Verifique antes de iniciar:
- [ ] Microsserviço em 100% de tráfego por pelo menos 2 semanas
- [ ] Zero rollback necessário no período
- [ ] Métricas dentro dos SLOs
- [ ] Feature flag em ON estável por 2+ semanas

Se algum pré-requisito não for atendido, informe o usuário e NÃO prossiga.

## Instruções

### Step 1: Remover código

Use o subagente **backend-engineer** para:
- Remover classes, controllers, services, repositories do contexto $ARGUMENTS
- Remover rotas/endpoints migrados
- Limpar dependências não utilizadas
- Remover feature flags de migração deste contexto
- Remover interfaces de bridge e dual-write
- Atualizar testes (remover testes do módulo extraído)

### Step 2: Limpar dados

Use o subagente **data-engineer** para:
- Criar migration para drop das tabelas: `V{n}__drop_${ARGUMENTS}_tables.sql`
- Remover CDC / sync temporário
- Remover views de compatibilidade
- **BACKUP antes de qualquer drop**
- Validar que monólito funciona sem tabelas removidas

### Step 3: Validar regressão

Use o subagente **qa-engineer** para:
- Executar suite completa de testes do monólito
- Verificar que nenhum fluxo referencia módulo removido
- Confirmar microsserviço não afetado pelo cleanup

### Step 4: Documentar conclusão

Assuma o papel de **Tech Lead** e:
- Gere ADR de conclusão do decommission
- Atualize mapa de bounded contexts
- Atualize documentação arquitetural
- Atualize runbook
