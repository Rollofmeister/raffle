# /swagger — Atualizar documentação da API

Gera/atualiza o arquivo Swagger a partir dos specs rswag e valida a documentação.

## Passos

### 1. Verificar specs rswag
Confirme que os request specs que serão documentados estão passando:
```bash
bundle exec rspec spec/requests/ --format progress
```
Não gere documentação a partir de specs com falha.

### 2. Gerar documentação
```bash
bundle exec rails rswag:specs:swaggerize
```

### 3. Validar o output
Abra e verifique `swagger/v1/swagger.yaml`:
- Todos os endpoints implementados estão documentados?
- Os parâmetros de request estão corretos?
- Os schemas de response estão corretos?
- Os códigos de status (200, 201, 401, 403, 404, 422) estão documentados?
- A autenticação (Bearer token) está configurada?

### 4. Verificar endpoints não documentados
Liste rotas da aplicação e compare com o swagger:
```bash
bundle exec rails routes | grep "api/v1"
```
Se houver rotas sem documentação, crie os specs rswag correspondentes.

### 5. Reportar
Informe:
- Quantos endpoints foram documentados
- Se há endpoints sem cobertura no swagger
- Caminho do arquivo gerado: `swagger/v1/swagger.yaml`
