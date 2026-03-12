# /coverage — Cobertura de testes

Executa a suite completa de specs com SimpleCov e reporta a cobertura.

**Argumento:** $ARGUMENTS (opcional — caminho específico para rodar subset, ex: "spec/models/")

## Passos

### 1. Executar specs com cobertura
```bash
COVERAGE=true bundle exec rspec ${ARGUMENTS:-} --format progress
```

### 2. Analisar resultado
Após a execução, leia o relatório em `coverage/index.html` ou o summary no terminal.

Verifique:
- **Cobertura total**: meta mínima de **90%**
- **Arquivos críticos** devem ter cobertura ≥ 95%:
  - `app/services/` — regras de negócio
  - `app/models/` — validações e callbacks
  - `app/jobs/` — processamento assíncrono

### 3. Identificar gaps
Para cada arquivo abaixo da meta:
- Identifique as linhas não cobertas
- Avalie se faltam casos de teste (edge cases, erros)
- Crie os specs necessários

### 4. Não contar como cobertura
Arquivos que podem ser excluídos da meta:
- `app/channels/` (testado via integration)
- `config/` e `db/`
- `app/serializers/` (coberto pelos request specs)

### 5. Reportar
Mostre tabela com:
| Arquivo | Cobertura | Status |
|---|---|---|
| app/services/draw_service.rb | 98% | ✓ |
| app/models/ticket.rb | 94% | ✓ |
| app/jobs/expire_tickets_job.rb | 87% | ✗ ABAIXO DA META |
