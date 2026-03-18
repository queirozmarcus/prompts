
# Fase 2 — Preparação do Monólito para Extração: $ARGUMENTS

Prepare o monólito para permitir extração segura do bounded context **$ARGUMENTS**, sem alterar comportamento.

## Instruções

### Step 1: Criar seams

Use o subagente **backend-engineer** para:
- Identificar todas as chamadas diretas entre $ARGUMENTS e outros módulos
- Extrair interfaces nos limites do bounded context
- Substituir chamadas diretas por chamadas via interface
- Reorganizar classes para pacotes alinhados ao contexto
- Adicionar ArchUnit test enforçando limites
- Configurar feature flag: `ff.migration.$ARGUMENTS.route-to-service`

**REGRA**: Nenhuma mudança funcional. Apenas reorganização. Monólito deve continuar idêntico.

### Step 2: Capturar baseline

Use o subagente **qa-engineer** para:
- Capturar golden dataset do módulo (request/response samples)
- Documentar performance baseline (latência, throughput)
- Garantir que testes de regressão cobrem >80% dos fluxos críticos
- Verificar que testes passam 100% após a reorganização

### Step 3: Validar

Confirme que:
- [ ] Monólito funciona identicamente após modularização
- [ ] Testes de regressão 100% passando
- [ ] Feature flag funciona (toggle sem efeito quando OFF)
- [ ] ArchUnit tests bloqueiam novas dependências cruzadas
- [ ] Golden dataset capturado e salvo em `docs/migration/baselines/`
