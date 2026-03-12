# /spec — Gerar e executar specs

Gera specs RSpec para um componente específico e executa os testes.

**Argumento:** $ARGUMENTS (ex: "model Raffle", "service DrawService", "job ExpireTicketsJob", "request raffles")

## O que fazer

### 1. Identificar o componente
Com base no argumento, identifique:
- Tipo: model, service, job, request (controller), serializer
- Nome: o arquivo alvo

### 2. Ler o código existente
Leia o arquivo de implementação antes de gerar o spec para entender:
- Métodos públicos e seus contratos
- Validações e callbacks (models)
- Casos de erro esperados
- Dependências externas (mock com WebMock/VCR se necessário)

### 3. Gerar o spec
Crie o arquivo de spec seguindo as convenções do projeto:

**Models** (`spec/models/`):
- Testar validações com shoulda-matchers
- Testar associations
- Testar scopes e métodos de instância
- Testar callbacks importantes

**Services** (`spec/services/`):
- Testar o método principal (geralmente `.call`)
- Testar sucesso, falha e edge cases
- Mockar dependências externas

**Jobs** (`spec/jobs/`):
- Testar que o job é enfileirado corretamente
- Testar a execução com dados válidos e inválidos

**Requests** (`spec/requests/api/v1/`):
- Usar formato rswag para gerar documentação simultânea
- Testar autenticação (401 sem token)
- Testar autorização (403 para role errado)
- Testar isolamento de tenant (org A não acessa dados de org B)
- Testar casos de sucesso (200/201)
- Testar casos de erro (422, 404)

### 4. Executar os specs
```bash
bundle exec rspec [caminho_do_spec] --format documentation
```

### 5. Reportar resultado
- Mostre o output dos testes
- Se houver falhas, analise e corrija
- Confirme cobertura do componente
