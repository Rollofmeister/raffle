# /feature — Ciclo completo de implementação de feature

Executa o ciclo completo TDD para implementar uma nova feature na API.

**Argumento:** $ARGUMENTS (descrição da feature, ex: "POST /api/v1/raffles — criar rifa")

## Fluxo obrigatório — execute cada etapa em sequência

### 1. PLANEJAMENTO
Antes de qualquer código:
- Identifique os arquivos que serão criados ou modificados
- Mapeie os endpoints, models, services e jobs envolvidos
- Verifique se há impacto no multi-tenancy (escopo por organization_id)
- Verifique se há impacto em jobs, cache ou cable
- Apresente o plano ao usuário antes de continuar

### 2. TESTES PRIMEIRO (TDD — Red phase)
Crie os specs **antes** da implementação:
- `spec/requests/api/v1/` para testes de endpoint (request specs com rswag)
- `spec/models/` para testes de model
- `spec/services/` para testes de service
- `spec/jobs/` para testes de job (se aplicável)

Regras dos specs:
- Use factories (FactoryBot), nunca fixtures
- Cubra casos de sucesso, erro, e edge cases
- Inclua testes de autorização (tenant isolation — garantir que org A não acessa dados de org B)
- Para endpoints, escreva no formato rswag (gera documentação Swagger automaticamente)
- Execute os specs e confirme que estão **falhando** (Red)

### 3. IMPLEMENTAÇÃO (Green phase)
Implemente o mínimo necessário para os testes passarem:
- Controllers em `app/controllers/api/v1/`
- Models em `app/models/`
- Services em `app/services/`
- Jobs em `app/jobs/` (Solid Queue)
- Serializers em `app/serializers/`

Regras de implementação:
- Controllers magros: lógica de negócio vai em services
- Sempre escopar queries por `current_organization`
- Nunca expor IDs internos — usar UUIDs ou tokens públicos
- Tratar erros explicitamente (não deixar exceções não tratadas)

Execute os specs e confirme que estão **passando** (Green).

### 4. REFATORAÇÃO (Refactor phase)
Com os testes verdes, melhore o código:
- Extraia duplicações para métodos privados ou concerns
- Verifique N+1 queries (use includes/eager_load)
- Confirme que os testes continuam passando após refatoração

### 5. LINT
Execute RuboCop e corrija todas as ofensas:
```bash
bundle exec rubocop app/ spec/ --autocorrect
bundle exec rubocop app/ spec/
```
Depois execute análise de segurança:
```bash
bundle exec brakeman --no-pager -q
```
Corrija qualquer issue reportado antes de continuar.

### 6. DOCUMENTAÇÃO SWAGGER
Gere/atualize a documentação da API:
```bash
bundle exec rails rswag:specs:swaggerize
```
Confirme que o arquivo `swagger/v1/swagger.yaml` foi atualizado corretamente.

### 7. COBERTURA
Execute a suite completa e verifique cobertura:
```bash
COVERAGE=true bundle exec rspec
```
A cobertura da feature implementada deve ser ≥ 95%.

### 8. REGISTRO NO CLAUDE.md
Ao final, atualize o `CLAUDE.md`:
- Adicione a feature na seção de **Passos e Decisões — Log** com a data
- Documente qualquer decisão de design relevante tomada durante a implementação
- Marque o item como concluído nos próximos passos

## Checklist de conclusão
- [ ] Specs escritos antes da implementação
- [ ] Todos os specs passando
- [ ] Casos de isolamento de tenant testados
- [ ] RuboCop sem ofensas
- [ ] Brakeman sem warnings
- [ ] Swagger atualizado
- [ ] Cobertura ≥ 95% na feature
- [ ] CLAUDE.md atualizado
