# /lint — Análise de qualidade e segurança

Executa RuboCop, RuboCop-RSpec e Brakeman. Corrige o que for possível automaticamente e reporta o restante.

**Argumento:** $ARGUMENTS (opcional — caminho específico, ex: "app/services/draw_service.rb")

## Passos

### 1. RuboCop — autocorrect
Aplica correções automáticas seguras:
```bash
bundle exec rubocop ${ARGUMENTS:-app/ spec/} --autocorrect
```

### 2. RuboCop — verificação final
Verifica se ainda há ofensas que precisam de correção manual:
```bash
bundle exec rubocop ${ARGUMENTS:-app/ spec/}
```

Se houver ofensas restantes:
- Analise cada uma
- Corrija manualmente
- Re-execute até passar com 0 ofensas

### 3. Brakeman — segurança
```bash
bundle exec brakeman --no-pager -q
```

Para cada warning:
- Avalie se é falso positivo ou vulnerabilidade real
- Corrija vulnerabilidades reais antes de continuar
- Documente falsos positivos com `# brakeman:ignore` e justificativa

### 4. Resultado
Reporte ao final:
- Total de arquivos analisados
- Ofensas RuboCop: N (deve ser 0)
- Warnings Brakeman: N (deve ser 0 ou apenas falsos positivos documentados)
